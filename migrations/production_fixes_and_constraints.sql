-- Production-level fixes and proper constraints for enhanced mapping system
-- This ensures data integrity and proper validation

-- ================== STEP 1: ADD PROPER FOREIGN KEY CONSTRAINTS =================================================

-- Ensure receipt_lid foreign key is properly set with cascade options
ALTER TABLE product_company_mapping 
DROP CONSTRAINT IF EXISTS product_company_mapping_receipt_lid_fkey;

ALTER TABLE product_company_mapping 
ADD CONSTRAINT product_company_mapping_receipt_lid_fkey 
FOREIGN KEY (receipt_lid) REFERENCES mapping_receipt(id) 
ON DELETE SET NULL ON UPDATE CASCADE;

-- Add proper indexes for performance
CREATE INDEX IF NOT EXISTS idx_product_company_mapping_receipt_lid ON product_company_mapping(receipt_lid);
CREATE INDEX IF NOT EXISTS idx_product_company_mapping_product_active ON product_company_mapping(product_lid) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_product_company_mapping_company_active ON product_company_mapping(company_lid) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_mapping_receipt_company ON mapping_receipt(company_lid);
CREATE INDEX IF NOT EXISTS idx_mapping_receipt_date ON mapping_receipt(mapping_date);

-- ================== STEP 2: ENHANCED VALIDATION FUNCTIONS =================================================

-- Updated map_product_to_company with proper duplicate handling
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
    existing_mapping_count INTEGER;
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
    
    -- Count existing mappings to this specific company
    SELECT COUNT(*) INTO existing_mapping_count
    FROM product_company_mapping 
    WHERE product_lid = p_product_lid AND company_lid = p_company_lid AND active = true;
    
    -- Check if no units available
    IF current_active_mappings >= product_unit_qty THEN
        result = jsonb_build_object(
            'status', 'error', 
            'message', 'Cannot map product "' || product_name || '". All ' || product_unit_qty || 
                      ' units are already mapped to other companies. Available: 0, Mapped: ' || current_active_mappings
        );
        RETURN result;
    END IF;
    
    -- Check if already mapped to this company (only if multiple units available)
    IF existing_mapping_count > 0 AND product_unit_qty = 1 THEN
        result = jsonb_build_object(
            'status', 'error', 
            'message', 'Product "' || product_name || '" is already mapped to company "' || company_name || '" and only has 1 unit available.'
        );
        RETURN result;
    END IF;
    
    -- If multiple units and already mapped, allow additional mapping
    IF existing_mapping_count > 0 AND product_unit_qty > 1 THEN
        -- Check if we can add another mapping
        IF current_active_mappings >= product_unit_qty THEN
            result = jsonb_build_object(
                'status', 'error', 
                'message', 'Cannot add another mapping for "' || product_name || '" to "' || company_name || '". All ' || product_unit_qty || ' units are already mapped.'
            );
            RETURN result;
        END IF;
    END IF;
    
    -- Update existing NEW products for this company to OLD (only if this is first mapping to this company)
    IF existing_mapping_count = 0 THEN
        UPDATE product_company_mapping 
        SET label_lid = old_label_id, updated_at = CURRENT_TIMESTAMP, updated_by = p_created_by
        WHERE company_lid = p_company_lid 
        AND label_lid = new_label_id 
        AND active = true;
    END IF;
    
    -- Insert new mapping with NEW label
    INSERT INTO product_company_mapping(product_lid, company_lid, label_lid, notes, created_by)
    VALUES (p_product_lid, p_company_lid, new_label_id, p_notes, p_created_by);
    
    -- Calculate remaining available units
    current_active_mappings := current_active_mappings + 1;
    
    result = jsonb_build_object(
        'status', 'success', 
        'message', 'Product "' || product_name || '" mapped to "' || company_name || '". ' || 
                  current_active_mappings || ' of ' || product_unit_qty || ' units now mapped. Available: ' ||
                  (product_unit_qty - current_active_mappings),
        'data', jsonb_build_object(
            'total_units', product_unit_qty,
            'mapped_units', current_active_mappings,
            'available_units', product_unit_qty - current_active_mappings,
            'product_name', product_name,
            'company_name', company_name,
            'existing_mappings_to_company', existing_mapping_count + 1
        )
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result = jsonb_build_object('status', 'error', 'message', 'Error mapping product: ' || SQLERRM);
        RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Enhanced bulk mapping with better validation
DROP FUNCTION IF EXISTS bulk_map_products_to_company(JSONB, INT, TEXT, INT);
CREATE OR REPLACE FUNCTION bulk_map_products_to_company(
    product_list JSONB,
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
    validation_errors TEXT[] := ARRAY[]::TEXT[];
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
    
    -- Pre-validate all products before creating receipt
    FOR product_record IN (
        SELECT (value::text)::INTEGER as product_id
        FROM jsonb_array_elements(product_list)
    ) LOOP
        DECLARE
            product_name VARCHAR(255);
            product_unit_qty INTEGER;
            current_mappings INTEGER;
            existing_company_mappings INTEGER;
        BEGIN
            -- Get product details
            SELECT name, unit
            INTO product_name, product_unit_qty
            FROM product 
            WHERE id = product_record.product_id AND active = true;
            
            IF product_name IS NULL THEN
                validation_errors := array_append(validation_errors, 'Product ID ' || product_record.product_id || ' not found');
                CONTINUE;
            END IF;
            
            -- Check current mappings
            SELECT COUNT(*) INTO current_mappings
            FROM product_company_mapping 
            WHERE product_lid = product_record.product_id AND active = true;
            
            SELECT COUNT(*) INTO existing_company_mappings
            FROM product_company_mapping 
            WHERE product_lid = product_record.product_id AND company_lid = p_company_lid AND active = true;
            
            -- Validate availability
            IF current_mappings >= product_unit_qty THEN
                validation_errors := array_append(validation_errors, '"' || product_name || '" has no available units (' || current_mappings || '/' || product_unit_qty || ' mapped)');
            ELSIF existing_company_mappings > 0 AND product_unit_qty = 1 THEN
                validation_errors := array_append(validation_errors, '"' || product_name || '" is already mapped to this company and only has 1 unit');
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                validation_errors := array_append(validation_errors, 'Error validating product ID ' || product_record.product_id || ': ' || SQLERRM);
        END;
    END LOOP;
    
    -- If validation errors, return them without creating receipt
    IF array_length(validation_errors, 1) > 0 THEN
        result = jsonb_build_object(
            'status', 'error',
            'message', 'Validation failed for ' || array_length(validation_errors, 1) || ' product(s). No mappings created.',
            'data', jsonb_build_object(
                'validation_errors', validation_errors,
                'total_errors', array_length(validation_errors, 1)
            )
        );
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
    
    -- Process each product (validation already passed)
    FOR product_record IN (
        SELECT (value::text)::INTEGER as product_id
        FROM jsonb_array_elements(product_list)
    ) LOOP
        DECLARE
            product_name VARCHAR(255);
        BEGIN
            -- Get product name
            SELECT name INTO product_name FROM product WHERE id = product_record.product_id AND active = true;
            
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
    result = jsonb_build_object(
        'status', 'success',
        'message', 'Successfully mapped ' || success_count || ' products to "' || company_name || '" with receipt ' || receipt_num,
        'data', jsonb_build_object(
            'receipt_number', receipt_num,
            'receipt_id', receipt_id,
            'success_count', success_count,
            'error_count', error_count,
            'successful_products', success_products,
            'errors', error_messages
        )
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result = jsonb_build_object('status', 'error', 'message', 'Error in bulk mapping: ' || SQLERRM);
        RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ================== STEP 3: ADD DATA INTEGRITY CHECKS =================================================

-- Function to validate data integrity
CREATE OR REPLACE FUNCTION validate_mapping_integrity()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check 1: Orphaned receipt references
    RETURN QUERY
    SELECT 
        'Orphaned Receipt References'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'Found ' || COUNT(*) || ' mappings with invalid receipt references'::TEXT
    FROM product_company_mapping pcm
    LEFT JOIN mapping_receipt mr ON pcm.receipt_lid = mr.id
    WHERE pcm.receipt_lid IS NOT NULL AND mr.id IS NULL;
    
    -- Check 2: Overmapped products
    RETURN QUERY
    SELECT 
        'Overmapped Products'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'Found ' || COUNT(*) || ' products with more mappings than available units'::TEXT
    FROM (
        SELECT p.id, p.name, p.unit, COUNT(pcm.id) as mapping_count
        FROM product p
        LEFT JOIN product_company_mapping pcm ON p.id = pcm.product_lid AND pcm.active = true
        GROUP BY p.id, p.name, p.unit
        HAVING COUNT(pcm.id) > p.unit
    ) overmapped;
    
    -- Check 3: Receipt consistency
    RETURN QUERY
    SELECT 
        'Receipt Product Count Consistency'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'Found ' || COUNT(*) || ' receipts with mismatched product counts'::TEXT
    FROM (
        SELECT mr.id, mr.total_products, COUNT(pcm.id) as actual_count
        FROM mapping_receipt mr
        LEFT JOIN product_company_mapping pcm ON mr.id = pcm.receipt_lid AND pcm.active = true
        WHERE mr.active = true
        GROUP BY mr.id, mr.total_products
        HAVING mr.total_products != COUNT(pcm.id)
    ) inconsistent;
    
END;
$$ LANGUAGE plpgsql;

-- ================== STEP 4: UPDATE EXISTING FUNCTIONS FOR RECEIPT SUPPORT =================================================

-- Enhanced get_product_company_mappings to include receipt information
CREATE OR REPLACE FUNCTION get_product_company_mappings()
RETURNS TABLE(
    mapping_id INT,
    product_id INT,
    product_name VARCHAR(255),
    product_code VARCHAR(100),
    company_id INT,
    company_name VARCHAR(255),
    company_code VARCHAR(100),
    label_id INT,
    label_name VARCHAR(50),
    receipt_id INT,
    receipt_number VARCHAR(20),
    mapping_date TIMESTAMP,
    notes TEXT,
    created_by INT,
    created_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pcm.id as mapping_id,
        p.id as product_id,
        p.name as product_name,
        p.product_code,
        c.id as company_id,
        c.name as company_name,
        c.company_code,
        l.id as label_id,
        l.name as label_name,
        mr.id as receipt_id,
        mr.receipt_number,
        pcm.mapping_date,
        pcm.notes,
        pcm.created_by,
        pcm.created_at
    FROM product_company_mapping pcm
    JOIN product p ON pcm.product_lid = p.id AND p.active = true
    JOIN company c ON pcm.company_lid = c.id AND c.active = true
    JOIN label l ON pcm.label_lid = l.id AND l.active = true
    LEFT JOIN mapping_receipt mr ON pcm.receipt_lid = mr.id AND mr.active = true
    WHERE pcm.active = true
    ORDER BY pcm.created_at DESC;
END;
$$ LANGUAGE plpgsql;