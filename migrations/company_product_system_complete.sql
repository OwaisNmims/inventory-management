-- ================== COMPLETE COMPANY & PRODUCT MANAGEMENT SYSTEM =================================================
-- This script drops and recreates the entire company and product management system in correct hierarchy
-- Run this single file to get everything set up in one go

-- ================== STEP 1: DROP EXISTING FUNCTIONS (with exact signatures) =================================================

-- Drop product management functions first (with exact signatures)
DROP FUNCTION IF EXISTS insert_labels(JSONB, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS insert_products(JSONB, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS update_product(INT, VARCHAR(255), VARCHAR(100), TEXT, VARCHAR(100), NUMERIC(10,2), VARCHAR(50), TEXT, INT) CASCADE;
DROP FUNCTION IF EXISTS map_product_to_company(INT, INT, TEXT, INT) CASCADE;
DROP FUNCTION IF EXISTS update_product_mapping_label(INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS get_product_company_mappings() CASCADE;
DROP FUNCTION IF EXISTS transfer_product_to_company(INT, INT, TEXT, INT) CASCADE;

-- Drop company system functions (with exact signatures)
DROP FUNCTION IF EXISTS insert_companies(JSONB, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS update_company(INT, VARCHAR(255), VARCHAR(100), VARCHAR(255), VARCHAR(50), VARCHAR(255), VARCHAR(255), INT, INT, INT, VARCHAR(100), VARCHAR(100), VARCHAR(100), INT, VARCHAR(255), INT) CASCADE;
DROP FUNCTION IF EXISTS add_new_companies(json, int) CASCADE;
DROP FUNCTION IF EXISTS insert_company_types(JSONB, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS update_company_type(INT, VARCHAR(100), VARCHAR(255), INT) CASCADE;
DROP FUNCTION IF EXISTS add_new_company_types(json, int) CASCADE;

-- ================== STEP 2: DROP EXISTING TABLES (in reverse dependency order) =================================================

-- Drop product management tables (in dependency order)
DROP TABLE IF EXISTS product_company_mapping CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS label CASCADE;

-- Drop company system tables (in dependency order) 
DROP TABLE IF EXISTS company CASCADE;
DROP TABLE IF EXISTS company_type CASCADE;

-- Drop related sequences
DROP SEQUENCE IF EXISTS company_id_seq CASCADE;
DROP SEQUENCE IF EXISTS company_type_id_seq CASCADE;
DROP SEQUENCE IF EXISTS label_id_seq CASCADE;
DROP SEQUENCE IF EXISTS product_id_seq CASCADE;
DROP SEQUENCE IF EXISTS product_company_mapping_id_seq CASCADE;

-- ================== STEP 3: CREATE TABLES (in correct dependency order) =================================================

-- 3.1: COMPANY TYPE MASTER (no dependencies)
CREATE TABLE company_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
    active BOOLEAN NOT NULL DEFAULT(true)
);

-- 3.2: LABEL MASTER (no dependencies)
CREATE TABLE label (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
    active BOOLEAN NOT NULL DEFAULT(true)
);

-- 3.3: PRODUCT MASTER (no dependencies)
CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    product_code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    category VARCHAR(100),
    price NUMERIC(10,2),
    unit VARCHAR(50),
    specifications TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
    active BOOLEAN NOT NULL DEFAULT(true)
);

-- 3.4: COMPANY MASTER (depends on company_type, country, state, city)
CREATE TABLE company (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    company_code VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255),
    phone VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    country_lid INT REFERENCES country(id),
    state_lid INT REFERENCES state(id), 
    city_lid INT REFERENCES city(id),
    postal_code VARCHAR(100),
    registration_number VARCHAR(100),
    tax_number VARCHAR(100),
    company_type_lid INT REFERENCES company_type(id),
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
    active BOOLEAN NOT NULL DEFAULT(true)
);

-- 3.5: PRODUCT COMPANY MAPPING (depends on product, company, label)
CREATE TABLE product_company_mapping (
    id SERIAL PRIMARY KEY,
    product_lid INT NOT NULL REFERENCES product(id),
    company_lid INT NOT NULL REFERENCES company(id),
    label_lid INT NOT NULL REFERENCES label(id),
    mapping_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
    active BOOLEAN NOT NULL DEFAULT(true),
    UNIQUE(product_lid, company_lid)
);

-- ================== STEP 4: INSERT INITIAL DATA =================================================

-- Insert initial company types
INSERT INTO company_type (name, description, created_by) VALUES 
('SELF', 'Self-owned company', 1),
('VENDOR', 'External vendor company', 1);

-- Insert initial labels
INSERT INTO label (name, description, created_by) VALUES 
('NEW', 'Newly added product for the company', 1),
('OLD', 'Previously added product that is no longer new', 1),
('SOLD', 'Product that has been sold', 1);

-- ================== STEP 5: CREATE FUNCTIONS =================================================

-- 5.1: COMPANY TYPE FUNCTIONS
CREATE OR REPLACE FUNCTION insert_company_types(
    new_company_types JSONB,
    var_created_by INTEGER
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    var_created_by := 1;
    
    DROP TABLE IF EXISTS temp_company_types;
    CREATE TEMP TABLE temp_company_types (
        name VARCHAR(100),
        description VARCHAR(255)
    );
    
    INSERT INTO temp_company_types(name, description)
    SELECT
        company_type->>'name',
        company_type->>'description'
    FROM
        jsonb_array_elements(new_company_types) AS company_type;
    
    IF EXISTS (SELECT * FROM temp_company_types tc
               INNER JOIN company_type ct ON
               ct.name = tc.name
               WHERE ct.active = true) 
    THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
    ELSE
        result := '{"status": "success", "message": "Company types inserted successfully!"}'::JSONB;
    END IF;
    
    INSERT INTO company_type(name, description, created_by)
    SELECT tc.name, tc.description, var_created_by 
    FROM temp_company_types tc
    LEFT JOIN (SELECT * FROM company_type WHERE active = true) ct ON 
    ct.name = tc.name
    WHERE ct.id IS NULL;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_company_type(
    company_type_id INT,
    new_name VARCHAR(100),
    new_description VARCHAR(255),
    updated_by_user INT
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    IF EXISTS (SELECT 1 FROM company_type 
               WHERE name = new_name 
               AND id != company_type_id AND active = true) THEN
        result = '{"status": "error", "message": "Duplicate company type name."}'::JSONB;
    ELSE
        UPDATE company_type
        SET
            name = new_name,
            description = new_description,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = updated_by_user
        WHERE id = company_type_id;

        result = jsonb_build_object('status', 'success', 'message', 'Company type updated successfully');
    END IF;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_new_company_types(IN input_json json, IN username int)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
      i jsonb;
      output_result JSONB;
      error_result JSONB;
      _count int;
      
BEGIN
        DROP TABLE IF EXISTS temp_company_types_bulk;
        CREATE TEMPORARY TABLE temp_company_types_bulk(
            id SERIAL PRIMARY KEY,
            name varchar(100),
            description varchar(255)
        );
        
        _count:= 0;
        
        FOR i IN SELECT * FROM json_array_elements(input_json)
        LOOP
            INSERT INTO temp_company_types_bulk(name, description) 
            VALUES (i->>'name', i->>'description');   
        END LOOP;    
        
        _count := (select count(distinct ct.name) from company_type ct 
                     join temp_company_types_bulk tc on ct.name = tc.name 
                     where ct.active = true);
                        
        if(_count > 0) then
                    SELECT jsonb_build_object(
                        'status', 500,
                        'message', 'duplicate',
                        'error_result', jsonb_agg(row_to_json(row))
                    ) AS error_response into error_result
                    FROM (
                        SELECT DISTINCT ct.name
                        FROM company_type ct
                        JOIN temp_company_types_bulk tc ON ct.name = tc.name
                        where ct.active = true
                    ) AS row;
            output_result:=  error_result;
        else 
            MERGE INTO company_type ct
            using (SELECT distinct name, description from temp_company_types_bulk) tc 
            on ct.name = tc.name
            WHEN MATCHED THEN
                 UPDATE SET active = true, updated_at = now(), updated_by = username
            WHEN NOT MATCHED THEN 
            INSERT (name, description, created_by) 
            VALUES (tc.name, tc.description, username);
        
            output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
        end if;
                
RETURN output_result;     
END;
$BODY$;

-- 5.2: LABEL FUNCTIONS
CREATE OR REPLACE FUNCTION insert_labels(
    new_labels JSONB,
    var_created_by INTEGER
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    var_created_by := 1;
    
    DROP TABLE IF EXISTS temp_labels;
    CREATE TEMP TABLE temp_labels (
        name VARCHAR(50),
        description VARCHAR(255)
    );
    
    INSERT INTO temp_labels(name, description)
    SELECT
        label->>'name',
        label->>'description'
    FROM
        jsonb_array_elements(new_labels) AS label;
    
    IF EXISTS (SELECT * FROM temp_labels tl
               INNER JOIN label l ON l.name = tl.name
               WHERE l.active = true) 
    THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
    ELSE
        result := '{"status": "success", "message": "Labels inserted successfully!"}'::JSONB;
    END IF;
    
    INSERT INTO label(name, description, created_by)
    SELECT tl.name, tl.description, var_created_by 
    FROM temp_labels tl
    LEFT JOIN (SELECT * FROM label WHERE active = true) l ON l.name = tl.name
    WHERE l.id IS NULL;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- 5.3: PRODUCT FUNCTIONS
CREATE OR REPLACE FUNCTION insert_products(
    new_products JSONB,
    var_created_by INTEGER
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    var_created_by := 1;
    
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
        result := '{"status": "success", "message": "Products inserted successfully!"}'::JSONB;
    END IF;
    
    INSERT INTO product(name, product_code, description, category, price, unit, specifications, created_by)
    SELECT tp.name, tp.product_code, tp.description, tp.category, tp.price, tp.unit, tp.specifications, var_created_by 
    FROM temp_products tp
    LEFT JOIN (SELECT * FROM product WHERE active = true) p ON 
    (p.product_code = tp.product_code OR p.name = tp.name)
    WHERE p.id IS NULL;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_product(
    product_id INT,
    new_name VARCHAR(255),
    new_product_code VARCHAR(100),
    new_description TEXT,
    new_category VARCHAR(100),
    new_price NUMERIC(10,2),
    new_unit VARCHAR(50),
    new_specifications TEXT,
    updated_by_user INT
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    IF EXISTS (SELECT 1 FROM product 
               WHERE (name = new_name OR product_code = new_product_code) 
               AND id != product_id AND active = true) THEN
        result = '{"status": "error", "message": "Duplicate product name or code."}'::JSONB;
    ELSE
        UPDATE product
        SET
            name = new_name,
            product_code = new_product_code,
            description = new_description,
            category = new_category,
            price = new_price,
            unit = new_unit,
            specifications = new_specifications,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = updated_by_user
        WHERE id = product_id;

        result = jsonb_build_object('status', 'success', 'message', 'Product updated successfully');
    END IF;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- 5.4: COMPANY FUNCTIONS
CREATE OR REPLACE FUNCTION insert_companies(
    new_companies JSONB,
    var_created_by INTEGER
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    var_created_by := 1;
    
    DROP TABLE IF EXISTS temp_companies;
    CREATE TEMP TABLE temp_companies (
        name VARCHAR(255),
        company_code VARCHAR(100),
        email VARCHAR(255),
        phone VARCHAR(50),
        address_line1 VARCHAR(255),
        address_line2 VARCHAR(255),
        country_lid INT,
        state_lid INT,
        city_lid INT,
        postal_code VARCHAR(100),
        registration_number VARCHAR(100),
        tax_number VARCHAR(100),
        company_type_lid INT,
        website VARCHAR(255)
    );
    
    INSERT INTO temp_companies(name, company_code, email, phone, address_line1, address_line2, 
                              country_lid, state_lid, city_lid, postal_code, registration_number, 
                              tax_number, company_type_lid, website)
    SELECT
        company->>'name',
        company->>'companyCode',
        company->>'email',
        company->>'phone',
        company->>'addressLine1',
        company->>'addressLine2',
        (company->>'countryLid')::INT,
        (company->>'stateLid')::INT,
        (company->>'cityLid')::INT,
        company->>'postalCode',
        company->>'registrationNumber',
        company->>'taxNumber',
        (company->>'companyTypeLid')::INT,
        company->>'website'
    FROM
        jsonb_array_elements(new_companies) AS company;
    
    IF EXISTS (SELECT * FROM temp_companies tc
               INNER JOIN company c ON
               (c.company_code = tc.company_code OR c.name = tc.name)
               WHERE c.active = true) 
    THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
    ELSE
        result := '{"status": "success", "message": "Companies inserted successfully!"}'::JSONB;
    END IF;
    
    INSERT INTO company(name, company_code, email, phone, address_line1, address_line2,
                       country_lid, state_lid, city_lid, postal_code, registration_number,
                       tax_number, company_type_lid, website, created_by)
    SELECT tc.name, tc.company_code, tc.email, tc.phone, tc.address_line1, tc.address_line2,
           tc.country_lid, tc.state_lid, tc.city_lid, tc.postal_code, tc.registration_number,
           tc.tax_number, tc.company_type_lid, tc.website, var_created_by 
    FROM temp_companies tc
    LEFT JOIN (SELECT * FROM company WHERE active = true) c ON 
    (c.company_code = tc.company_code OR c.name = tc.name)
    WHERE c.id IS NULL;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_company(
    company_id INT,
    new_company_name VARCHAR(255),
    new_company_code VARCHAR(100),
    new_email VARCHAR(255),
    new_phone VARCHAR(50),
    new_address_line1 VARCHAR(255),
    new_address_line2 VARCHAR(255),
    new_country_lid INT,
    new_state_lid INT,
    new_city_lid INT,
    new_postal_code VARCHAR(100),
    new_registration_number VARCHAR(100),
    new_tax_number VARCHAR(100),
    new_company_type_lid INT,
    new_website VARCHAR(255),
    updated_by_user INT
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    IF EXISTS (SELECT 1 FROM company 
               WHERE (name = new_company_name OR company_code = new_company_code) 
               AND id != company_id AND active = true) THEN
        result = '{"status": "error", "message": "Duplicate company name or code."}'::JSONB;
    ELSE
        UPDATE company
        SET
            name = new_company_name,
            company_code = new_company_code,
            email = new_email,
            phone = new_phone,
            address_line1 = new_address_line1,
            address_line2 = new_address_line2,
            country_lid = new_country_lid,
            state_lid = new_state_lid,
            city_lid = new_city_lid,
            postal_code = new_postal_code,
            registration_number = new_registration_number,
            tax_number = new_tax_number,
            company_type_lid = new_company_type_lid,
            website = new_website,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = updated_by_user
        WHERE id = company_id;

        result = jsonb_build_object('status', 'success', 'message', 'Company updated successfully');
    END IF;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_new_companies(IN input_json json, IN username int)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
      i jsonb;
      output_result JSONB;
      error_result JSONB;
      _count int;
      
BEGIN
        DROP TABLE IF EXISTS temp_companies_bulk;
        CREATE TEMPORARY TABLE temp_companies_bulk(
            id SERIAL PRIMARY KEY,
            name varchar(255),
            company_code varchar(100)
        );
        
        _count:= 0;
        
        FOR i IN SELECT * FROM json_array_elements(input_json)
        LOOP
            INSERT INTO temp_companies_bulk(name, company_code) 
            VALUES (i->>'name', i->>'companyCode');   
        END LOOP;    
        
        _count := (select count(distinct c.name) from company c 
                     join temp_companies_bulk tc on (c.name = tc.name OR c.company_code = tc.company_code) 
                     where c.active = true);
                        
        if(_count > 0) then
                    SELECT jsonb_build_object(
                        'status', 500,
                        'message', 'duplicate',
                        'error_result', jsonb_agg(row_to_json(row))
                    ) AS error_response into error_result
                    FROM (
                        SELECT DISTINCT c.name, c.company_code
                        FROM company c
                        JOIN temp_companies_bulk tc ON (c.name = tc.name OR c.company_code = tc.company_code)
                        where c.active = true
                    ) AS row;
            output_result:=  error_result;
        else 
            MERGE INTO company c
            using (SELECT distinct name, company_code from temp_companies_bulk) tc 
            on (c.name = tc.name OR c.company_code = tc.company_code)
            WHEN MATCHED THEN
                 UPDATE SET active = true, updated_at = now(), updated_by = username
            WHEN NOT MATCHED THEN 
            INSERT (name, company_code, created_by) 
            VALUES (tc.name, tc.company_code, username);
        
            output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
        end if;
                
RETURN output_result;     
END;
$BODY$;

-- 5.5: PRODUCT COMPANY MAPPING FUNCTIONS
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
BEGIN
    SELECT id INTO new_label_id FROM label WHERE name = 'NEW' AND active = true;
    SELECT id INTO old_label_id FROM label WHERE name = 'OLD' AND active = true;
    
    -- Check if product is already actively mapped to this company
    IF EXISTS (SELECT 1 FROM product_company_mapping 
               WHERE product_lid = p_product_lid AND company_lid = p_company_lid AND active = true) THEN
        result = '{"status": "error", "message": "Product is already mapped to this company."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Check if product is already actively mapped to ANY other company
    IF EXISTS (SELECT 1 FROM product_company_mapping 
               WHERE product_lid = p_product_lid AND company_lid != p_company_lid AND active = true) THEN
        result = '{"status": "error", "message": "Product is already actively mapped to another company. Please transfer it instead."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Update existing products for this company (that are not SOLD) to OLD
    UPDATE product_company_mapping 
    SET label_lid = old_label_id, updated_at = CURRENT_TIMESTAMP, updated_by = p_created_by
    WHERE company_lid = p_company_lid 
    AND label_lid = new_label_id 
    AND active = true;
    
    -- Insert new mapping with NEW label
    INSERT INTO product_company_mapping(product_lid, company_lid, label_lid, notes, created_by)
    VALUES (p_product_lid, p_company_lid, new_label_id, p_notes, p_created_by);
    
    result = '{"status": "success", "message": "Product mapped successfully and existing products updated to OLD."}'::JSONB;
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_product_mapping_label(
    p_mapping_id INT,
    p_label_lid INT,
    p_updated_by INT
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    UPDATE product_company_mapping 
    SET label_lid = p_label_lid, updated_at = CURRENT_TIMESTAMP, updated_by = p_updated_by
    WHERE id = p_mapping_id AND active = true;
    
    IF FOUND THEN
        result = '{"status": "success", "message": "Product mapping label updated successfully."}'::JSONB;
    ELSE
        result = '{"status": "error", "message": "Mapping not found or already inactive."}'::JSONB;
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_product_company_mappings()
RETURNS TABLE (
    mapping_id INT,
    product_id INT,
    product_name VARCHAR,
    product_code VARCHAR,
    company_id INT,
    company_name VARCHAR,
    company_code VARCHAR,
    label_id INT,
    label_name VARCHAR,
    mapping_date TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pcm.id,
        p.id,
        p.name,
        p.product_code,
        c.id,
        c.name,
        c.company_code,
        l.id,
        l.name,
        pcm.mapping_date,
        pcm.notes,
        pcm.created_at
    FROM product_company_mapping pcm
    JOIN product p ON p.id = pcm.product_lid AND p.active = true
    JOIN company c ON c.id = pcm.company_lid AND c.active = true
    JOIN label l ON l.id = pcm.label_lid AND l.active = true
    WHERE pcm.active = true
    ORDER BY pcm.mapping_date DESC, c.name, p.name;
END;
$$ LANGUAGE plpgsql;

-- TRANSFER PRODUCT BETWEEN COMPANIES FUNCTION
CREATE OR REPLACE FUNCTION transfer_product_to_company(
    p_mapping_id INT,
    p_new_company_lid INT,
    p_notes TEXT,
    p_updated_by INT
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
    v_product_lid INT;
    v_current_company_lid INT;
    new_label_id INT;
    old_label_id INT;
BEGIN
    -- Get label IDs
    SELECT id INTO new_label_id FROM label WHERE name = 'NEW' AND active = true;
    SELECT id INTO old_label_id FROM label WHERE name = 'OLD' AND active = true;
    
    -- Get current mapping details
    SELECT product_lid, company_lid INTO v_product_lid, v_current_company_lid
    FROM product_company_mapping 
    WHERE id = p_mapping_id AND active = true;
    
    -- Check if mapping exists
    IF v_product_lid IS NULL THEN
        result = '{"status": "error", "message": "Mapping not found or inactive."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Check if transferring to the same company
    IF v_current_company_lid = p_new_company_lid THEN
        result = '{"status": "error", "message": "Product is already mapped to this company."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Check if product is already mapped to new company
    IF EXISTS (SELECT 1 FROM product_company_mapping 
               WHERE product_lid = v_product_lid AND company_lid = p_new_company_lid AND active = true) THEN
        result = '{"status": "error", "message": "Product is already mapped to the target company."}'::JSONB;
        RETURN result;
    END IF;
    
    -- Deactivate current mapping
    UPDATE product_company_mapping 
    SET active = false, updated_at = CURRENT_TIMESTAMP, updated_by = p_updated_by
    WHERE id = p_mapping_id;
    
    -- Update existing NEW products in new company to OLD
    UPDATE product_company_mapping 
    SET label_lid = old_label_id, updated_at = CURRENT_TIMESTAMP, updated_by = p_updated_by
    WHERE company_lid = p_new_company_lid 
    AND label_lid = new_label_id 
    AND active = true;
    
    -- Create new mapping with NEW label in the new company
    INSERT INTO product_company_mapping(product_lid, company_lid, label_lid, notes, created_by)
    VALUES (v_product_lid, p_new_company_lid, new_label_id, p_notes, p_updated_by);
    
    result = '{"status": "success", "message": "Product transferred successfully. Existing NEW products in target company updated to OLD."}'::JSONB;
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong during transfer!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- ================== COMPLETION MESSAGE =================================================

COMMIT;

SELECT 'Company and Product Management System created successfully with complete hierarchy!' as status; 