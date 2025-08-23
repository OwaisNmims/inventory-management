-- ================== CASCADE DROP COMPANY AND PRODUCT SYSTEM =================================================
-- This script will only drop company master and product management system tables/functions
-- Keeps all existing tables (country, city, currency_type, expenses, state, tour, hotels, etc.)

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

COMMIT;

-- Success message
SELECT 'Company and Product management tables/functions dropped successfully with CASCADE!' as status; 