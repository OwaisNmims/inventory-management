-- FUNCTION: public.get_product_company_mappings()

-- DROP FUNCTION IF EXISTS public.get_product_company_mappings();

CREATE OR REPLACE FUNCTION public.get_product_company_mappings(
	)
    RETURNS TABLE(mapping_id integer, product_id integer, product_name character varying, product_code character varying, company_id integer, company_name character varying, company_code character varying, label_id integer, label_name character varying, mapping_date timestamp without time zone, notes text, inventory_unit_lid integer, created_at timestamp without time zone) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
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
        pcm.inventory_unit_lid,
        pcm.created_at
    FROM product_company_mapping pcm
    JOIN product p ON p.id = pcm.product_lid AND p.active = true
    JOIN company c ON c.id = pcm.company_lid AND c.active = true
    JOIN label l ON l.id = pcm.label_lid AND l.active = true
    WHERE pcm.active = true
    ORDER BY pcm.mapping_date DESC, c.name, p.name;
END;
$BODY$;

ALTER FUNCTION public.get_product_company_mappings()
    OWNER TO postgres;
-- FUNCTION: public.insert_products(jsonb, integer)

-- DROP FUNCTION IF EXISTS public.insert_products(jsonb, integer);

CREATE OR REPLACE FUNCTION public.insert_products(
	new_products jsonb,
	var_created_by integer)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    result JSONB;
    self_company_id INTEGER;
    inserted_product_id INTEGER;
    product_record RECORD;
    v_units INTEGER;
BEGIN
    
    -- Get the self company ID
    SELECT c.id INTO self_company_id 
    FROM company c 
    JOIN company_type ct ON c.company_type_lid = ct.id 
    WHERE ct.name = 'SELF' AND c.active = TRUE 
    LIMIT 1;
    
    -- Check if we have both self company and NEW label
    IF self_company_id IS NULL THEN
        result = '{"status": "error", "message": "Self company not found. Please create a company with type SELF."}'::JSONB;
        RETURN result;
    END IF;
    
    DROP TABLE IF EXISTS temp_products;
    CREATE TEMP TABLE temp_products (
        name VARCHAR(255),
        product_code VARCHAR(100),
        description TEXT,
        category VARCHAR(100),
        price NUMERIC(10,2),
        unit INTEGER,
        specifications TEXT
    );
    
    INSERT INTO temp_products(name, product_code, description, category, price, unit, specifications)
    SELECT
        product->>'name',
        product->>'productCode',
        product->>'description',
        product->>'category',
        (product->>'price')::NUMERIC,
        (product->>'unit')::INTEGER,
        product->>'specifications'
    FROM
        jsonb_array_elements(new_products) AS product;
    
    IF EXISTS (SELECT * FROM temp_products tp
               INNER JOIN product p ON (p.product_code = tp.product_code OR p.name = tp.name)
               WHERE p.active = true) 
    THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
    ELSE
        result := '{"status": "success", "message": "Products inserted successfully and inventory created under SELF!"}'::JSONB;
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
        
        -- Create inventory rows under SELF, status AVAILABLE
        v_units := COALESCE(product_record.unit, 0);
        IF v_units < 1 THEN v_units := 1; END IF;

        INSERT INTO inventory_unit (product_lid, unit_serial, status, current_company_lid, created_by)
        SELECT inserted_product_id,
               'P' || inserted_product_id::TEXT || '-' || LPAD(gs::TEXT, 6, '0'),
               'AVAILABLE',
               self_company_id,
               var_created_by
        FROM generate_series(1, v_units) AS gs;
    END LOOP;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result = '{"status": "error", "message": "Something went wrong! ' || SQLERRM || '"}'::JSONB;
        RAISE;
END;
$BODY$;

ALTER FUNCTION public.insert_products(jsonb, integer)
    OWNER TO postgres;