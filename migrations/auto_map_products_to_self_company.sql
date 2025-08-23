-- Migration: Auto-map products to self company
-- This script modifies the insert_products function to automatically create 
-- a mapping between newly inserted products and the self company

-- Drop the existing function
DROP FUNCTION IF EXISTS insert_products(JSONB, INTEGER);

-- Create the enhanced function that auto-maps to self company
CREATE OR REPLACE FUNCTION insert_products(
    new_products JSONB,
    var_created_by INTEGER
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
    self_company_id INTEGER;
    new_label_id INTEGER;
    inserted_product_id INTEGER;
    product_record RECORD;
BEGIN
    var_created_by := 1;
    
    -- Get the self company ID
    SELECT c.id INTO self_company_id 
    FROM company c 
    JOIN company_type ct ON c.company_type_lid = ct.id 
    WHERE ct.name = 'SELF' AND c.active = TRUE 
    LIMIT 1;
    
    -- Get the NEW label ID
    SELECT id INTO new_label_id 
    FROM label 
    WHERE name = 'NEW' AND active = TRUE 
    LIMIT 1;
    
    -- Check if we have both self company and NEW label
    IF self_company_id IS NULL THEN
        result = '{"status": "error", "message": "Self company not found. Please create a company with type SELF."}'::JSONB;
        RETURN result;
    END IF;
    
    IF new_label_id IS NULL THEN
        result = '{"status": "error", "message": "NEW label not found. Please create a label named NEW."}'::JSONB;
        RETURN result;
    END IF;
    
    DROP TABLE IF EXISTS temp_products;
    CREATE TEMP TABLE temp_products (
        name VARCHAR(255),
        product_code VARCHAR(100),
        description TEXT,
        category VARCHAR(100),
        price NUMERIC(10,2),
        unit VARCHAR(50),
        specifications TEXT
    );
    
    INSERT INTO temp_products(name, product_code, description, category, price, unit, specifications)
    SELECT
        product->>'name',
        product->>'productCode',
        product->>'description',
        product->>'category',
        (product->>'price')::NUMERIC,
        product->>'unit',
        product->>'specifications'
    FROM
        jsonb_array_elements(new_products) AS product;
    
    IF EXISTS (SELECT * FROM temp_products tp
               INNER JOIN product p ON (p.product_code = tp.product_code OR p.name = tp.name)
               WHERE p.active = true) 
    THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
    ELSE
        result := '{"status": "success", "message": "Products inserted successfully and mapped to self company!"}'::JSONB;
    END IF;
    
    -- Insert products and capture their IDs for mapping
    FOR product_record IN (
        SELECT tp.name, tp.product_code, tp.description, tp.category, tp.price, tp.unit, tp.specifications
        FROM temp_products tp
        LEFT JOIN (SELECT * FROM product WHERE active = true) p ON 
        (p.product_code = tp.product_code OR p.name = tp.name)
        WHERE p.id IS NULL
    ) LOOP
        -- Insert the product
        INSERT INTO product(name, product_code, description, category, price, unit, specifications, created_by)
        VALUES (product_record.name, product_record.product_code, product_record.description, 
                product_record.category, product_record.price, product_record.unit, 
                product_record.specifications, var_created_by)
        RETURNING id INTO inserted_product_id;
        
        -- Create the mapping to self company with NEW label
        INSERT INTO product_company_mapping(product_lid, company_lid, label_lid, notes, created_by)
        VALUES (inserted_product_id, self_company_id, new_label_id, 
                'Auto-mapped to self company on product creation', var_created_by);
    END LOOP;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong! ' || SQLERRM || '"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- Also create/update the map_product_to_company function if it doesn't exist
CREATE OR REPLACE FUNCTION map_product_to_company(
    product_id INTEGER,
    company_id INTEGER,
    notes_text TEXT,
    created_by_user INTEGER
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
    default_label_id INTEGER;
BEGIN
    -- Get the NEW label ID as default
    SELECT id INTO default_label_id 
    FROM label 
    WHERE name = 'NEW' AND active = TRUE 
    LIMIT 1;
    
    IF default_label_id IS NULL THEN
        result = '{"status": "error", "message": "Default label NEW not found."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Check if mapping already exists
    IF EXISTS (SELECT 1 FROM product_company_mapping 
               WHERE product_lid = product_id AND company_lid = company_id AND active = true) THEN
        result = '{"status": "error", "message": "Product is already mapped to this company."}'::JSONB;
    ELSE
        INSERT INTO product_company_mapping(product_lid, company_lid, label_lid, notes, created_by)
        VALUES (product_id, company_id, default_label_id, notes_text, created_by_user);
        
        result = '{"status": "success", "message": "Product mapped to company successfully!"}'::JSONB;
    END IF;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong! ' || SQLERRM || '"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;