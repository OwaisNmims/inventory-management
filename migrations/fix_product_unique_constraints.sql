-- Fix product unique constraints to allow reusing names/codes from deleted products
-- This migration drops the simple UNIQUE constraint and creates partial UNIQUE indexes
-- that only apply to active products

-- Drop the existing UNIQUE constraint on product_code
ALTER TABLE public.product 
    DROP CONSTRAINT IF EXISTS product_product_code_key;

-- Create partial UNIQUE index for product_code (only for active products)
-- This allows deleted products (active=false) to have duplicate codes
CREATE UNIQUE INDEX IF NOT EXISTS ux_product_code_active 
    ON public.product(product_code) 
    WHERE active = true;

-- Create partial UNIQUE index for product_name (only for active products)
-- This allows deleted products (active=false) to have duplicate names
CREATE UNIQUE INDEX IF NOT EXISTS ux_product_name_active 
    ON public.product(name) 
    WHERE active = true;

-- Verify the indexes were created
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'product'
AND indexname IN ('ux_product_code_active', 'ux_product_name_active');
