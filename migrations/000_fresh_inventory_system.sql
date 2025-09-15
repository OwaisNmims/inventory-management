-- Fresh Inventory System Migration
-- Drops legacy tables and recreates a clean schema aligned to per-unit inventory

BEGIN;


-- 1) Core master tables
DROP TABLE IF EXISTS company CASCADE;
CREATE TABLE company (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  company_code VARCHAR(100) NOT NULL UNIQUE,
  company_type VARCHAR(40) NOT NULL CHECK (company_type IN ('SELF','VENDOR','CUSTOMER')) DEFAULT 'SELF',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,
  created_by INT,
  updated_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Self company seed
INSERT INTO company(name, company_code, company_type, created_by)
VALUES('SELF', 'SELF', 'SELF', 1)
ON CONFLICT (company_code) DO NOTHING;

-- give me alter statement for product table to add column specifications text
ALTER TABLE product ADD COLUMN specifications text;

ALTER TABLE product DROP COLUMN specifications;



ERROR:  column "specifications" of relation "product" already exists 

SQL state: 42701


CREATE TABLE product (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  product_code VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  category VARCHAR(120),
  price NUMERIC(12,2),
  specifications text,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,
  created_by INT,
  updated_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Inventory status reference
CREATE TABLE inventory_status (
  id SERIAL PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO inventory_status(name, description) VALUES
  ('AVAILABLE','Unit is available for mapping'),
  ('MAPPED','Unit is mapped to a company'),
  ('SOLD','Unit has been sold'),
  ('RESERVED','Unit is reserved for an order')
ON CONFLICT DO NOTHING;

-- Label reference for mapping (NEW/OLD)
CREATE TABLE mapping_label (
  id SERIAL PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO mapping_label(name, description) VALUES
  ('NEW','Newly added inventory for company'),
  ('OLD','Previously existing inventory for company')
ON CONFLICT DO NOTHING;

-- Per-unit inventory
CREATE TABLE inventory_unit (
  id SERIAL PRIMARY KEY,
  product_lid INT NOT NULL REFERENCES product(id),
  status_lid INT NOT NULL REFERENCES inventory_status(id),
  current_company_lid INT NULL REFERENCES company(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,
  created_by INT,
  updated_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_inventory_unit_product ON inventory_unit(product_lid);
CREATE INDEX idx_inventory_unit_status ON inventory_unit(status_lid);
CREATE INDEX idx_inventory_unit_company ON inventory_unit(current_company_lid);

-- Mapping inventory to company with labels

DROP TABLE IF EXISTS inventory_company_mapping CASCADE;
CREATE TABLE inventory_company_mapping (
  id SERIAL PRIMARY KEY,
  inventory_unit_lid INT NOT NULL REFERENCES inventory_unit(id) ,
  company_lid INT NOT NULL REFERENCES company(id) ,
  label_lid INT NOT NULL REFERENCES mapping_label(id),
  order_lid INT NULL REFERENCES customer_order(id),
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,
  created_by INT,
  updated_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (inventory_unit_lid) -- only one active mapping per unit at a time enforced via active flag
);

CREATE INDEX idx_inventory_company_mapping_company ON inventory_company_mapping(company_lid);

-- Orders
CREATE TABLE customer_order (
  id SERIAL PRIMARY KEY,
  company_lid INT NOT NULL REFERENCES company(id),
  order_number TEXT NOT NULL UNIQUE,
  notes TEXT, 
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE customer_order_item (
  id SERIAL PRIMARY KEY,
  order_lid INT NOT NULL REFERENCES customer_order(id),
  product_lid INT NOT NULL REFERENCES product(id),
  inventory_unit_lid INT NULL REFERENCES inventory_unit(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Helper: get status ids
CREATE OR REPLACE FUNCTION get_inventory_status_id(p_name TEXT) RETURNS INT AS $$
DECLARE sid INT; BEGIN
  SELECT id INTO sid FROM inventory_status WHERE name = p_name AND active=TRUE LIMIT 1;
  IF sid IS NULL THEN RAISE EXCEPTION 'Missing inventory_status: %', p_name; END IF;
  RETURN sid;
END; $$ LANGUAGE plpgsql;

-- Helper: get label ids
CREATE OR REPLACE FUNCTION get_mapping_label_id(p_name TEXT) RETURNS INT AS $$
DECLARE lid INT; BEGIN
  SELECT id INTO lid FROM mapping_label WHERE name = p_name AND active=TRUE LIMIT 1;
  IF lid IS NULL THEN RAISE EXCEPTION 'Missing mapping_label: %', p_name; END IF;
  RETURN lid;
END; $$ LANGUAGE plpgsql;

-- 2) Product insert that auto-creates inventory units based on unit count and maps to SELF
DROP FUNCTION IF EXISTS insert_products(JSONB, INT);
CREATE OR REPLACE FUNCTION insert_products(
  new_products JSONB,
  var_created_by INT
) RETURNS JSONB AS $$
DECLARE
  result JSONB := jsonb_build_object('status','success','message','Products inserted');
  p RECORD; inserted_product_id INT; self_company_id INT; status_available INT; label_new INT;
  unit_count INT; i INT;
BEGIN
  SELECT id INTO self_company_id FROM company WHERE company_code='SELF' AND active=TRUE LIMIT 1;
  status_available := get_inventory_status_id('AVAILABLE');
  label_new := get_mapping_label_id('NEW');

  IF new_products IS NULL OR jsonb_typeof(new_products) <> 'array' THEN
    RETURN jsonb_build_object('status','error','message','Invalid payload');
  END IF;

  CREATE TEMP TABLE IF NOT EXISTS temp_products (
    name TEXT, product_code TEXT, description TEXT, category TEXT, price NUMERIC(12,2), unit_count INT, specifications TEXT
  ) ON COMMIT DROP;

  INSERT INTO temp_products(name, product_code, description, category, price, unit_count, specifications)
  SELECT 
    COALESCE(value->>'name','')::TEXT,
    COALESCE(value->>'productCode','')::TEXT,
    NULLIF(value->>'description',''),
    NULLIF(value->>'category',''),
    NULLIF(value->>'price','')::NUMERIC,
    COALESCE((value->>'unit')::INT, 1),
    NULLIF(value->>'specifications','')
  FROM jsonb_array_elements(new_products);

  FOR p IN (
    SELECT * FROM temp_products
  ) LOOP
    IF p.name IS NULL OR p.name='' OR p.product_code IS NULL OR p.product_code='' THEN
      CONTINUE; -- skip invalid
    END IF;

    INSERT INTO product(name, product_code, description, category, price, specifications, created_by)
    VALUES(p.name, UPPER(p.product_code), p.description, p.category, p.price, p.specifications, var_created_by)
    ON CONFLICT (product_code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO inserted_product_id;

    -- Create inventory units based on unit count
    unit_count := GREATEST(1, COALESCE(p.unit_count, 1));
    
    FOR i IN 1..unit_count LOOP
      INSERT INTO inventory_unit(product_lid, status_lid, current_company_lid, created_by)
      VALUES (inserted_product_id, status_available, self_company_id, var_created_by);
    END LOOP;

    -- Map all units to SELF as NEW
    INSERT INTO inventory_company_mapping(inventory_unit_lid, company_lid, label_lid, notes, created_by)
    SELECT iu.id, self_company_id, label_new, 'Auto-map on product create', var_created_by
    FROM inventory_unit iu
    WHERE iu.product_lid = inserted_product_id 
    AND NOT EXISTS (
      SELECT 1 FROM inventory_company_mapping icm WHERE icm.inventory_unit_lid = iu.id AND icm.active = TRUE
    );
  END LOOP;

  RETURN result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message','insert_products failed: '||SQLERRM);
END; $$ LANGUAGE plpgsql;

-- 3) Order creation that allocates available units and labels mapping NEW/OLD
DROP FUNCTION IF EXISTS create_order_and_allocate(JSONB, INT, TEXT, INT);
CREATE OR REPLACE FUNCTION create_order_and_allocate(
  p_items JSONB,           -- [{"productId":1,"qty":2},...]
  p_company_lid INT,
  p_notes TEXT,
  p_created_by INT
) RETURNS JSONB AS $$
DECLARE
  order_id INT; item RECORD; i INT; status_available INT; status_mapped INT; label_new INT; label_old INT;
  unit_id INT; existing_mapping_id INT; first_time BOOLEAN;
  order_number TEXT := 'ORD-'||to_char(clock_timestamp(),'YYYYMMDDHH24MISSMS');
  result JSONB := jsonb_build_object('status','success','message','Order created');
BEGIN
  status_available := get_inventory_status_id('AVAILABLE');
  status_mapped := get_inventory_status_id('MAPPED');
  label_new := get_mapping_label_id('NEW');
  label_old := get_mapping_label_id('OLD');

  INSERT INTO customer_order(company_lid, order_number, notes, created_by)
  VALUES(p_company_lid, order_number, p_notes, p_created_by)
  RETURNING id INTO order_id;

  FOR item IN SELECT (value->>'productId')::INT AS product_id, GREATEST(1,COALESCE((value->>'qty')::INT,1)) AS qty FROM jsonb_array_elements(p_items) LOOP
    -- determine if this company already had mappings for this product before this order
    SELECT EXISTS (
      SELECT 1 FROM inventory_company_mapping m
      JOIN inventory_unit u ON u.id = m.inventory_unit_lid
      WHERE m.company_lid = p_company_lid AND u.product_lid = item.product_id AND m.active = TRUE
    ) INTO first_time;

    FOR i IN 1..item.qty LOOP
      -- pick an available unit
      SELECT id INTO unit_id FROM inventory_unit 
      WHERE product_lid = item.product_id AND status_lid = status_available
      ORDER BY id ASC LIMIT 1;

      IF unit_id IS NULL THEN
        result := result || jsonb_build_object('warning', 'Insufficient inventory for product '||item.product_id);
        EXIT; -- out of qty loop
      END IF;

      -- assign to company and mark MAPPED
      UPDATE inventory_unit SET status_lid = status_mapped, current_company_lid = p_company_lid, updated_at=CURRENT_TIMESTAMP, updated_by=p_created_by
      WHERE id = unit_id;

      -- create mapping with NEW for units added in this order, mark previous active mappings for this product+company as OLD
      IF first_time THEN
        -- there were existing mappings, label this new one as OLD-like if instructed; per spec: all new inventories added should be labelled NEW and old mappings as OLD
        UPDATE inventory_company_mapping m SET label_lid = label_old, updated_at = CURRENT_TIMESTAMP, updated_by = p_created_by
        FROM inventory_unit u
        WHERE m.inventory_unit_lid = u.id AND m.company_lid = p_company_lid AND u.product_lid = item.product_id AND m.active = TRUE;
      END IF;

      INSERT INTO inventory_company_mapping(inventory_unit_lid, company_lid, label_lid, notes, created_by)
      VALUES(unit_id, p_company_lid, label_new, 'Allocated via order '||order_number, p_created_by)
      RETURNING id INTO existing_mapping_id;

      INSERT INTO customer_order_item(order_lid, product_lid, inventory_unit_lid, quantity, created_by)
      VALUES(order_id, item.product_id, unit_id, 1, p_created_by);

      -- after first allocation for this product in this order, flip first_time to TRUE so subsequent ones become NEW but previous are OLD
      first_time := TRUE;
    END LOOP;
  END LOOP;

  RETURN result || jsonb_build_object('orderId', order_id, 'orderNumber', order_number);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('status','error','message','create_order_and_allocate failed: '||SQLERRM);
END; $$ LANGUAGE plpgsql;

COMMIT;


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

DROP TABLE IF EXISTS company CASCADE;
CREATE TABLE company (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  company_code VARCHAR(100) NOT NULL UNIQUE,
  company_type VARCHAR(40) NOT NULL CHECK (company_type IN ('SELF','VENDOR')) DEFAULT 'VENDOR',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,
  created_by INT,
  updated_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

select * from company


-- Self company seed
INSERT INTO company(name, company_code, company_type, created_by)
VALUES('JEAN FENDI', 'SELF', 'SELF', 1)
ON CONFLICT (company_code) DO NOTHING;


-- 3.2: LABEL MASTER (no dependencies)
-- Label reference for mapping (NEW/OLD)
CREATE TABLE mapping_label (
  id SERIAL PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO mapping_label(name, description) VALUES
  ('NEW','Newly added inventory for company'),
  ('OLD','Previously existing inventory for company')
ON CONFLICT DO NOTHING;


-- 3.3: PRODUCT MASTER (no dependencies)

CREATE TABLE product (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  product_code VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  category VARCHAR(120),
  price NUMERIC(12,2),
  specifications JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,
  created_by INT,
  updated_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE inventory_status (
  id SERIAL PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO inventory_status(name, description) VALUES
  ('AVAILABLE','Unit is available for mapping'),
  ('MAPPED','Unit is mapped to a company'),
  ('SOLD','Unit has been sold'),
  ('RESERVED','Unit is reserved for an order')
ON CONFLICT DO NOTHING;

DROP TABLE IF EXISTS inventory_unit;
CREATE TABLE inventory_unit (
  id SERIAL PRIMARY KEY,
  product_lid INT NOT NULL REFERENCES product(id),
  status_lid INT NOT NULL REFERENCES inventory_status(id),
  current_company_lid INT NULL REFERENCES company(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,
  created_by INT,
  updated_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_inventory_unit_product ON inventory_unit(product_lid);
CREATE INDEX idx_inventory_unit_status ON inventory_unit(status_lid);
CREATE INDEX idx_inventory_unit_company ON inventory_unit(current_company_lid);


DROP TABLE IF EXISTS inventory_company_mapping CASCADE;
CREATE TABLE inventory_company_mapping (
  id SERIAL PRIMARY KEY,
  inventory_unit_lid INT NOT NULL REFERENCES inventory_unit(id) ,
  company_lid INT NOT NULL REFERENCES company(id) ,
  label_lid INT NOT NULL REFERENCES mapping_label(id),
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP,
  created_by INT,
  updated_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (inventory_unit_lid) -- only one active mapping per unit at a time enforced via active flag
);

CREATE INDEX idx_inventory_company_mapping_company ON inventory_company_mapping(company_lid);

-- Orders
CREATE TABLE customer_order (
  id SERIAL PRIMARY KEY,
  company_lid INT NOT NULL REFERENCES company(id),
  order_number TEXT NOT NULL UNIQUE,
  notes TEXT, 
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE customer_order_item (
  id SERIAL PRIMARY KEY,
  order_lid INT NOT NULL REFERENCES customer_order(id),
  product_lid INT NOT NULL REFERENCES product(id),
  inventory_unit_lid INT NULL REFERENCES inventory_unit(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by INT,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

    // Soft delete product
    // write a function to delete product and all its inventory units and mapping to company
    // this should only happen if the product is not mapped to any company which is not self company
    // if the product is mapped to any company which is not self company, then it should not be deleted
    // if the product is mapped to self company, then it should be deleted
    // also if the inventory all units should be available.
    // give me sql function for this and handle it in the controller.

    DROP FUNCTION IF EXISTS delete_product(INT, INT);
    CREATE OR REPLACE FUNCTION delete_product(
        p_product_lid INT,
        p_created_by INT
    ) RETURNS TEXT AS $$
    BEGIN
        -- Check if product is mapped to any company which is not self company
        IF EXISTS (
            SELECT 1 FROM inventory_company_mapping icm
            JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
            JOIN company c ON c.id = icm.company_lid
            WHERE iu.product_lid = p_product_lid AND c.company_code != 'SELF'
        ) THEN
            RAISE EXCEPTION 'Product is mapped to a non-self company';
        END IF;

    --check if inventory units have inventory status as available
    IF EXISTS (
        SELECT 1 FROM inventory_unit iu
        JOIN inventory_status ist ON ist.id = iu.status_lid AND ist.name != 'AVAILABLE'
        WHERE iu.product_lid = p_product_lid
    ) THEN
        RAISE EXCEPTION 'Inventory units are not available';
    END IF;

    UPDATE product SET active = false, updated_at = CURRENT_TIMESTAMP, updated_by = p_created_by where id = p_product_lid;

    UPDATE inventory_unit SET 
        active = false,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_created_by
    WHERE product_lid = p_product_lid;

    DELETE FROM inventory_company_mapping WHERE inventory_unit_lid IN (SELECT id FROM inventory_unit WHERE product_lid = p_product_lid);    

    RETURN 'Product deleted successfully'::TEXT;
    END;
    $$ LANGUAGE plpgsql;
