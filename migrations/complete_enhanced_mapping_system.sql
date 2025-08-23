-- Complete Enhanced Mapping System: INTEGER units + Receipt system
-- This migration includes unit validation AND receipt tracking for bulk mappings

-- ================== STEP 1: CHANGE UNIT COLUMN TO INTEGER =================================================

-- First, update any non-numeric values to 1
UPDATE product 
SET unit = '1' 
WHERE unit IS NULL OR unit = '' OR unit !~ '^[0-9]+$';

-- Now change the column type to INTEGER
ALTER TABLE product 
ALTER COLUMN unit TYPE INTEGER USING unit::INTEGER,
ALTER COLUMN unit SET DEFAULT 1,
ALTER COLUMN unit SET NOT NULL;

-- Add comment for clarity
COMMENT ON COLUMN product.unit IS 'Number of available units for this product';

-- ================== STEP 2: CREATE RECEIPT SYSTEM =================================================

-- Create a table to track mapping receipts/batches
CREATE TABLE IF NOT EXISTS mapping_receipt (
    id SERIAL PRIMARY KEY,
    receipt_number VARCHAR(20) UNIQUE NOT NULL,
    company_lid INT NOT NULL REFERENCES company(id),
    total_products INT NOT NULL DEFAULT 0,
    mapping_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    created_by INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT(true)
);

-- Add receipt reference to product_company_mapping
ALTER TABLE product_company_mapping 
ADD COLUMN IF NOT EXISTS receipt_lid INT REFERENCES mapping_receipt(id);

-- Add comment
COMMENT ON COLUMN product_company_mapping.receipt_lid IS 'Reference to bulk mapping receipt (NULL for single mappings)';
COMMENT ON TABLE mapping_receipt IS 'Tracks bulk mapping receipts with unique numbers';

-- ================== STEP 3: RECEIPT NUMBER GENERATION =================================================

-- Function to generate unique receipt number
CREATE OR REPLACE FUNCTION generate_receipt_number()
RETURNS VARCHAR(20) AS $$
DECLARE
    receipt_num VARCHAR(20);
    counter INTEGER;
BEGIN
    -- Generate receipt number like: RCP-YYYYMMDD-001
    SELECT COALESCE(MAX(CAST(SUBSTRING(receipt_number FROM '[0-9]+$') AS INTEGER)), 0) + 1
    INTO counter
    FROM mapping_receipt 
    WHERE receipt_number LIKE 'RCP-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-%';
    
    receipt_num := 'RCP-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(counter::TEXT, 3, '0');
    
    RETURN receipt_num;
END;
$$ LANGUAGE plpgsql;

-- ================== STEP 4: ENHANCED SINGLE MAPPING FUNCTION =================================================

-- Drop existing function and create enhanced version
DROP FUNCTION IF EXISTS map_product_to_company(INT, INT, TEXT, INT);
CREATE OR REPLACE FUNCTION map_product_to_company(
    p_product_lid INT,
    p_company_lid INT,
    p_notes TEXT,
    p_created_by INT
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
    new_label_id INT;
    old_label_id INT;
    product_unit_qty INTEGER;
    current_active_mappings INTEGER;
    product_name VARCHAR(255);
    company_name VARCHAR(255);
BEGIN
    -- Get label IDs
    SELECT id INTO new_label_id FROM label WHERE name = 'NEW' AND active = true LIMIT 1;
    SELECT id INTO old_label_id FROM label WHERE name = 'OLD' AND active = true LIMIT 1;
    
    IF new_label_id IS NULL OR old_label_id IS NULL THEN
        result = '{"status": "error", "message": "Required labels (NEW/OLD) not found."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Get product details (unit is now INTEGER)
    SELECT name, unit
    INTO product_name, product_unit_qty
    FROM product 
    WHERE id = p_product_lid AND active = true;
    
    IF product_name IS NULL THEN
        result = '{"status": "error", "message": "Product not found or inactive."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Get company name
    SELECT name INTO company_name FROM company WHERE id = p_company_lid AND active = true;
    IF company_name IS NULL THEN
        result = '{"status": "error", "message": "Company not found or inactive."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Count current active mappings for this product
    SELECT COUNT(*) INTO current_active_mappings
    FROM product_company_mapping 
    WHERE product_lid = p_product_lid AND active = true;
    
    -- Check if product is already mapped to this specific company
    IF EXISTS (SELECT 1 FROM product_company_mapping 
               WHERE product_lid = p_product_lid AND company_lid = p_company_lid AND active = true) THEN
        result = jsonb_build_object(
            'status', 'error', 
            'message', 'Product "' || product_name || '" is already mapped to company "' || company_name || '".'
        );
        RETURN result;
    END IF;
    
    -- Validate against unit quantity limit
    IF current_active_mappings >= product_unit_qty THEN
        result = jsonb_build_object(
            'status', 'error', 
            'message', 'Cannot map product "' || product_name || '". All ' || product_unit_qty || 
                      ' units are already mapped to other companies. Available: 0, Mapped: ' || current_active_mappings
        );
        RETURN result;
    END IF;
    
    -- Update existing NEW products for this company to OLD
    UPDATE product_company_mapping 
    SET label_lid = old_label_id, updated_at = CURRENT_TIMESTAMP, updated_by = p_created_by
    WHERE company_lid = p_company_lid 
    AND label_lid = new_label_id 
    AND active = true;
    
    -- Insert new mapping with NEW label (no receipt for single mapping)
    INSERT INTO product_company_mapping(product_lid, company_lid, label_lid, notes, created_by)
    VALUES (p_product_lid, p_company_lid, new_label_id, p_notes, p_created_by);
    
    -- Calculate remaining available units
    current_active_mappings := current_active_mappings + 1;
    
    result = jsonb_build_object(
        'status', 'success', 
        'message', 'Product "' || product_name || '" mapped to "' || company_name || '". ' || 
                  current_active_mappings || ' of ' || product_unit_qty || ' units now mapped.',
        'data', jsonb_build_object(
            'total_units', product_unit_qty,
            'mapped_units', current_active_mappings,
            'available_units', product_unit_qty - current_active_mappings,
            'product_name', product_name,
            'company_name', company_name
        )
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result = jsonb_build_object('status', 'error', 'message', 'Error mapping product: ' || SQLERRM);
        RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ================== STEP 5: BULK MAPPING FUNCTION WITH RECEIPTS =================================================

-- Function for bulk mapping multiple products to one company with receipt
CREATE OR REPLACE FUNCTION bulk_map_products_to_company(
    product_list JSONB, -- Array of product IDs
    p_company_lid INT,
    p_notes TEXT,
    p_created_by INT
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
    receipt_num VARCHAR(20);
    receipt_id INT;
    new_label_id INT;
    old_label_id INT;
    company_name VARCHAR(255);
    product_record RECORD;
    success_count INT := 0;
    error_count INT := 0;
    total_count INT;
    error_messages TEXT[] := ARRAY[]::TEXT[];
    success_products TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Validate inputs
    IF product_list IS NULL OR jsonb_array_length(product_list) = 0 THEN
        result = '{"status": "error", "message": "No products provided for mapping."}'::JSONB;
        RETURN result;
    END IF;
    
    total_count := jsonb_array_length(product_list);
    
    -- Get label IDs
    SELECT id INTO new_label_id FROM label WHERE name = 'NEW' AND active = true LIMIT 1;
    SELECT id INTO old_label_id FROM label WHERE name = 'OLD' AND active = true LIMIT 1;
    
    IF new_label_id IS NULL OR old_label_id IS NULL THEN
        result = '{"status": "error", "message": "Required labels (NEW/OLD) not found."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Get company name
    SELECT name INTO company_name FROM company WHERE id = p_company_lid AND active = true;
    IF company_name IS NULL THEN
        result = '{"status": "error", "message": "Company not found or inactive."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Generate receipt number and create receipt
    receipt_num := generate_receipt_number();
    
    INSERT INTO mapping_receipt(receipt_number, company_lid, total_products, notes, created_by)
    VALUES (receipt_num, p_company_lid, total_count, p_notes, p_created_by)
    RETURNING id INTO receipt_id;
    
    -- Update existing NEW products for this company to OLD
    UPDATE product_company_mapping 
    SET label_lid = old_label_id, updated_at = CURRENT_TIMESTAMP, updated_by = p_created_by
    WHERE company_lid = p_company_lid 
    AND label_lid = new_label_id 
    AND active = true;
    
    -- Process each product
    FOR product_record IN (
        SELECT (value::text)::INTEGER as product_id
        FROM jsonb_array_elements(product_list)
    ) LOOP
        DECLARE
            product_name VARCHAR(255);
            product_unit_qty INTEGER;
            current_mappings INTEGER;
        BEGIN
            -- Get product details
            SELECT name, unit
            INTO product_name, product_unit_qty
            FROM product 
            WHERE id = product_record.product_id AND active = true;
            
            IF product_name IS NULL THEN
                error_count := error_count + 1;
                error_messages := array_append(error_messages, 'Product ID ' || product_record.product_id || ' not found');
                CONTINUE;
            END IF;
            
            -- Check current mappings
            SELECT COUNT(*) INTO current_mappings
            FROM product_company_mapping 
            WHERE product_lid = product_record.product_id AND active = true;
            
            -- Check if already mapped to this company
            IF EXISTS (SELECT 1 FROM product_company_mapping 
                       WHERE product_lid = product_record.product_id AND company_lid = p_company_lid AND active = true) THEN
                error_count := error_count + 1;
                error_messages := array_append(error_messages, '"' || product_name || '" already mapped to this company');
                CONTINUE;
            END IF;
            
            -- Check unit availability
            IF current_mappings >= product_unit_qty THEN
                error_count := error_count + 1;
                error_messages := array_append(error_messages, '"' || product_name || '" has no available units (' || current_mappings || '/' || product_unit_qty || ' mapped)');
                CONTINUE;
            END IF;
            
            -- Create mapping with receipt reference
            INSERT INTO product_company_mapping(product_lid, company_lid, label_lid, receipt_lid, notes, created_by)
            VALUES (product_record.product_id, p_company_lid, new_label_id, receipt_id, 
                   'Bulk mapped via receipt ' || receipt_num, p_created_by);
            
            success_count := success_count + 1;
            success_products := array_append(success_products, product_name);
            
        EXCEPTION
            WHEN OTHERS THEN
                error_count := error_count + 1;
                error_messages := array_append(error_messages, 'Error processing product ID ' || product_record.product_id || ': ' || SQLERRM);
        END;
    END LOOP;
    
    -- Update receipt with actual success count
    UPDATE mapping_receipt 
    SET total_products = success_count 
    WHERE id = receipt_id;
    
    -- Prepare result
    IF success_count = 0 THEN
        result = jsonb_build_object(
            'status', 'error',
            'message', 'No products were successfully mapped.',
            'data', jsonb_build_object(
                'receipt_number', receipt_num,
                'receipt_id', receipt_id,
                'success_count', success_count,
                'error_count', error_count,
                'errors', error_messages
            )
        );
    ELSIF error_count = 0 THEN
        result = jsonb_build_object(
            'status', 'success',
            'message', 'All ' || success_count || ' products successfully mapped to "' || company_name || '" with receipt ' || receipt_num,
            'data', jsonb_build_object(
                'receipt_number', receipt_num,
                'receipt_id', receipt_id,
                'success_count', success_count,
                'error_count', error_count,
                'successful_products', success_products
            )
        );
    ELSE
        result = jsonb_build_object(
            'status', 'partial',
            'message', success_count || ' products mapped successfully, ' || error_count || ' failed. Receipt: ' || receipt_num,
            'data', jsonb_build_object(
                'receipt_number', receipt_num,
                'receipt_id', receipt_id,
                'success_count', success_count,
                'error_count', error_count,
                'successful_products', success_products,
                'errors', error_messages
            )
        );
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result = jsonb_build_object('status', 'error', 'message', 'Error in bulk mapping: ' || SQLERRM);
        RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ================== STEP 6: HELPER FUNCTIONS =================================================

-- Function to check product availability with mapping details
CREATE OR REPLACE FUNCTION get_product_availability(p_product_lid INT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    product_info RECORD;
    current_mappings INTEGER;
    company_details JSONB;
BEGIN
    -- Get product details
    SELECT id, name, product_code, unit
    INTO product_info
    FROM product 
    WHERE id = p_product_lid AND active = true;
    
    IF product_info.id IS NULL THEN
        result = '{"status": "error", "message": "Product not found or inactive."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Count current active mappings
    SELECT COUNT(*) INTO current_mappings
    FROM product_company_mapping 
    WHERE product_lid = p_product_lid AND active = true;
    
    -- Get company mapping details including receipt info
    SELECT jsonb_agg(
        jsonb_build_object(
            'company_id', c.id,
            'company_name', c.name,
            'company_code', c.company_code,
            'label', l.name,
            'mapping_date', pcm.mapping_date,
            'receipt_number', mr.receipt_number,
            'receipt_id', mr.id,
            'notes', pcm.notes
        )
    ) INTO company_details
    FROM product_company_mapping pcm
    JOIN company c ON pcm.company_lid = c.id
    JOIN label l ON pcm.label_lid = l.id
    LEFT JOIN mapping_receipt mr ON pcm.receipt_lid = mr.id
    WHERE pcm.product_lid = p_product_lid AND pcm.active = true;
    
    result = jsonb_build_object(
        'status', 'success',
        'data', jsonb_build_object(
            'product_id', product_info.id,
            'product_name', product_info.name,
            'product_code', product_info.product_code,
            'total_units', product_info.unit,
            'mapped_units', current_mappings,
            'available_units', product_info.unit - current_mappings,
            'can_map_more', (product_info.unit - current_mappings) > 0,
            'mapped_companies', COALESCE(company_details, '[]'::jsonb)
        )
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result = jsonb_build_object('status', 'error', 'message', 'Error checking availability: ' || SQLERRM);
        RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to get all receipts with details
CREATE OR REPLACE FUNCTION get_mapping_receipts()
RETURNS TABLE(
    receipt_id INT,
    receipt_number VARCHAR(20),
    company_name VARCHAR(255),
    company_code VARCHAR(100),
    total_products INT,
    mapping_date TIMESTAMP,
    notes TEXT,
    products JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mr.id,
        mr.receipt_number,
        c.name,
        c.company_code,
        mr.total_products,
        mr.mapping_date,
        mr.notes,
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'product_id', p.id,
                    'product_name', p.name,
                    'product_code', p.product_code,
                    'label', l.name
                )
            ) FILTER (WHERE p.id IS NOT NULL),
            '[]'::jsonb
        ) as products
    FROM mapping_receipt mr
    JOIN company c ON mr.company_lid = c.id
    LEFT JOIN product_company_mapping pcm ON mr.id = pcm.receipt_lid AND pcm.active = true
    LEFT JOIN product p ON pcm.product_lid = p.id
    LEFT JOIN label l ON pcm.label_lid = l.id
    WHERE mr.active = true
    GROUP BY mr.id, mr.receipt_number, c.name, c.company_code, mr.total_products, mr.mapping_date, mr.notes
    ORDER BY mr.mapping_date DESC;
END;
$$ LANGUAGE plpgsql;