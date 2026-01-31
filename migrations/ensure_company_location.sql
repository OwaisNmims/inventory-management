-- Require state and city for companies
ALTER TABLE public.company
  ADD COLUMN IF NOT EXISTS email VARCHAR(255),
  ADD COLUMN IF NOT EXISTS phone VARCHAR(50),
  ADD COLUMN IF NOT EXISTS registration_number VARCHAR(100),
  ADD COLUMN IF NOT EXISTS tax_number VARCHAR(100),
  ADD COLUMN IF NOT EXISTS country_lid INT REFERENCES public.country(id),
  ADD COLUMN IF NOT EXISTS state_lid INT REFERENCES public.state(id),
  ADD COLUMN IF NOT EXISTS city_lid INT REFERENCES public.city(id);

-- Update insert_companies to require location fields
CREATE OR REPLACE FUNCTION public.insert_companies(
	new_companies jsonb,
	var_created_by integer)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    result JSONB;
    inserted_count INTEGER := 0;
    duplicate_count INTEGER := 0;
    company_record JSONB;
    comp_name VARCHAR(255);
    comp_code VARCHAR(100);
    comp_type VARCHAR(40);
    comp_state INT;
    comp_city INT;
BEGIN
    inserted_count := 0;
    duplicate_count := 0;

    FOR company_record IN SELECT * FROM jsonb_array_elements(new_companies)
    LOOP
        comp_name := company_record->>'name';
        comp_code := company_record->>'companyCode';
        comp_type := COALESCE(company_record->>'company_type', 'VENDOR');
        comp_state := (company_record->>'stateLid')::INT;
        comp_city := (company_record->>'cityLid')::INT;

        IF comp_name IS NULL OR comp_name = '' OR comp_code IS NULL OR comp_code = '' OR comp_state IS NULL OR comp_city IS NULL THEN
            CONTINUE;
        END IF;

        IF EXISTS (
            SELECT 1 FROM company c
            WHERE (c.name = comp_name OR c.company_code = comp_code) 
            AND c.active = true
        ) THEN
            duplicate_count := duplicate_count + 1;
        ELSE
            INSERT INTO company (
                name, 
                company_code, 
                company_type, 
                state_lid,
                city_lid,
                active, 
                created_at, 
                created_by
            ) VALUES (
                comp_name,
                comp_code,
                comp_type,
                comp_state,
                comp_city,
                true,
                CURRENT_TIMESTAMP,
                var_created_by
            );

            inserted_count := inserted_count + 1;
        END IF;
    END LOOP;

    IF inserted_count > 0 AND duplicate_count > 0 THEN
        result := jsonb_build_object(
            'status', 'success',
            'message', format('%s companies inserted successfully. %s duplicates skipped.', inserted_count, duplicate_count),
            'inserted_count', inserted_count,
            'duplicate_count', duplicate_count
        );
    ELSIF inserted_count > 0 THEN
        result := jsonb_build_object(
            'status', 'success',
            'message', format('%s companies inserted successfully!', inserted_count),
            'inserted_count', inserted_count,
            'duplicate_count', 0
        );
    ELSIF duplicate_count > 0 THEN
        result := jsonb_build_object(
            'status', 'warning',
            'message', format('All %s companies were duplicates. No new companies inserted.', duplicate_count),
            'inserted_count', 0,
            'duplicate_count', duplicate_count
        );
    ELSE
        result := jsonb_build_object(
            'status', 'error',
            'message', 'No valid companies provided.',
            'inserted_count', 0,
            'duplicate_count', 0
        );
    END IF;

    RETURN result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', format('Database error: %s', SQLERRM),
            'inserted_count', 0,
            'duplicate_count', 0
        );
END;
$BODY$;

ALTER FUNCTION public.insert_companies(jsonb, integer)
    OWNER TO postgres;

-- Update update_company to enforce required location parameters
CREATE OR REPLACE FUNCTION public.update_company(
	company_id integer,
	new_company_name character varying,
	new_company_code character varying,
	new_email character varying,
	new_phone character varying,
	new_address_line1 character varying,
	new_address_line2 character varying,
	new_country_lid integer,
	new_state_lid integer,
	new_city_lid integer,
	new_postal_code character varying,
	new_registration_number character varying,
	new_tax_number character varying,
	new_company_type character varying,
	new_website character varying,
	updated_by_user integer)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    result JSONB;
BEGIN
    IF new_state_lid IS NULL OR new_city_lid IS NULL THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'State and city are required for a company.'
        );
    END IF;

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
            company_type = new_company_type,
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
$BODY$;

ALTER FUNCTION public.update_company(integer, character varying, character varying, character varying, character varying, character varying, character varying, integer, integer, integer, character varying, character varying, character varying, character varying, character varying, integer)
    OWNER TO postgres;
