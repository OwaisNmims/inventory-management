--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Postgres.app)
-- Dumped by pg_dump version 17.0

-- Started on 2025-09-16 01:28:07 IST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 323 (class 1255 OID 16391)
-- Name: add_new_countries(json, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_new_countries(input_json json, username integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
      i jsonb;
	  output_result JSONB;
	  error_result JSONB;
	  _count int;
	  
BEGIN
			DROP TABLE IF EXISTS temp_countries;
			CREATE TEMPORARY TABLE temp_countries(
				id SERIAL PRIMARY KEY ,
				name varchar(255),
				code varchar(255)
			);
			
			_count:= 0;
			
			    -- Loop through array elements and insert into the temporary table
				 FOR i IN SELECT * FROM json_array_elements(input_json)
				LOOP
					INSERT INTO temp_countries(name, code) VALUES (i->>'name'::varchar, i->>'code'::varchar);   
				END LOOP;	
				
				_count := (SELECT COUNT(*) FROM country c 
						 	JOIN temp_countries tc ON c.name = tc.name and c.code = tc.code WHERE c.active = true GROUP BY c.name, c.code);
							
				if(_count > 0) then
							SELECT jsonb_build_object(
								'status', 500,
								'message', 'duplicate',
								'error_result', jsonb_agg(row_to_json(row))
							) AS error_response into error_result
							FROM (
								SELECT DISTINCT c.name
								FROM country c
								JOIN temp_countries tc ON c.name = tc.name
								where c.active = true
							) AS row;
					output_result:=  error_result;
			else 
				MERGE INTO country c
				using temp_countries tc 
				on c.name = tc.name and c.code = tc.code
				WHEN MATCHED THEN
					 UPDATE SET active = true, updated_at = now(), updated_by = username
				WHEN NOT MATCHED THEN 
				INSERT (name, code, created_by) 
				VALUES (tc.name, tc.code, username);
			
				output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
				end if;
				
					
RETURN output_result;	 
END;
$$;


ALTER FUNCTION public.add_new_countries(input_json json, username integer) OWNER TO postgres;

--
-- TOC entry 324 (class 1255 OID 16392)
-- Name: add_new_expenses(json, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_new_expenses(input_json json, username text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
      i text;
	  output_result JSONB;
	  error_result JSONB;
	  _count int;
	  
BEGIN
			DROP TABLE IF EXISTS temp_expenses;
			CREATE TEMPORARY TABLE temp_expenses(
				id SERIAL PRIMARY KEY ,
				name varchar(255)
			);
			
			_count:= 0;
			
			    -- Loop through array elements and insert into the temporary table
				 FOR i IN SELECT * FROM json_array_elements_text(input_json)
				LOOP
					INSERT INTO temp_expenses(name) VALUES (i);   
				END LOOP;	
				
				_count := (select count(distinct e.name) from expenses e 
						 	join temp_expenses te on e.name = te.name where e.active = true);
							
				if(_count > 0) then
							SELECT jsonb_build_object(
								'status', 500,
								'message', 'duplicate',
								'error_result', jsonb_agg(row_to_json(row))
							) AS error_response into error_result
							FROM (
								SELECT DISTINCT e.name
								FROM expenses e
								JOIN temp_expenses te ON e.name = te.name
								where e.active = true
							) AS row;
					output_result:=  error_result;
			else 
				MERGE INTO expenses e
				using (SELECT distinct name from temp_expenses) te 
				on e.name = te.name
				WHEN MATCHED THEN
					 UPDATE SET active = true, updated_at = now(), updated_by = username
				WHEN NOT MATCHED THEN 
				INSERT (name, created_by) 
				VALUES (te.name, username);
			
				output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
				end if;
				
					
RETURN output_result;	 
END;
$$;


ALTER FUNCTION public.add_new_expenses(input_json json, username text) OWNER TO postgres;

--
-- TOC entry 325 (class 1255 OID 16393)
-- Name: add_new_passenger_type(json, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_new_passenger_type(input_json json, username text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
      i text;
	  output_result JSONB;
	  error_result JSONB;
	  _count int;
	  
BEGIN
			DROP TABLE IF EXISTS temp_passenger_type;
			CREATE TEMPORARY TABLE temp_passenger_type(
				id SERIAL PRIMARY KEY ,
				name varchar(255)
			);
			
			_count:= 0;
			
			    -- Loop through array elements and insert into the temporary table
				 FOR i IN SELECT * FROM json_array_elements_text(input_json)
				LOOP
					INSERT INTO temp_passenger_type(name) VALUES (i);   
				END LOOP;	
				
				_count := (select count(distinct pt.name) from passenger_type pt 
						 	join temp_passenger_type tpt on pt.name = tpt.name where pt.active = true);
							
				if(_count > 0) then
							SELECT jsonb_build_object(
								'status', 500,
								'message', 'duplicate',
								'error_result', jsonb_agg(row_to_json(row))
							) AS error_response into error_result
							FROM (
								SELECT DISTINCT pt.name
								from passenger_type pt
								JOIN temp_passenger_type tpt ON pt.name = tpt.name
								where pt.active = true
							) AS row;
					output_result:=  error_result;
			else 
				MERGE INTO passenger_type pt
				using (SELECT distinct name from temp_passenger_type) tpt 
				on pt.name = tpt.name
				WHEN MATCHED THEN
					 UPDATE SET active = true, updated_at = now(), updated_by = username
				WHEN NOT MATCHED THEN 
				INSERT (name, created_by) 
				VALUES (tpt.name, username);
			
				output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
				end if;
				
					
RETURN output_result;	 
END;
$$;


ALTER FUNCTION public.add_new_passenger_type(input_json json, username text) OWNER TO postgres;

--
-- TOC entry 326 (class 1255 OID 16394)
-- Name: add_new_state(json, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_new_state(input_json json, username text) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
      i jsonb;
	  output_result JSONB;
	  error_result JSONB;
	  _count int;
	  
BEGIN
			DROP TABLE IF EXISTS temp_state;
			CREATE TEMPORARY TABLE temp_state(
				id SERIAL PRIMARY KEY ,
				country_lid int,
				name varchar(255)
			);
			
			_count:= 0;
			
			    -- Loop through array elements and insert into the temporary table
				 FOR i IN SELECT * FROM json_array_elements(input_json)
				LOOP
					INSERT INTO temp_state(country_lid, name) VALUES ((i->>'country_lid')::INT, i->>'name');   
				END LOOP;	
				
				 select count(*) into _count from state s 
				 join temp_state ts on s.name = ts.name and s.country_lid = ts.country_lid where s.active = true
				 group by s.name, s.country_lid;
							
				if(_count > 0) then
							SELECT jsonb_build_object(
								'status', 500,
								'message', 'duplicate',
								'error_result', jsonb_agg(row_to_json(row))
							) AS error_response into error_result
							FROM (
								SELECT DISTINCT s.name, s.country_lid
								FROM state s
								JOIN temp_state ts  on s.name = ts.name and s.country_lid = ts.country_lid where s.active = true
				 				group by s.name, s.country_lid
							) AS row;
					output_result:=  error_result;
			else 
				MERGE INTO state s
				using (SELECT distinct name, country_lid from temp_state) ts
				on s.name = ts.name and s.country_lid = ts.country_lid
				WHEN MATCHED THEN
					 UPDATE SET active = true, updated_at = now(), updated_by = username
				WHEN NOT MATCHED THEN 
				INSERT (name, country_lid, created_by) 
				VALUES (ts.name, ts.country_lid, username);
			
				output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
				end if;
				
					
RETURN output_result;	 
END;
$$;


ALTER FUNCTION public.add_new_state(input_json json, username text) OWNER TO postgres;

--
-- TOC entry 327 (class 1255 OID 16395)
-- Name: add_new_tax(json, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_new_tax(input_json json, username integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
      i text;
	  output_result JSONB;
	  error_result JSONB;
	  _count int;
	  
BEGIN
			DROP TABLE IF EXISTS temp_tax;
			CREATE TEMPORARY TABLE temp_tax(
				id SERIAL PRIMARY KEY ,
				name varchar(255),
				percentage NUMERIC
			);
			
			_count:= 0;
			
			    -- Loop through array elements and insert into the temporary table
				 FOR i IN SELECT * FROM json_array_elements_text(input_json)
				LOOP
					-- Assuming that `i` is a JSON text, parse it into a JSON object
					-- and then extract values
				INSERT INTO temp_tax(name, percentage)VALUES (i::json->>'tax', (i::json->>'percentage')::numeric);

				END LOOP;	
				
				_count := (SELECT COUNT(DISTINCT c.name) FROM tax c JOIN temp_tax tc ON c.name = tc.name WHERE c.active = true);

							
				if(_count > 0) then
							SELECT jsonb_build_object(
								'status', 500,
								'message', 'duplicate',
								'error_result', jsonb_agg(row_to_json(row))
							) AS error_response into error_result
							FROM (
								SELECT DISTINCT c.name
								FROM tax c
								JOIN temp_tax tc ON c.name = tc.name
								where c.active = true
							) AS row;
					output_result:=  error_result;
			else 
			MERGE INTO tax c
				using (SELECT distinct name, percentage from temp_tax) tc 
				on c.name = tc.name
				WHEN MATCHED THEN
					 UPDATE SET percentage = tc.percentage , active = true, updated_at = now(), updated_by = username
				WHEN NOT MATCHED THEN 
				INSERT (name, percentage, created_by) 
				VALUES (tc.name, tc.percentage, username);
			
				output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
				end if;

				
					
RETURN output_result;	 
END;
$$;


ALTER FUNCTION public.add_new_tax(input_json json, username integer) OWNER TO postgres;

--
-- TOC entry 328 (class 1255 OID 16396)
-- Name: add_new_tour(text, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_new_tour(tour_name text, tour_nights integer, username integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
      i text;
	  output_result JSONB;
	  error_result JSONB;
	  _count int;
	  
BEGIN
			_count:= 0;
				
				
				_count := (select count(*) from tour t 
						 	 where t.active = true and t.name = tour_name and t.duration_nights = tour_nights);
							
				if(_count > 0) then
							SELECT jsonb_build_object(
								'status', 500,
								'message', 'Tour with the same name and same duration already exists'
							) AS error_response into error_result;
					output_result:=  error_result;
			else 
				MERGE INTO tour t
				using (SELECT tour_name, tour_nights) tc 
				on t.name  = tc.tour_name and t.duration_nights = tc.tour_nights
				WHEN MATCHED THEN
					 UPDATE SET active = true, updated_at = now(), updated_by = username
				WHEN NOT MATCHED THEN 
				INSERT (name, duration_nights, duration_days, created_by) 
				VALUES (tc.tour_name, tc.tour_nights, tc.tour_nights + 1, username);
			
				output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
				end if;
				
					
RETURN output_result;	 
EXCEPTION
    WHEN OTHERS THEN
        -- Handle exceptions or errors if needed
		output_result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.add_new_tour(tour_name text, tour_nights integer, username integer) OWNER TO postgres;

--
-- TOC entry 329 (class 1255 OID 16397)
-- Name: add_new_users(json, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_new_users(input_json json, username integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
      i jsonb;
	  output_result JSONB;
	  error_result JSONB;
	  _count int;
	  
BEGIN
			DROP TABLE IF EXISTS temp_users;
			CREATE TEMPORARY TABLE temp_users(
				id SERIAL PRIMARY KEY ,
				firstname varchar(255),
				lastname varchar(255),
				email varchar(255),
				password varchar(255)
			);
			
			_count:= 0;
			
			    -- Loop through array elements and insert into the temporary table
				 FOR i IN SELECT * FROM json_array_elements(input_json)
				LOOP
					INSERT INTO temp_users(firstname, lastname,  email, password) 
					VALUES (i->>'firstName'::varchar, i->>'lastName'::varchar, i->>'email'::varchar, i->>'password'::varchar);   
				END LOOP;	
				
				_count := (SELECT COUNT(*) FROM users u 
						 	JOIN temp_users tu ON tu.email = u.email WHERE u.active = true GROUP BY u.email);
							
				if(_count > 0) then
							SELECT jsonb_build_object(
								'status', 500,
								'message', 'Duplicate',
								'error_result', jsonb_agg(row_to_json(row))
							) AS error_response into error_result
							FROM (
								SELECT DISTINCT u.firstname, u.lastname, u.email
								FROM users u 
						 		JOIN temp_users tu 
								ON tu.email = u.email 
								WHERE u.active = true
							) AS row;
					output_result:=  error_result;
			else 
				INSERT into users(firstname, lastname, email, password, created_by)
				SELECT tu.firstname, tu.lastname, tu.email, tu.password, username
				from temp_users tu;
			
				output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
				end if;
				
					
RETURN output_result;	 
END;
$$;


ALTER FUNCTION public.add_new_users(input_json json, username integer) OWNER TO postgres;

--
-- TOC entry 330 (class 1255 OID 16398)
-- Name: assign_imp_role(integer, integer, boolean, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.assign_imp_role(userid integer, _role_id integer, _active boolean, _created_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
    
    DECLARE
    output_result JSONB;
	_count int;
    BEGIN
 
    select count(id) into _count from user_roles ur where ur.user_id = userId and ur.role_id = _role_id;
   
   if(_count > 0) then
   	update user_roles set updated_at = now(), updated_by = _created_by ,  active = _active where user_id = userId and role_id  = _role_id; 
   else
   
   insert into user_roles(user_id, role_id, created_by) values(userId, _role_id, _created_by);
   END IF;
   	
    output_result:= '{"status":200, "message":"Successfull"}';
    
    RETURN output_result;
    END;
    $$;


ALTER FUNCTION public.assign_imp_role(userid integer, _role_id integer, _active boolean, _created_by integer) OWNER TO postgres;

--
-- TOC entry 353 (class 1255 OID 17302)
-- Name: backfill_inventory_units(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.backfill_inventory_units() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
  existing_count INT;
  to_create INT;
BEGIN
  FOR r IN SELECT id, unit FROM product WHERE active=TRUE LOOP
    SELECT COUNT(*) INTO existing_count FROM inventory_unit WHERE product_lid=r.id;
    to_create := GREATEST(0, r.unit - existing_count);
    IF to_create > 0 THEN
      INSERT INTO inventory_unit(product_lid, unit_serial)
      SELECT r.id, 'P' || r.id::TEXT || '-' || LPAD((existing_count + g.n)::TEXT, 6, '0')
      FROM generate_series(1, to_create) AS g(n);
    END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION public.backfill_inventory_units() OWNER TO postgres;

--
-- TOC entry 359 (class 1255 OID 17344)
-- Name: bulk_map_products_to_company(jsonb, integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.bulk_map_products_to_company(product_list jsonb, p_company_lid integer, p_notes text, p_created_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  receipt_num TEXT;
  receipt_id INT;
  success_count INT := 0;
  error_messages TEXT[] := ARRAY[]::TEXT[];
  product_record RECORD;
  new_label_id INT; old_label_id INT;
BEGIN
  IF product_list IS NULL OR jsonb_array_length(product_list)=0 THEN
    RETURN jsonb_build_object('status','error','message','No products provided');
  END IF;

  SELECT id INTO new_label_id FROM label WHERE name='NEW' AND active=TRUE LIMIT 1;
  SELECT id INTO old_label_id FROM label WHERE name='OLD' AND active=TRUE LIMIT 1;

  -- Create receipt
  receipt_num := generate_receipt_number();
  INSERT INTO mapping_receipt(receipt_number, company_lid, total_products, notes, created_by)
  VALUES (receipt_num, p_company_lid, 0, p_notes, p_created_by) RETURNING id INTO receipt_id;

  -- Update existing NEW to OLD
  UPDATE product_company_mapping SET label_lid=old_label_id, updated_at=NOW(), updated_by=p_created_by
  WHERE company_lid=p_company_lid AND label_lid=new_label_id AND active=TRUE;

  -- Allocate units
  FOR product_record IN SELECT (value::TEXT)::INT AS product_id FROM jsonb_array_elements(product_list) LOOP
    DECLARE inv_id INT;
    BEGIN
      SELECT id INTO inv_id FROM inventory_unit
      WHERE product_lid=product_record.product_id AND status='AVAILABLE'
      ORDER BY id ASC LIMIT 1;
      IF inv_id IS NULL THEN
        error_messages := array_append(error_messages, 'No available units for product '||product_record.product_id);
        CONTINUE;
      END IF;

      INSERT INTO product_company_mapping(product_lid, company_lid, label_lid, notes, created_by, receipt_lid, inventory_unit_lid)
      VALUES(product_record.product_id, p_company_lid, new_label_id, 'Bulk mapped via receipt '||receipt_num, p_created_by, receipt_id, inv_id);

      UPDATE inventory_unit SET status='MAPPED', current_company_lid=p_company_lid, mapped_at=NOW(), receipt_lid=receipt_id WHERE id=inv_id;
      success_count := success_count + 1;
    EXCEPTION WHEN OTHERS THEN
      error_messages := array_append(error_messages, 'Error mapping product '||product_record.product_id||': '||SQLERRM);
    END;
  END LOOP;

  -- Update receipt count
  UPDATE mapping_receipt SET total_products=success_count WHERE id=receipt_id;

  RETURN jsonb_build_object('status', CASE WHEN array_length(error_messages,1) IS NULL THEN 'success' ELSE 'partial' END,
                             'message', 'Mapped '||success_count||' unit(s) with receipt '||receipt_num,
                             'data', jsonb_build_object('receipt_id', receipt_id, 'receipt_number', receipt_num, 'errors', error_messages));
END;
$$;


ALTER FUNCTION public.bulk_map_products_to_company(product_list jsonb, p_company_lid integer, p_notes text, p_created_by integer) OWNER TO postgres;

--
-- TOC entry 362 (class 1255 OID 25741)
-- Name: calc(text, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calc(formula text, a numeric DEFAULT NULL::numeric, b numeric DEFAULT NULL::numeric, c numeric DEFAULT NULL::numeric, d numeric DEFAULT NULL::numeric, e numeric DEFAULT NULL::numeric, f numeric DEFAULT NULL::numeric, g numeric DEFAULT NULL::numeric, h numeric DEFAULT NULL::numeric, i numeric DEFAULT NULL::numeric, j numeric DEFAULT NULL::numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
BEGIN
    sql_expr := formula;
    
    -- Replace variables with values
    IF a IS NOT NULL THEN sql_expr := replace(sql_expr, 'a', a::TEXT); END IF;
    IF b IS NOT NULL THEN sql_expr := replace(sql_expr, 'b', b::TEXT); END IF;
    IF c IS NOT NULL THEN sql_expr := replace(sql_expr, 'c', c::TEXT); END IF;
    IF d IS NOT NULL THEN sql_expr := replace(sql_expr, 'd', d::TEXT); END IF;
    IF e IS NOT NULL THEN sql_expr := replace(sql_expr, 'e', e::TEXT); END IF;
    IF f IS NOT NULL THEN sql_expr := replace(sql_expr, 'f', f::TEXT); END IF;
    IF g IS NOT NULL THEN sql_expr := replace(sql_expr, 'g', g::TEXT); END IF;
    IF h IS NOT NULL THEN sql_expr := replace(sql_expr, 'h', h::TEXT); END IF;
    IF i IS NOT NULL THEN sql_expr := replace(sql_expr, 'i', i::TEXT); END IF;
    IF j IS NOT NULL THEN sql_expr := replace(sql_expr, 'j', j::TEXT); END IF;
    
    -- Execute calculation (PostgreSQL handles BODMAS automatically)
    EXECUTE 'SELECT (' || sql_expr || ')::NUMERIC' INTO result;
    
    RETURN COALESCE(result, 0);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
$$;


ALTER FUNCTION public.calc(formula text, a numeric, b numeric, c numeric, d numeric, e numeric, f numeric, g numeric, h numeric, i numeric, j numeric) OWNER TO postgres;

--
-- TOC entry 363 (class 1255 OID 25742)
-- Name: calculate(text, numeric, numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate(formula text, revenue numeric DEFAULT NULL::numeric, cost numeric DEFAULT NULL::numeric, visits numeric DEFAULT NULL::numeric, conversions numeric DEFAULT NULL::numeric, clicks numeric DEFAULT NULL::numeric, impressions numeric DEFAULT NULL::numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
BEGIN
    sql_expr := formula;
    
    -- Replace business variables with values
    IF revenue IS NOT NULL THEN 
        sql_expr := regexp_replace(sql_expr, '\mrevenue\M', revenue::TEXT, 'g'); 
    END IF;
    IF cost IS NOT NULL THEN 
        sql_expr := regexp_replace(sql_expr, '\mcost\M', cost::TEXT, 'g'); 
    END IF;
    IF visits IS NOT NULL THEN 
        sql_expr := regexp_replace(sql_expr, '\mvisits\M', visits::TEXT, 'g'); 
    END IF;
    IF conversions IS NOT NULL THEN 
        sql_expr := regexp_replace(sql_expr, '\mconversions\M', conversions::TEXT, 'g'); 
    END IF;
    IF clicks IS NOT NULL THEN 
        sql_expr := regexp_replace(sql_expr, '\mclicks\M', clicks::TEXT, 'g'); 
    END IF;
    IF impressions IS NOT NULL THEN 
        sql_expr := regexp_replace(sql_expr, '\mimpressions\M', impressions::TEXT, 'g'); 
    END IF;
    
    -- Execute calculation
    EXECUTE 'SELECT (' || sql_expr || ')::NUMERIC' INTO result;
    
    RETURN COALESCE(result, 0);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
$$;


ALTER FUNCTION public.calculate(formula text, revenue numeric, cost numeric, visits numeric, conversions numeric, clicks numeric, impressions numeric) OWNER TO postgres;

--
-- TOC entry 309 (class 1255 OID 16399)
-- Name: currency_calculator(character varying, character varying, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.currency_calculator(currency_from character varying, currency_to character varying, total_price numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
    DECLARE
      div_result numeric;
     currency_price_from numeric;
     currency_price_to numeric;
    begin
	    
	    select price into currency_price_from from currency_rates where currency_code = currency_from;
		
		
		RAISE NOTICE '::::::::::::::::::currency_price_from:: %', currency_price_from;
	    select price into currency_price_to from currency_rates where currency_code = currency_to;
		
		
		RAISE NOTICE ':::::::::::::::::::currency_price_to: %', currency_price_to;
		
	    select  (round((currency_price_to/currency_price_from), 2) + (case when currency_code = 'INR' then 0 else 1.5 end)) * total_price into div_result 
		from currency_rates where currency_code = currency_from;

      RETURN div_result;
    END;
$$;


ALTER FUNCTION public.currency_calculator(currency_from character varying, currency_to character varying, total_price numeric) OWNER TO postgres;

--
-- TOC entry 361 (class 1255 OID 25671)
-- Name: delete_product(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_product(p_product_lid integer, p_created_by integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
    $$;


ALTER FUNCTION public.delete_product(p_product_lid integer, p_created_by integer) OWNER TO postgres;

--
-- TOC entry 358 (class 1255 OID 25743)
-- Name: eval_formula(text, numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.eval_formula(formula text, var1 numeric DEFAULT 0, var2 numeric DEFAULT 0, var3 numeric DEFAULT 0, var4 numeric DEFAULT 0, var5 numeric DEFAULT 0) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
BEGIN
    sql_expr := formula;
    
    -- Simple fix: Cast everything to NUMERIC to ensure decimal division
    sql_expr := replace(sql_expr, 'a', var1::TEXT || '::NUMERIC');
    sql_expr := replace(sql_expr, 'b', var2::TEXT || '::NUMERIC');
    sql_expr := replace(sql_expr, 'c', var3::TEXT || '::NUMERIC');
    sql_expr := replace(sql_expr, 'd', var4::TEXT || '::NUMERIC');
    sql_expr := replace(sql_expr, 'e', var5::TEXT || '::NUMERIC');
    
    EXECUTE 'SELECT (' || sql_expr || ')::NUMERIC' INTO result;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
$$;


ALTER FUNCTION public.eval_formula(formula text, var1 numeric, var2 numeric, var3 numeric, var4 numeric, var5 numeric) OWNER TO postgres;

--
-- TOC entry 357 (class 1255 OID 25744)
-- Name: eval_formula_smart(text, numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.eval_formula_smart(formula text, var1 numeric DEFAULT 0, var2 numeric DEFAULT 0, var3 numeric DEFAULT 0, var4 numeric DEFAULT 0, var5 numeric DEFAULT 0) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
BEGIN
    sql_expr := formula;
    
    -- BEST FIX: Just cast to NUMERIC - works for both integers and decimals
    sql_expr := replace(sql_expr, 'a', '(' || var1::TEXT || ')::NUMERIC');
    sql_expr := replace(sql_expr, 'b', '(' || var2::TEXT || ')::NUMERIC');
    sql_expr := replace(sql_expr, 'c', '(' || var3::TEXT || ')::NUMERIC');
    sql_expr := replace(sql_expr, 'd', '(' || var4::TEXT || ')::NUMERIC');
    sql_expr := replace(sql_expr, 'e', '(' || var5::TEXT || ')::NUMERIC');
    
    EXECUTE 'SELECT (' || sql_expr || ')::NUMERIC' INTO result;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
$$;


ALTER FUNCTION public.eval_formula_smart(formula text, var1 numeric, var2 numeric, var3 numeric, var4 numeric, var5 numeric) OWNER TO postgres;

--
-- TOC entry 347 (class 1255 OID 17169)
-- Name: generate_receipt_number(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_receipt_number() RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.generate_receipt_number() OWNER TO postgres;

--
-- TOC entry 354 (class 1255 OID 25672)
-- Name: get_inventory_status_id(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_inventory_status_id(p_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE sid INT; BEGIN
  SELECT id INTO sid FROM inventory_status WHERE name = p_name AND active=TRUE LIMIT 1;
  IF sid IS NULL THEN RAISE EXCEPTION 'Missing inventory_status: %', p_name; END IF;
  RETURN sid;
END; $$;


ALTER FUNCTION public.get_inventory_status_id(p_name text) OWNER TO postgres;

--
-- TOC entry 355 (class 1255 OID 25673)
-- Name: get_mapping_label_id(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_mapping_label_id(p_name text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE lid INT; BEGIN
  SELECT id INTO lid FROM mapping_label WHERE name = p_name AND active=TRUE LIMIT 1;
  IF lid IS NULL THEN RAISE EXCEPTION 'Missing mapping_label: %', p_name; END IF;
  RETURN lid;
END; $$;


ALTER FUNCTION public.get_mapping_label_id(p_name text) OWNER TO postgres;

--
-- TOC entry 348 (class 1255 OID 17174)
-- Name: get_mapping_receipts(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_mapping_receipts() RETURNS TABLE(receipt_id integer, receipt_number character varying, company_name character varying, company_code character varying, total_products integer, mapping_date timestamp without time zone, notes text, products jsonb)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.get_mapping_receipts() OWNER TO postgres;

--
-- TOC entry 351 (class 1255 OID 17346)
-- Name: get_product_availability(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_product_availability(p_product_id integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  total_units INT; available_units INT; mapped_units INT; sold_units INT; mapped_list JSONB := '[]'::JSONB;
BEGIN
  SELECT COUNT(*) INTO total_units FROM inventory_unit WHERE product_lid=p_product_id;
  SELECT COUNT(*) INTO available_units FROM inventory_unit WHERE product_lid=p_product_id AND status='AVAILABLE';
  SELECT COUNT(*) INTO mapped_units FROM inventory_unit WHERE product_lid=p_product_id AND status='MAPPED';
  SELECT COUNT(*) INTO sold_units FROM inventory_unit WHERE product_lid=p_product_id AND status='SOLD';

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'company_name', c.name,
    'receipt_number', mr.receipt_number,
    'receipt_id', mr.id,
    'mapping_date', pcm.mapping_date,
    'label', l.name
  ) ORDER BY pcm.mapping_date DESC), '[]'::JSONB)
  INTO mapped_list
  FROM product_company_mapping pcm
  JOIN company c ON c.id = pcm.company_lid
  JOIN label l ON l.id = pcm.label_lid
  LEFT JOIN mapping_receipt mr ON mr.id = pcm.receipt_lid
  WHERE pcm.product_lid = p_product_id AND pcm.active = TRUE;

  RETURN jsonb_build_object('status','success','data', jsonb_build_object(
    'total_units', total_units,
    'mapped_units', mapped_units,
    'sold_units', sold_units,
    'available_units', available_units,
    'can_map_more', available_units > 0,
    'mapped_companies', mapped_list
  ));
END;
$$;


ALTER FUNCTION public.get_product_availability(p_product_id integer) OWNER TO postgres;

--
-- TOC entry 331 (class 1255 OID 16400)
-- Name: insert_carriers(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_carriers(new_carriers jsonb, createdby integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	createdBy := 1;
	
	DROP TABLE IF EXISTS temp_carrier;
	CREATE TEMP TABLE temp_carrier (
		carrier_name VARCHAR(255),
		mode_lid INT
	);
	
	INSERT INTO temp_carrier(carrier_name, mode_lid)
	SELECT
		carriers->>'carrierName' AS carrierName,
		(carriers->>'transportModeLid')::INT AS transportModeLid
	FROM
    jsonb_array_elements(new_carriers) AS carriers;

	IF EXISTS (SELECT 1 FROM temp_carrier tc
		INNER JOIN carrier c ON
		c.name = tc.carrier_name AND
		c.transport_mode_lid = tc.mode_lid
		WHERE c.active = true)
	THEN
		
		result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
		    
	ELSE
		result := '{"status": "success", "message": "Carriers inserted successfully!"}'::JSONB;
	END IF;

	
	-- TO BE INSERTED
  	INSERT INTO carrier(name, transport_mode_lid, created_by)
	SELECT tc.carrier_name, tc.mode_lid, createdBy FROM temp_carrier tc
	LEFT JOIN (SELECT * FROM carrier WHERE active = true) c ON 
	c.name = tc.carrier_name AND
	c.transport_mode_lid = tc.mode_lid
	WHERE c.id IS NULL;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.insert_carriers(new_carriers jsonb, createdby integer) OWNER TO postgres;

--
-- TOC entry 332 (class 1255 OID 16401)
-- Name: insert_cities(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_cities(newcities jsonb, createdby integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	createdBy := 1;
	
	DROP TABLE IF EXISTS temp_cities;
	CREATE TEMP TABLE temp_cities (
		city_name VARCHAR(255),
		country_lid INT,
		state_lid INT,
		postal_code VARCHAR(255)
	);
	
	INSERT INTO temp_cities(city_name, country_lid, state_lid, postal_code)
	SELECT
		city->>'city' AS city,
		(city->>'countryLid')::INT AS countryLid,
		(city->>'stateLid')::INT AS stateLid,
		city->>'postalCode' AS postalCode
	FROM
    jsonb_array_elements(newCities) AS city;
	
	IF EXISTS (SELECT * FROM temp_cities tc
	INNER JOIN city c ON
	c.country_lid = tc.country_lid AND
	c.state_lid = tc.state_lid AND
	c.postal_code = tc.postal_code
	WHERE c.active = true) 
	THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
	ELSE
		result := '{"status": "success", "message": "Cities inserted successfully!"}'::JSONB;
	END IF;
	
	-- TO BE INSERTED
  	INSERT INTO city(name, country_lid, state_lid, postal_code, created_by)
	SELECT tc.city_name, tc.country_lid, tc.state_lid, tc.postal_code, 1 FROM temp_cities tc
	LEFT JOIN (SELECT * FROM city WHERE active = true) c ON 
	c.country_lid = tc.country_lid AND
	c.state_lid = tc.state_lid AND
	c.postal_code = tc.postal_code
	WHERE c.id IS NULL;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.insert_cities(newcities jsonb, createdby integer) OWNER TO postgres;

--
-- TOC entry 356 (class 1255 OID 25740)
-- Name: insert_companies(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_companies(new_companies jsonb, var_created_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
    inserted_count INTEGER := 0;
    duplicate_count INTEGER := 0;
    company_record JSONB;
    comp_name VARCHAR(255);
    comp_code VARCHAR(100);
    comp_type VARCHAR(40);
BEGIN
    -- Initialize counters
    inserted_count := 0;
    duplicate_count := 0;
    
    -- Loop through each company in the JSONB array
    FOR company_record IN SELECT * FROM jsonb_array_elements(new_companies)
    LOOP
        -- Extract company data
        comp_name := company_record->>'name';
        comp_code := company_record->>'companyCode';
        comp_type := COALESCE(company_record->>'company_type', 'VENDOR');
        
        -- Validate required fields
        IF comp_name IS NULL OR comp_name = '' OR comp_code IS NULL OR comp_code = '' THEN
            CONTINUE; -- Skip invalid entries
        END IF;
        
        -- Check for duplicates
        IF EXISTS (
            SELECT 1 FROM company c
            WHERE (c.name = comp_name OR c.company_code = comp_code) 
            AND c.active = true
        ) THEN
            duplicate_count := duplicate_count + 1;
        ELSE
            -- Insert the company
            INSERT INTO company (
                name, 
                company_code, 
                company_type, 
                active, 
                created_at, 
                created_by
            ) VALUES (
                comp_name,
                comp_code,
                comp_type,
                true,
                CURRENT_TIMESTAMP,
                var_created_by
            );
            
            inserted_count := inserted_count + 1;
        END IF;
    END LOOP;
    
    -- Build result message
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
$$;


ALTER FUNCTION public.insert_companies(new_companies jsonb, var_created_by integer) OWNER TO postgres;

--
-- TOC entry 333 (class 1255 OID 16402)
-- Name: insert_currencies(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_currencies(newcurrency jsonb, createdby integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	createdBy := 1;
	
	DROP TABLE IF EXISTS temp_currencies;
	CREATE TEMP TABLE temp_currencies (
		currency_name VARCHAR(255),
		currency_symbol varchar(100),
		currency_code VARCHAR(100)
	);
	
	INSERT INTO temp_currencies(currency_name, currency_symbol, currency_code)
	SELECT
		currency->>'currencyName' AS name,
		currency->>'currencySymbol' AS symbol,
		currency->>'currencyCode' AS code
	FROM
    jsonb_array_elements(newCurrency) AS currency;
	
	
	IF EXISTS (SELECT * FROM temp_currencies tc
	INNER JOIN currency_type c ON
	c.name = tc.currency_name
	WHERE c.active = true) 
	THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
	ELSE
		result := '{"status": "success", "message": "Currencies inserted successfully!"}'::JSONB;
	END IF;
	
	-- TO BE INSERTED
  	INSERT INTO currency_type(name, symbol, code, created_by)
	SELECT tc.currency_name, tc.currency_symbol, tc.currency_code, 1 FROM temp_currencies tc
	LEFT JOIN (SELECT * FROM currency_type WHERE active = true) c ON 
	c.name = tc.currency_name 
	WHERE c.id IS NULL;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.insert_currencies(newcurrency jsonb, createdby integer) OWNER TO postgres;

--
-- TOC entry 334 (class 1255 OID 16403)
-- Name: insert_expense(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_expense(new_expenses jsonb, var_created_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	var_created_by := 1;
	
	DROP TABLE IF EXISTS temp_expenses;
	CREATE TEMP TABLE temp_expenses (
		name VARCHAR(255)
	);
	
	INSERT INTO temp_expenses(name)
	SELECT
		expense->>'expenseName'
	FROM
    jsonb_array_elements(new_expenses) AS expense;
	
	IF EXISTS (SELECT * FROM temp_expenses te
	INNER JOIN expenses e ON
	e.name = te.name
	WHERE e.active = true) 
	THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
	ELSE
		result := '{"status": "success", "message": "Data inserted successfully!"}'::JSONB;
	END IF;
	
	-- TO BE INSERTED
  	INSERT INTO expenses(name, created_by)
	SELECT te.name, var_created_by FROM temp_expenses te
	LEFT JOIN (SELECT * FROM expenses WHERE active = true) e ON 
	e.name = te.name
	WHERE e.id IS NULL;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.insert_expense(new_expenses jsonb, var_created_by integer) OWNER TO postgres;

--
-- TOC entry 335 (class 1255 OID 16404)
-- Name: insert_fare_class(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_fare_class(new_fare_class jsonb, createdby integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	createdBy := 1;
	
	DROP TABLE IF EXISTS temp_fare_class;
	CREATE TEMP TABLE temp_fare_class (
		fare_class_name VARCHAR(255),
		mode_lid INT
	);
	
	INSERT INTO temp_fare_class(fare_class_name, mode_lid)
	SELECT
		fare_class->>'fareClassName' AS carrierName,
		(fare_class->>'transportModeLid')::INT AS transportModeLid
	FROM
    jsonb_array_elements(new_fare_class) AS fare_class;

	IF EXISTS (SELECT 1 FROM temp_fare_class tc
		INNER JOIN fare_class c ON
		c.name = tc.fare_class_name AND
		c.transport_mode_lid = tc.mode_lid
		WHERE c.active = true)
	THEN
		
		result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
		    
	ELSE
		result := '{"status": "success", "message": "Fare class inserted successfully!"}'::JSONB;
	END IF;

	
	-- TO BE INSERTED
  	INSERT INTO fare_class(name, transport_mode_lid, created_by)
	SELECT tc.fare_class_name, tc.mode_lid, createdBy FROM temp_fare_class tc
	LEFT JOIN (SELECT * FROM fare_class WHERE active = true) c ON 
	c.name = tc.fare_class_name AND
	c.transport_mode_lid = tc.mode_lid
	WHERE c.id IS NULL;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END; 
$$;


ALTER FUNCTION public.insert_fare_class(new_fare_class jsonb, createdby integer) OWNER TO postgres;

--
-- TOC entry 336 (class 1255 OID 16405)
-- Name: insert_hotel(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_hotel(input_json jsonb, var_created_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	var_created_by := 1;
	
	DROP TABLE IF EXISTS temp_hotel;
	CREATE TEMP TABLE temp_hotel (
		id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
		name VARCHAR(255) NOT NULL,
		country_lid INT NOT NULL,
		state_lid INT NOT NULL,
		city_lid INT NOT NULL,
		room_types JSONB
	);
	
	INSERT INTO temp_hotel(name, country_lid, state_lid, city_lid, room_types)
	SELECT
		hotel->>'name',
		(hotel->>'country_lid')::INT,
		(hotel->>'state_lid')::INT,
		(hotel->>'city_lid')::INT,
		(hotel->>'room_types')::JSONB
	FROM
    jsonb_array_elements(input_json) AS hotel;
	
	DROP TABLE IF EXISTS inserted_hotels;
	CREATE TEMP TABLE inserted_hotels (
		hotel_lid INT NOT NULL,
		name VARCHAR(255) NOT NULL,
		country_lid INT NOT NULL,
		state_lid INT NOT NULL,
		city_lid INT NOT NULL
	);
	
	
	IF EXISTS (SELECT * FROM temp_hotel th
		INNER JOIN hotels h ON
		h.name = th.name AND
		h.country_lid = th.country_lid
		WHERE h.active = true) 
	THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
	ELSE
		result := '{"status": "success", "message": "Data inserted successfully!"}'::JSONB;
	END IF;
	

    WITH inserted_hotels_cte AS (
        INSERT INTO hotels(name, country_lid, state_lid, city_lid, created_by)
        SELECT th.name, th.country_lid, th.state_lid, th.city_lid, 1 FROM temp_hotel th
        LEFT JOIN hotels h ON 
            h.name = th.name AND
            h.country_lid = th.country_lid
        WHERE h.id IS NULL
        RETURNING id AS hotel_lid, name, country_lid, state_lid, city_lid
    )
    INSERT INTO inserted_hotels(hotel_lid, name, country_lid, state_lid, city_lid)
    SELECT hotel_lid, name, country_lid, state_lid, city_lid
    FROM inserted_hotels_cte;
	

	-- INSERT HOTEL ROOM TYPE
	INSERT INTO hotel_room_types(hotel_lid, room_type_lid, created_by)
	SELECT ih.hotel_lid, rte.value::INT AS room_type_lid, 1 FROM inserted_hotels ih
	INNER JOIN temp_hotel th ON 
	th.name = ih.name
	AND th.country_lid = ih.country_lid
	AND th.state_lid = ih.state_lid
	AND th.city_lid = ih.city_lid
	INNER JOIN LATERAL jsonb_array_elements(th.room_types) AS rte ON true;
	
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.insert_hotel(input_json jsonb, var_created_by integer) OWNER TO postgres;

--
-- TOC entry 337 (class 1255 OID 16406)
-- Name: insert_mode_of_transport(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_mode_of_transport(new_modes jsonb, createdby integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	createdBy := 1;
	
	DROP TABLE IF EXISTS temp_modes;
	CREATE TEMP TABLE temp_modes (
		mode_name VARCHAR(255)
	);
	
	INSERT INTO temp_modes(mode_name)
	SELECT
		transportMode->>'transportMode' AS transportMode
	FROM
    jsonb_array_elements(new_modes) AS transportMode;
	
	IF EXISTS (SELECT 1 FROM temp_modes tm
		INNER JOIN mode_of_transport mt ON
		mt.name = tm.mode_name
		WHERE mt.active = true)
	THEN
		IF EXISTS (SELECT CASE
        			WHEN (SELECT COUNT(*) FROM temp_modes) = (SELECT COUNT(*) FROM temp_modes tm
                                                  INNER JOIN mode_of_transport mt ON mt.name = tm.mode_name
                                                  WHERE mt.active = true)
        			THEN TRUE
        			ELSE FALSE
    				END)
		THEN
			result = '{"status": "success", "message": "Duplicate data Found."}'::JSONB;
		ELSE
			result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
		END IF;          

	ELSE
		result := '{"status": "success", "message": "Transport Mode inserted successfully!"}'::JSONB;
	END IF;

	
	-- TO BE INSERTED
  	INSERT INTO mode_of_transport(name, created_by)
	SELECT tm.mode_name, createdBy FROM temp_modes tm
	LEFT JOIN (SELECT * FROM mode_of_transport WHERE active = true) mt ON 
	mt.name = tm.mode_name
	WHERE mt.id IS NULL;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.insert_mode_of_transport(new_modes jsonb, createdby integer) OWNER TO postgres;

--
-- TOC entry 338 (class 1255 OID 16407)
-- Name: insert_pax_type(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_pax_type(input_json jsonb, var_created_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	var_created_by := 1;
	
	DROP TABLE IF EXISTS temp_pax_type;
	CREATE TEMP TABLE temp_pax_type (
		name VARCHAR(255)
	);
	
	INSERT INTO temp_pax_type(name)
	SELECT
		pax_type->>'paxType'
	FROM
    jsonb_array_elements(input_json) AS pax_type;
	
	IF EXISTS (SELECT * FROM temp_pax_type tpt
	INNER JOIN passenger_type pt ON
	pt.name = tpt.name
	WHERE pt.active = true) 
	THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
	ELSE
		result := '{"status": "success", "message": "Data inserted successfully!"}'::JSONB;
	END IF;
	
	-- TO BE INSERTED
  	INSERT INTO passenger_type(name, created_by)
	SELECT tpt.name, var_created_by FROM temp_pax_type tpt
	LEFT JOIN (SELECT * FROM passenger_type WHERE active = true) pt ON 
	pt.name = tpt.name
	WHERE pt.id IS NULL;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.insert_pax_type(input_json jsonb, var_created_by integer) OWNER TO postgres;

--
-- TOC entry 360 (class 1255 OID 25668)
-- Name: insert_products(jsonb, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_products(new_products jsonb, var_created_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
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
END; $$;


ALTER FUNCTION public.insert_products(new_products jsonb, var_created_by integer) OWNER TO postgres;

--
-- TOC entry 339 (class 1255 OID 16408)
-- Name: insert_tour_currency_rates(jsonb, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_tour_currency_rates(tourcurrencyrates jsonb, tourlid integer, createdby integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
    createdBy := 1;

    DROP TABLE IF EXISTS temp_tour_curr_rates;
    CREATE TEMP TABLE temp_tour_curr_rates (
       	currency_type_lid INT,
        currency_rate NUMERIC,
        price NUMERIC,
        actual_price NUMERIC,
        tour_lid INT
    );

    INSERT INTO temp_tour_curr_rates(currency_type_lid, currency_rate, price, actual_price, tour_lid)
    SELECT
        (curr_rate->>'currency_type_lid')::INT AS currency_type_lid,
        (curr_rate->>'currency_rate')::NUMERIC AS currency_rate,
        (curr_rate->>'price')::NUMERIC AS price,
        (curr_rate->>'actual_price')::NUMERIC AS actual_price,
        tourLid
    FROM
    jsonb_array_elements(tourCurrencyRates) AS curr_rate;
	
	IF EXISTS (SELECT * FROM temp_tour_curr_rates tc
	INNER JOIN tour_currency_rates t ON
	t.currency_type_lid = tc.currency_type_lid AND
	t.currency_rate = tc.currency_rate AND
	t.price = tc.price AND
	t.actual_price = tc.actual_price AND
	t.tour_lid = tc.tour_lid 		   
	WHERE t.active = true) 
	THEN
        result := '[{"status":"success","message":"Data inserted successfully except for the duplicate data."}]'::JSONB;
	ELSE
		result := '[{"status": "success", "message": "Currency Rates inserted successfully!"}]'::JSONB;
	END IF;

    -- TO BE INSERTED
    INSERT INTO tour_currency_rates(currency_type_lid, currency_rate, price, actual_price, tour_lid, created_by)
    SELECT tc.currency_type_lid, tc.currency_rate, tc.price, tc.actual_price, tc.tour_lid, 1 FROM temp_tour_curr_rates tc
	LEFT JOIN (SELECT * FROM tour_currency_rates WHERE active = true) t ON 
	t.currency_type_lid = tc.currency_type_lid AND
	t.currency_rate = tc.currency_rate AND
	t.price = tc.price AND
	t.actual_price = tc.actual_price AND
	t.tour_lid = tc.tour_lid
	WHERE t.id IS NULL;
  
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        result := '[{"status": "error", "message": "Something went wrong!"}]'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.insert_tour_currency_rates(tourcurrencyrates jsonb, tourlid integer, createdby integer) OWNER TO postgres;

--
-- TOC entry 340 (class 1255 OID 16409)
-- Name: insert_tour_expenses(json, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_tour_expenses(input_json json, username integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
	DECLARE
		i jsonb;
		output_result JSONB;
		result_json json;
		new_id integer;
	BEGIN

		DROP TABLE IF EXISTS temp_tour_expenses;
		CREATE TEMPORARY TABLE temp_tour_expenses (
			id int,
			expense_lid integer,
			expense_type varchar(255),
			remark TEXT,
			pax_lid integer,
			pax_type varchar(255),
			pax_count integer,
			currency_lid integer,
			currency varchar(255),
			unit_price numeric,
			nightly_recurring boolean,
			daily_recurring boolean,
			recurring_nights integer,
			recurring_days integer,
			total_price numeric
			); 
			-- Loop through array elements and insert into the table
			FOR i IN SELECT * FROM json_array_elements(input_json)
			LOOP
					-- Insert the row and capture the inserted id
					INSERT INTO tour_expenses (
							tour_lid, expense_lid, remark, pax_lid, pax_count, currency_lid,
							unit_price, nightly_recurring, daily_recurring, recurring_nights, recurring_days, total_price, created_by
					)
					VALUES (
							(i->>'TOUR_LID')::integer, (i->>'expenseLid')::integer, (i->>'remark')::text, (i->>'paxLid')::integer,
							(i->>'paxCount')::integer, (i->>'currencyLid')::integer,
							(i->>'unitPrice')::numeric, (i->>'nightlyRecurring')::boolean,
							(i->>'dailyRecurring')::boolean, (i->>'recurringNights')::integer, (i->>'recurringDays')::integer, CAST(i->>'totalPrice' as numeric),
							username
					)
			RETURNING id INTO new_id;
			
			INSERT INTO temp_tour_expenses (
				id, expense_lid, expense_type, remark, pax_lid, pax_type, pax_count,currency_lid, currency, unit_price,
				nightly_recurring, daily_recurring, recurring_nights, recurring_days, total_price
			)
			VALUES (
				new_id, (i->>'expenseLid')::integer, (i->>'expenseType')::varchar, (i->>'remark')::text,(i->>'paxLid')::integer,
				(i->>'paxType')::varchar, (i->>'paxCount')::integer, (i->>'currencyLid')::integer,
				(i->>'currency')::varchar, (i->>'unitPrice')::numeric, (i->>'nightlyRecurring')::boolean,
				(i->>'dailyRecurring')::boolean, (i->>'recurringNights')::integer, (i->>'recurringDays')::integer, CAST(i->>'totalPrice' as numeric)
			);	
			END LOOP;
		
			result_json:= (SELECT
				json_agg(json_build_object(
					'id', t.id,
					'expenseLid', t.expense_lid,
					'expenseType', t.expense_type,
					'remark', t.remark,
					'paxType', t.pax_type,
					'paxLid', t.pax_lid,
					'paxCount', t.pax_count,
					'currencyLid', t.currency_lid,
					'currency', t.currency,
					'unitPrice', t.unit_price,
					'nightlyRecurring', t.nightly_recurring,
					'dailyRecurring', t.daily_recurring,
					'recurringNights', t.recurring_nights,
					'recurringDays', t.recurring_days,
					'totalPrice', t.total_price
				))
		FROM temp_tour_expenses t);

		output_result := jsonb_build_object('status', 200, 'message', 'Successfully inserted', 'result', result_json); 

		RETURN output_result;
	END;
$$;


ALTER FUNCTION public.insert_tour_expenses(input_json json, username integer) OWNER TO postgres;

--
-- TOC entry 341 (class 1255 OID 16410)
-- Name: insert_update_margin(numeric, numeric, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_update_margin(_margin numeric, _tour_lid numeric, _created_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
    -- Check for duplicate tax names
    IF EXISTS (select * from tour_margin tm where tm.tour_lid = _tour_lid) then
    update tour_margin set margin  = _margin, updated_by  = _created_by, updated_at  = now() where tour_lid  = _tour_lid;
        result = '{"status": "success", "message": "Tour margin updated"}'::JSONB;
    ELSE
        insert into tour_margin(margin, tour_lid, created_by) values(_margin, _tour_lid, _created_by);
        result = jsonb_build_object('status', 'success', 'message', 'Tour margin inserted successfully');
    END IF;
   
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Handle exceptions or errors if needed
        result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.insert_update_margin(_margin numeric, _tour_lid numeric, _created_by integer) OWNER TO postgres;

--
-- TOC entry 350 (class 1255 OID 17345)
-- Name: record_product_sales(jsonb, integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.record_product_sales(p_items jsonb, p_company_lid integer, p_notes text, p_created_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  item RECORD; to_sell INT; sold INT := 0; errors TEXT[] := ARRAY[]::TEXT[];
  sold_label_id INT; m RECORD;
BEGIN
  SELECT id INTO sold_label_id FROM label WHERE name='SOLD' AND active=TRUE LIMIT 1;
  IF p_items IS NULL OR jsonb_typeof(p_items)!='array' OR jsonb_array_length(p_items)=0 THEN
    RETURN jsonb_build_object('status','error','message','No items to sell');
  END IF;

  FOR item IN SELECT (value->>'id')::INT AS product_id, GREATEST(1,COALESCE((value->>'qty')::INT,1)) AS qty FROM jsonb_array_elements(p_items) LOOP
    to_sell := item.qty;
    FOR m IN (
      SELECT pcm.id AS mapping_id, iu.id AS inv_id
      FROM product_company_mapping pcm
      JOIN inventory_unit iu ON iu.id=pcm.inventory_unit_lid
      JOIN label l ON l.id=pcm.label_lid
      WHERE pcm.active=TRUE AND pcm.company_lid=p_company_lid AND pcm.product_lid=item.product_id AND iu.status='MAPPED' AND l.name<>'SOLD'
      ORDER BY pcm.created_at ASC
    ) LOOP
      EXIT WHEN to_sell<=0;
      UPDATE product_company_mapping SET label_lid=sold_label_id, updated_at=NOW(), updated_by=p_created_by WHERE id=m.mapping_id;
      UPDATE inventory_unit SET status='SOLD', sold_at=NOW() WHERE id=m.inv_id;
      to_sell := to_sell - 1; sold := sold + 1;
    END LOOP;

    INSERT INTO product_sale(product_lid, company_lid, quantity, notes, created_by)
    VALUES(item.product_id, p_company_lid, (item.qty - GREATEST(to_sell,0)), p_notes, p_created_by);

    IF to_sell>0 THEN errors := array_append(errors, 'Insufficient units to sell '||to_sell||' of product '||item.product_id); END IF;
  END LOOP;

  RETURN jsonb_build_object('status', CASE WHEN array_length(errors,1) IS NULL THEN 'success' ELSE 'partial' END,
                            'message','Recorded sales for '||sold||' unit(s)','data', jsonb_build_object('sold_units',sold,'errors',errors));
END;
$$;


ALTER FUNCTION public.record_product_sales(p_items jsonb, p_company_lid integer, p_notes text, p_created_by integer) OWNER TO postgres;

--
-- TOC entry 342 (class 1255 OID 16411)
-- Name: tour_quotations(integer, numeric, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tour_quotations(_tour_lid integer, _tour_price_inr numeric, userid integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  _margin numeric;
  simple_tax numeric;
  compound_tax numeric;
  totalPrice numeric;
  estimation_without_fixed_pax numeric;
  estimation_for_complete_pax numeric;
  complete_payers INT;
  per_person_before numeric;
  totalPriceWithTax numeric;
    result JSONB;
BEGIN
  _margin:= (select margin from tour_margin where tour_lid = _tour_lid and active = true);
    
    RAISE NOTICE ':::::::::::::_margin %d', _margin; 
  
  simple_tax:= (COALESCE((select sum(tt.tax_percentage) from tour_taxes tt 
  join tax tx on tt.tax_lid = tx.id
  where tt.tour_lid = _tour_lid and compounding = '0' and tx.active= true and tt.active = true), 0));
    
    RAISE NOTICE ':::::::::::::simple_tax %d', simple_tax; 
  
  compound_tax:= (COALESCE((select sum(tt.tax_percentage) from tour_taxes tt 
          join tax tx on tt.tax_lid = tx.id
          where tt.tour_lid = _tour_lid and compounding = '1' 
          and tx.active= true and tt.active = true), 0));
    
    RAISE NOTICE ':::::::::::::compound_tax %d', compound_tax;
  
  totalPrice:=  (_tour_price_inr * (1 + (_margin/100)));
    
    RAISE NOTICE ':::::::::::::totalPrice %d', totalPrice;
    
    
    
    totalPriceWithTax:= (totalPrice*(1 + (simple_tax/100))*(1 + (compound_tax/100)));
    RAISE NOTICE ':::::::::::::totalPriceWithTax %d', totalPriceWithTax;
  
    
  estimation_without_fixed_pax :=   (select (totalPriceWithTax - COALESCE(sum(t.fixed), 0) )
            from (select  tp.payment_amount*tp.no_of_passengers as fixed
            from  tour_passengers tp WHERE tour_lid = _tour_lid and is_payable = true and active = true 
            and payment_percentage = 0 and payment_amount > 0) t);
  
    
      RAISE NOTICE ':::::::::::::estimation_without_fixed_pax %d', estimation_without_fixed_pax;
            

  per_person_before:= (estimation_without_fixed_pax/  (select  sum(tp.no_of_passengers) from  tour_passengers tp 
                             where tour_lid = _tour_lid 
                             and is_payable = true and payment_percentage > 0 and active = true));
    RAISE NOTICE '::::::::::::: per person before %d',per_person_before; 
            drop table if exists temp_percent_pax;
            create temporary table temp_percent_pax(
            id SERIAL,
            pax_type_lid INT,
            payment_percentage NUMERIC,
            per_person NUMERIC,
            no_of_pax INT,
            tax_cost numeric,
            total_without_tax numeric, 
            total_without_margin numeric,
            profit numeric
            );  
            INSERT INTO temp_percent_pax (pax_type_lid, payment_percentage, per_person, no_of_pax)
            select tp.pax_type_lid, tp.payment_percentage, (per_person_before*(tp.payment_percentage::numeric/100)), tp.no_of_passengers
            from  tour_passengers tp WHERE tour_lid = _tour_lid and is_payable = true and active = true and  
            (payment_percentage > 0 and payment_percentage < 100);
          
  estimation_for_complete_pax:= estimation_without_fixed_pax - (select COALESCE(sum(t.amount), 0) from
                                  (select (no_of_passengers*tpp.per_person) 
                                   as amount from tour_passengers tp 
                                join temp_percent_pax tpp on tp.pax_type_lid = tpp.pax_type_lid) t);
    
          RAISE NOTICE ':::::::::::::estimation_for_complete_pax %d', estimation_for_complete_pax;
  complete_payers:= (select sum(tp.no_of_passengers)
            from  tour_passengers tp WHERE tour_lid = _tour_lid and is_payable = true and active = true and
            payment_percentage = 100);  
    
      RAISE NOTICE ':::::::::::::complete_payers %d', complete_payers;
    RAISE NOTICE '::::::::::::: estimation_for_complete_pax/complete_payers %', estimation_for_complete_pax/complete_payers;
            
            INSERT INTO temp_percent_pax (pax_type_lid, payment_percentage, per_person, no_of_pax)
            select tp.pax_type_lid, tp.payment_percentage, estimation_for_complete_pax/complete_payers, tp.no_of_passengers
            from  tour_passengers tp WHERE tour_lid = _tour_lid and is_payable = true and active = true and
            payment_percentage = 100;
            
            INSERT INTO temp_percent_pax (pax_type_lid, payment_percentage, per_person, no_of_pax)
            select tp.pax_type_lid, tp.payment_percentage, tp.payment_amount, tp.no_of_passengers
            from  tour_passengers tp WHERE tour_lid = _tour_lid and is_payable = true and active = true and 
            payment_amount > 0;
--            RAISE NOTICE ':::::::::::::estimation_without_fixed_pax %d', estimation_without_fixed_pax;
            UPDATE temp_percent_pax SET 
            tax_cost  = (per_person - (per_person/((1 + (simple_tax/100))*( 1 + (compound_tax/100))))), 
            total_without_tax =  (per_person/((1 + (simple_tax/100))*( 1 + (compound_tax/100)))),
            total_without_margin = ((per_person/((1 + (simple_tax/100))*( 1 + (compound_tax/100))))::numeric/(1 + (_margin/100)));
            
            UPDATE temp_percent_pax SET profit =(total_without_tax - total_without_margin);
            DELETE FROM tour_pax_quote where tour_lid = _tour_lid;        
    
            INSERT INTO tour_pax_quote (tour_lid, pax_type_lid, payment_percentage, 
            per_person_quote, no_of_pax, tax_cost, total_without_tax, total_without_margin, profit, created_by)
            SELECT _tour_lid, tpp.pax_type_lid, tpp.payment_percentage, ROUND(tpp.per_person, 2), 
            tpp.no_of_pax, ROUND(tpp.tax_cost, 2), ROUND(tpp.total_without_tax, 2), ROUND(tpp.total_without_margin, 2),
            ROUND(tpp.profit, 2), userId 
            from temp_percent_pax tpp;
            
              result := (
                  SELECT json_agg(json_build_object(
                      'pax_id', p.id,
                      'name', p.name,
                      'per_person_quote', tpq.per_person_quote,
                      'no_of_pax', tpq.no_of_pax,
                      'tax_cost', tpq.tax_cost,
                      'total_without_tax', tpq.total_without_tax,
                      'margin', _margin,
                      'total_without_margin_tax', tpq.total_without_margin,
                      'profit', tpq.profit,
                      'totalProfit', tpq.profit * tpq.no_of_pax::numeric
                    ))
                    from tour_pax_quote tpq 
                    join passenger_type p on p.id = tpq.pax_type_lid
                    where p.active = true and tpq.active = true 
                      and tpq.tour_lid = _tour_lid
                  );
       -- Return the JSON array as a JSON object
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
           -- Handle exceptions or errors if needed
    result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.tour_quotations(_tour_lid integer, _tour_price_inr numeric, userid integer) OWNER TO postgres;

--
-- TOC entry 352 (class 1255 OID 17347)
-- Name: transfer_product_to_company(integer, integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.transfer_product_to_company(p_mapping_id integer, p_new_company_lid integer, p_notes text, p_updated_by integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
  inv_id INT; old_company INT; result JSONB;
BEGIN
  SELECT inventory_unit_lid, company_lid INTO inv_id, old_company FROM product_company_mapping WHERE id=p_mapping_id AND active=TRUE;
  IF inv_id IS NULL THEN RETURN jsonb_build_object('status','error','message','Mapping not found'); END IF;
  UPDATE product_company_mapping SET company_lid=p_new_company_lid, notes=COALESCE(p_notes, notes), updated_at=NOW(), updated_by=p_updated_by WHERE id=p_mapping_id;
  UPDATE inventory_unit SET current_company_lid=p_new_company_lid WHERE id=inv_id;
  RETURN jsonb_build_object('status','success','message','Transferred mapping to new company');
END;
$$;


ALTER FUNCTION public.transfer_product_to_company(p_mapping_id integer, p_new_company_lid integer, p_notes text, p_updated_by integer) OWNER TO postgres;

--
-- TOC entry 310 (class 1255 OID 16413)
-- Name: update_carrier(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_carrier(carrier_lid integer, new_carrier_name character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
	mode_lid INT;
BEGIN
	
	mode_lid := (SELECT transport_mode_lid FROM carrier WHERE id = carrier_lid);
    -- Check for duplicate mode names
    IF EXISTS (SELECT 1 FROM carrier WHERE name = new_carrier_name AND id != carrier_lid AND transport_mode_lid = mode_lid) THEN
        result = '{"status": "error", "message": "Duplicate carrier name."}'::JSONB;
	ELSE
		-- Update the city
		UPDATE carrier
		SET
			name = new_carrier_name
		WHERE id = carrier_lid;

		result = jsonb_build_object('status', 'success', 'message', 'Carrier updated');
	END IF;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Handle exceptions or errors if needed
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;

$$;


ALTER FUNCTION public.update_carrier(carrier_lid integer, new_carrier_name character varying) OWNER TO postgres;

--
-- TOC entry 311 (class 1255 OID 16414)
-- Name: update_city(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_city(city_id integer, new_city_name character varying, new_postal_code character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
	current_state_lid INT;
	current_country_lid INT;
BEGIN

	current_state_lid := (SELECT state_lid FROM city WHERE id = city_id);
	current_country_lid := (SELECT country_lid FROM city WHERE id = city_id);
	
    -- Check for duplicate city names
    IF EXISTS (SELECT 1 FROM city WHERE postal_code = new_postal_code AND country_lid = current_country_lid AND state_lid = current_state_lid AND id != city_id) THEN
        result = '{"status": "error", "message": "Duplicate city/postal code."}'::JSONB;
	ELSE
		-- Update the city
		UPDATE city
		SET
			name = new_city_name,
			postal_code = new_postal_code
		WHERE id = city_id;

		result = jsonb_build_object('status', 'success', 'message', 'City updated');
	END IF;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Handle exceptions or errors if needed
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.update_city(city_id integer, new_city_name character varying, new_postal_code character varying) OWNER TO postgres;

--
-- TOC entry 346 (class 1255 OID 16745)
-- Name: update_company(integer, character varying, character varying, character varying, character varying, character varying, character varying, integer, integer, integer, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_company(company_id integer, new_company_name character varying, new_company_code character varying, new_email character varying, new_phone character varying, new_address_line1 character varying, new_address_line2 character varying, new_country_lid integer, new_state_lid integer, new_city_lid integer, new_postal_code character varying, new_registration_number character varying, new_tax_number character varying, new_company_type character varying, new_website character varying, updated_by_user integer) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
    -- Check for duplicate company names or codes
    IF EXISTS (SELECT 1 FROM company 
               WHERE (name = new_company_name OR company_code = new_company_code) 
               AND id != company_id AND active = true) THEN
        result = '{"status": "error", "message": "Duplicate company name or code."}'::JSONB;
    ELSE
        -- Update the company
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
$$;


ALTER FUNCTION public.update_company(company_id integer, new_company_name character varying, new_company_code character varying, new_email character varying, new_phone character varying, new_address_line1 character varying, new_address_line2 character varying, new_country_lid integer, new_state_lid integer, new_city_lid integer, new_postal_code character varying, new_registration_number character varying, new_tax_number character varying, new_company_type character varying, new_website character varying, updated_by_user integer) OWNER TO postgres;

--
-- TOC entry 343 (class 1255 OID 16415)
-- Name: update_fare_class(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_fare_class(fare_class_lid integer, new_fare_class_name character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
	mode_lid INT;
BEGIN
	
	mode_lid := (SELECT transport_mode_lid FROM fare_class WHERE id = fare_class_lid);
    -- Check for duplicate mode names
    IF EXISTS (SELECT 1 FROM fare_class WHERE name = new_fare_class_name AND id != fare_class_lid AND transport_mode_lid = mode_lid) THEN
        result = '{"status": "error", "message": "Duplicate Fare Class name."}'::JSONB;
	ELSE
		-- Update the city
		UPDATE fare_class
		SET
			name = new_fare_class_name
		WHERE id = fare_class_lid;

		result = jsonb_build_object('status', 'success', 'message', 'Fare class updated');
	END IF;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Handle exceptions or errors if needed
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;

$$;


ALTER FUNCTION public.update_fare_class(fare_class_lid integer, new_fare_class_name character varying) OWNER TO postgres;

--
-- TOC entry 344 (class 1255 OID 16416)
-- Name: update_mode_of_transport(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_mode_of_transport(mode_lid integer, mode_name character varying) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	
    -- Check for duplicate mode names
    IF EXISTS (SELECT 1 FROM mode_of_transport WHERE name = mode_name AND id != mode_lid) THEN
        result = '{"status": "error", "message": "Duplicate transport mode."}'::JSONB;
	ELSE
		-- Update the city
		UPDATE mode_of_transport
		SET
			name = mode_name
		WHERE id = mode_lid;

		result = jsonb_build_object('status', 'success', 'message', 'Transport mode updated');
	END IF;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Handle exceptions or errors if needed
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.update_mode_of_transport(mode_lid integer, mode_name character varying) OWNER TO postgres;

--
-- TOC entry 345 (class 1255 OID 16417)
-- Name: update_tax(integer, character varying, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_tax(tax_id integer, new_tax_name character varying, new_percentage numeric) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
DECLARE
    result JSONB;
BEGIN
	
    -- Check for duplicate tax names
    IF EXISTS (SELECT 1 FROM tax WHERE name = new_tax_name AND id != tax_id) THEN
        result = '{"status": "error", "message": "Duplicate tax/percentage."}'::JSONB;
	ELSE
		-- Update the tax
		UPDATE tax SET name = new_tax_name, percentage = new_percentage WHERE id = tax_id;

		result = jsonb_build_object('status', 'success', 'message', 'tax updated');
	END IF;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Handle exceptions or errors if needed
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$;


ALTER FUNCTION public.update_tax(tax_id integer, new_tax_name character varying, new_percentage numeric) OWNER TO postgres;

--
-- TOC entry 349 (class 1255 OID 17193)
-- Name: validate_mapping_integrity(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_mapping_integrity() RETURNS TABLE(check_name text, status text, details text)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.validate_mapping_integrity() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 243 (class 1259 OID 16418)
-- Name: carrier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.carrier (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    transport_mode_lid integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.carrier OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 16423)
-- Name: carrier_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.carrier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.carrier_id_seq OWNER TO postgres;

--
-- TOC entry 4291 (class 0 OID 0)
-- Dependencies: 244
-- Name: carrier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.carrier_id_seq OWNED BY public.carrier.id;


--
-- TOC entry 245 (class 1259 OID 16424)
-- Name: city; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.city (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    country_lid integer NOT NULL,
    state_lid integer NOT NULL,
    postal_code character varying(100) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.city OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 16429)
-- Name: city_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.city_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.city_id_seq OWNER TO postgres;

--
-- TOC entry 4292 (class 0 OID 0)
-- Dependencies: 246
-- Name: city_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.city_id_seq OWNED BY public.city.id;


--
-- TOC entry 294 (class 1259 OID 25379)
-- Name: company; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.company (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    company_code character varying(100) NOT NULL,
    company_type character varying(40) DEFAULT 'VENDOR'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT company_company_type_check CHECK (((company_type)::text = ANY ((ARRAY['SELF'::character varying, 'VENDOR'::character varying])::text[])))
);


ALTER TABLE public.company OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 25378)
-- Name: company_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.company_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.company_id_seq OWNER TO postgres;

--
-- TOC entry 4293 (class 0 OID 0)
-- Dependencies: 293
-- Name: company_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.company_id_seq OWNED BY public.company.id;


--
-- TOC entry 290 (class 1259 OID 25329)
-- Name: company_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.company_type (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.company_type OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 25328)
-- Name: company_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.company_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.company_type_id_seq OWNER TO postgres;

--
-- TOC entry 4294 (class 0 OID 0)
-- Dependencies: 289
-- Name: company_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.company_type_id_seq OWNED BY public.company_type.id;


--
-- TOC entry 247 (class 1259 OID 16430)
-- Name: country; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.country (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    code character varying(100) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.country OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 16435)
-- Name: country_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.country_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.country_id_seq OWNER TO postgres;

--
-- TOC entry 4295 (class 0 OID 0)
-- Dependencies: 248
-- Name: country_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.country_id_seq OWNED BY public.country.id;


--
-- TOC entry 249 (class 1259 OID 16436)
-- Name: currency_rates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.currency_rates (
    currency_code character varying(25),
    price numeric NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.currency_rates OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 16443)
-- Name: currency_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.currency_rates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.currency_rates_id_seq OWNER TO postgres;

--
-- TOC entry 4296 (class 0 OID 0)
-- Dependencies: 250
-- Name: currency_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.currency_rates_id_seq OWNED BY public.currency_rates.id;


--
-- TOC entry 251 (class 1259 OID 16444)
-- Name: currency_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.currency_type (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    symbol character varying(255),
    symbol_native character varying(255),
    decimal_digits character varying(255),
    rounding character varying(255),
    code character varying(255),
    name_plural character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.currency_type OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 16451)
-- Name: currency_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.currency_type ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.currency_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 302 (class 1259 OID 25563)
-- Name: customer_order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_order (
    id integer NOT NULL,
    company_lid integer NOT NULL,
    order_number text NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.customer_order OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 25562)
-- Name: customer_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customer_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customer_order_id_seq OWNER TO postgres;

--
-- TOC entry 4297 (class 0 OID 0)
-- Dependencies: 301
-- Name: customer_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customer_order_id_seq OWNED BY public.customer_order.id;


--
-- TOC entry 304 (class 1259 OID 25615)
-- Name: customer_order_item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer_order_item (
    id integer NOT NULL,
    order_lid integer NOT NULL,
    product_lid integer NOT NULL,
    inventory_unit_lid integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.customer_order_item OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 25614)
-- Name: customer_order_item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customer_order_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customer_order_item_id_seq OWNER TO postgres;

--
-- TOC entry 4298 (class 0 OID 0)
-- Dependencies: 303
-- Name: customer_order_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customer_order_item_id_seq OWNED BY public.customer_order_item.id;


--
-- TOC entry 253 (class 1259 OID 16452)
-- Name: expenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expenses (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_by character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_by character varying(255),
    updated_at timestamp without time zone,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.expenses OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 16459)
-- Name: expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expenses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expenses_id_seq OWNER TO postgres;

--
-- TOC entry 4299 (class 0 OID 0)
-- Dependencies: 254
-- Name: expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expenses_id_seq OWNED BY public.expenses.id;


--
-- TOC entry 255 (class 1259 OID 16460)
-- Name: fare_class; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fare_class (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    transport_mode_lid integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.fare_class OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 16465)
-- Name: fare_class_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fare_class_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fare_class_id_seq OWNER TO postgres;

--
-- TOC entry 4300 (class 0 OID 0)
-- Dependencies: 256
-- Name: fare_class_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fare_class_id_seq OWNED BY public.fare_class.id;


--
-- TOC entry 306 (class 1259 OID 25640)
-- Name: inventory_company_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory_company_mapping (
    id integer NOT NULL,
    inventory_unit_lid integer NOT NULL,
    company_lid integer NOT NULL,
    label_lid integer NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.inventory_company_mapping OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 25639)
-- Name: inventory_company_mapping_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventory_company_mapping_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_company_mapping_id_seq OWNER TO postgres;

--
-- TOC entry 4301 (class 0 OID 0)
-- Dependencies: 305
-- Name: inventory_company_mapping_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventory_company_mapping_id_seq OWNED BY public.inventory_company_mapping.id;


--
-- TOC entry 298 (class 1259 OID 25407)
-- Name: inventory_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory_status (
    id integer NOT NULL,
    name character varying(40) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.inventory_status OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 25406)
-- Name: inventory_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventory_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_status_id_seq OWNER TO postgres;

--
-- TOC entry 4302 (class 0 OID 0)
-- Dependencies: 297
-- Name: inventory_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventory_status_id_seq OWNED BY public.inventory_status.id;


--
-- TOC entry 300 (class 1259 OID 25421)
-- Name: inventory_unit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory_unit (
    id integer NOT NULL,
    product_lid integer NOT NULL,
    status_lid integer NOT NULL,
    current_company_lid integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.inventory_unit OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 25420)
-- Name: inventory_unit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventory_unit_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_unit_id_seq OWNER TO postgres;

--
-- TOC entry 4303 (class 0 OID 0)
-- Dependencies: 299
-- Name: inventory_unit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventory_unit_id_seq OWNED BY public.inventory_unit.id;


--
-- TOC entry 292 (class 1259 OID 25340)
-- Name: mapping_label; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mapping_label (
    id integer NOT NULL,
    name character varying(40) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.mapping_label OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 25339)
-- Name: mapping_label_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mapping_label_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mapping_label_id_seq OWNER TO postgres;

--
-- TOC entry 4304 (class 0 OID 0)
-- Dependencies: 291
-- Name: mapping_label_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mapping_label_id_seq OWNED BY public.mapping_label.id;


--
-- TOC entry 286 (class 1259 OID 17146)
-- Name: mapping_receipt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mapping_receipt (
    id integer NOT NULL,
    receipt_number character varying(20) NOT NULL,
    company_lid integer NOT NULL,
    total_products integer DEFAULT 0 NOT NULL,
    mapping_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    notes text,
    created_by integer NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.mapping_receipt OWNER TO postgres;

--
-- TOC entry 4305 (class 0 OID 0)
-- Dependencies: 286
-- Name: TABLE mapping_receipt; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.mapping_receipt IS 'Tracks bulk mapping receipts with unique numbers';


--
-- TOC entry 285 (class 1259 OID 17145)
-- Name: mapping_receipt_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mapping_receipt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mapping_receipt_id_seq OWNER TO postgres;

--
-- TOC entry 4306 (class 0 OID 0)
-- Dependencies: 285
-- Name: mapping_receipt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mapping_receipt_id_seq OWNED BY public.mapping_receipt.id;


--
-- TOC entry 257 (class 1259 OID 16466)
-- Name: mode_of_transport; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mode_of_transport (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.mode_of_transport OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 16471)
-- Name: mode_of_transport_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mode_of_transport_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mode_of_transport_id_seq OWNER TO postgres;

--
-- TOC entry 4307 (class 0 OID 0)
-- Dependencies: 258
-- Name: mode_of_transport_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mode_of_transport_id_seq OWNED BY public.mode_of_transport.id;


--
-- TOC entry 259 (class 1259 OID 16472)
-- Name: passenger_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.passenger_type (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.passenger_type OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 16477)
-- Name: passenger_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.passenger_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.passenger_type_id_seq OWNER TO postgres;

--
-- TOC entry 4308 (class 0 OID 0)
-- Dependencies: 260
-- Name: passenger_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.passenger_type_id_seq OWNED BY public.passenger_type.id;


--
-- TOC entry 296 (class 1259 OID 25394)
-- Name: product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    product_code character varying(100) NOT NULL,
    description text,
    category character varying(120),
    price numeric(12,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    active boolean DEFAULT true NOT NULL,
    specifications text
);


ALTER TABLE public.product OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 25393)
-- Name: product_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_id_seq OWNER TO postgres;

--
-- TOC entry 4309 (class 0 OID 0)
-- Dependencies: 295
-- Name: product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_id_seq OWNED BY public.product.id;


--
-- TOC entry 288 (class 1259 OID 17223)
-- Name: product_sale; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_sale (
    id integer NOT NULL,
    product_lid integer NOT NULL,
    company_lid integer NOT NULL,
    quantity integer NOT NULL,
    sale_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    notes text,
    receipt_lid integer,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT product_sale_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.product_sale OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 17222)
-- Name: product_sale_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_sale_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_sale_id_seq OWNER TO postgres;

--
-- TOC entry 4310 (class 0 OID 0)
-- Dependencies: 287
-- Name: product_sale_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_sale_id_seq OWNED BY public.product_sale.id;


--
-- TOC entry 261 (class 1259 OID 16478)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 16483)
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO postgres;

--
-- TOC entry 4311 (class 0 OID 0)
-- Dependencies: 262
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- TOC entry 308 (class 1259 OID 25746)
-- Name: sample_table; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sample_table (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    category character varying(50),
    count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sample_table OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 25745)
-- Name: sample_table_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sample_table_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sample_table_id_seq OWNER TO postgres;

--
-- TOC entry 4312 (class 0 OID 0)
-- Dependencies: 307
-- Name: sample_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sample_table_id_seq OWNED BY public.sample_table.id;


--
-- TOC entry 263 (class 1259 OID 16484)
-- Name: state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.state (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    country_lid integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    created_by character varying(255) NOT NULL,
    updated_by character varying(255),
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.state OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 16491)
-- Name: state_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.state_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.state_id_seq OWNER TO postgres;

--
-- TOC entry 4313 (class 0 OID 0)
-- Dependencies: 264
-- Name: state_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.state_id_seq OWNED BY public.state.id;


--
-- TOC entry 265 (class 1259 OID 16492)
-- Name: tax; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tax (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    percentage numeric NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL,
    compounding bit(1) DEFAULT '0'::"bit"
);


ALTER TABLE public.tax OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 16500)
-- Name: tax_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tax ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tax_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 267 (class 1259 OID 16501)
-- Name: tour; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tour (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    duration_days integer NOT NULL,
    duration_nights integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL,
    sealed bit(1) DEFAULT '0'::"bit" NOT NULL
);


ALTER TABLE public.tour OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 16508)
-- Name: tour_currency_rates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tour_currency_rates (
    id integer NOT NULL,
    currency_type_lid integer NOT NULL,
    currency_rate numeric NOT NULL,
    price numeric NOT NULL,
    actual_price numeric NOT NULL,
    tour_lid integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.tour_currency_rates OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 16515)
-- Name: tour_currency_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tour_currency_rates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tour_currency_rates_id_seq OWNER TO postgres;

--
-- TOC entry 4314 (class 0 OID 0)
-- Dependencies: 269
-- Name: tour_currency_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tour_currency_rates_id_seq OWNED BY public.tour_currency_rates.id;


--
-- TOC entry 270 (class 1259 OID 16516)
-- Name: tour_expenses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tour_expenses (
    id integer NOT NULL,
    tour_lid integer NOT NULL,
    expense_lid integer NOT NULL,
    pax_lid integer NOT NULL,
    pax_count integer,
    currency_lid integer,
    unit_price numeric,
    nightly_recurring boolean,
    daily_recurring boolean,
    total_price numeric,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL,
    remark text,
    recurring_nights integer,
    recurring_days integer
);


ALTER TABLE public.tour_expenses OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 16523)
-- Name: tour_expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tour_expenses ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tour_expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 272 (class 1259 OID 16524)
-- Name: tour_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tour_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tour_id_seq OWNER TO postgres;

--
-- TOC entry 4315 (class 0 OID 0)
-- Dependencies: 272
-- Name: tour_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tour_id_seq OWNED BY public.tour.id;


--
-- TOC entry 273 (class 1259 OID 16525)
-- Name: tour_margin; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tour_margin (
    id integer NOT NULL,
    tour_lid integer,
    margin numeric NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.tour_margin OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 16532)
-- Name: tour_margin_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tour_margin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tour_margin_id_seq OWNER TO postgres;

--
-- TOC entry 4316 (class 0 OID 0)
-- Dependencies: 274
-- Name: tour_margin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tour_margin_id_seq OWNED BY public.tour_margin.id;


--
-- TOC entry 275 (class 1259 OID 16533)
-- Name: tour_passengers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tour_passengers (
    id integer NOT NULL,
    tour_lid integer,
    pax_type_lid integer,
    no_of_passengers integer NOT NULL,
    is_payable boolean NOT NULL,
    payment_percentage integer,
    payment_amount numeric,
    occupancy_preference integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.tour_passengers OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 16540)
-- Name: tour_passengers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tour_passengers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tour_passengers_id_seq OWNER TO postgres;

--
-- TOC entry 4317 (class 0 OID 0)
-- Dependencies: 276
-- Name: tour_passengers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tour_passengers_id_seq OWNED BY public.tour_passengers.id;


--
-- TOC entry 277 (class 1259 OID 16541)
-- Name: tour_pax_quote; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tour_pax_quote (
    id integer NOT NULL,
    tour_lid integer,
    pax_type_lid integer,
    payment_percentage integer,
    per_person_quote numeric,
    no_of_pax integer,
    tax_cost numeric,
    total_without_tax numeric,
    total_without_margin numeric,
    profit numeric,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.tour_pax_quote OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 16548)
-- Name: tour_pax_quote_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tour_pax_quote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tour_pax_quote_id_seq OWNER TO postgres;

--
-- TOC entry 4318 (class 0 OID 0)
-- Dependencies: 278
-- Name: tour_pax_quote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tour_pax_quote_id_seq OWNED BY public.tour_pax_quote.id;


--
-- TOC entry 279 (class 1259 OID 16549)
-- Name: tour_taxes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tour_taxes (
    id integer NOT NULL,
    tour_lid integer,
    tax_lid integer,
    tax_percentage numeric NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.tour_taxes OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 16556)
-- Name: tour_taxes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tour_taxes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tour_taxes_id_seq OWNER TO postgres;

--
-- TOC entry 4319 (class 0 OID 0)
-- Dependencies: 280
-- Name: tour_taxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tour_taxes_id_seq OWNED BY public.tour_taxes.id;


--
-- TOC entry 281 (class 1259 OID 16557)
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    user_id integer,
    role_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 16562)
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_roles_id_seq OWNER TO postgres;

--
-- TOC entry 4320 (class 0 OID 0)
-- Dependencies: 282
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- TOC entry 283 (class 1259 OID 16563)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    firstname character varying(255) NOT NULL,
    lastname character varying(255),
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 16570)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 3855 (class 2604 OID 16571)
-- Name: carrier id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrier ALTER COLUMN id SET DEFAULT nextval('public.carrier_id_seq'::regclass);


--
-- TOC entry 3858 (class 2604 OID 16572)
-- Name: city id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.city ALTER COLUMN id SET DEFAULT nextval('public.city_id_seq'::regclass);


--
-- TOC entry 3931 (class 2604 OID 25382)
-- Name: company id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company ALTER COLUMN id SET DEFAULT nextval('public.company_id_seq'::regclass);


--
-- TOC entry 3925 (class 2604 OID 25332)
-- Name: company_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_type ALTER COLUMN id SET DEFAULT nextval('public.company_type_id_seq'::regclass);


--
-- TOC entry 3861 (class 2604 OID 16573)
-- Name: country id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country ALTER COLUMN id SET DEFAULT nextval('public.country_id_seq'::regclass);


--
-- TOC entry 3866 (class 2604 OID 16574)
-- Name: currency_rates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currency_rates ALTER COLUMN id SET DEFAULT nextval('public.currency_rates_id_seq'::regclass);


--
-- TOC entry 3944 (class 2604 OID 25566)
-- Name: customer_order id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order ALTER COLUMN id SET DEFAULT nextval('public.customer_order_id_seq'::regclass);


--
-- TOC entry 3947 (class 2604 OID 25618)
-- Name: customer_order_item id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order_item ALTER COLUMN id SET DEFAULT nextval('public.customer_order_item_id_seq'::regclass);


--
-- TOC entry 3869 (class 2604 OID 16575)
-- Name: expenses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses ALTER COLUMN id SET DEFAULT nextval('public.expenses_id_seq'::regclass);


--
-- TOC entry 3872 (class 2604 OID 16576)
-- Name: fare_class id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fare_class ALTER COLUMN id SET DEFAULT nextval('public.fare_class_id_seq'::regclass);


--
-- TOC entry 3950 (class 2604 OID 25643)
-- Name: inventory_company_mapping id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_company_mapping ALTER COLUMN id SET DEFAULT nextval('public.inventory_company_mapping_id_seq'::regclass);


--
-- TOC entry 3938 (class 2604 OID 25410)
-- Name: inventory_status id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_status ALTER COLUMN id SET DEFAULT nextval('public.inventory_status_id_seq'::regclass);


--
-- TOC entry 3941 (class 2604 OID 25424)
-- Name: inventory_unit id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_unit ALTER COLUMN id SET DEFAULT nextval('public.inventory_unit_id_seq'::regclass);


--
-- TOC entry 3928 (class 2604 OID 25343)
-- Name: mapping_label id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_label ALTER COLUMN id SET DEFAULT nextval('public.mapping_label_id_seq'::regclass);


--
-- TOC entry 3917 (class 2604 OID 17149)
-- Name: mapping_receipt id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_receipt ALTER COLUMN id SET DEFAULT nextval('public.mapping_receipt_id_seq'::regclass);


--
-- TOC entry 3875 (class 2604 OID 16577)
-- Name: mode_of_transport id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mode_of_transport ALTER COLUMN id SET DEFAULT nextval('public.mode_of_transport_id_seq'::regclass);


--
-- TOC entry 3878 (class 2604 OID 16578)
-- Name: passenger_type id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passenger_type ALTER COLUMN id SET DEFAULT nextval('public.passenger_type_id_seq'::regclass);


--
-- TOC entry 3935 (class 2604 OID 25397)
-- Name: product id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product ALTER COLUMN id SET DEFAULT nextval('public.product_id_seq'::regclass);


--
-- TOC entry 3921 (class 2604 OID 17226)
-- Name: product_sale id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_sale ALTER COLUMN id SET DEFAULT nextval('public.product_sale_id_seq'::regclass);


--
-- TOC entry 3881 (class 2604 OID 16579)
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- TOC entry 3953 (class 2604 OID 25749)
-- Name: sample_table id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sample_table ALTER COLUMN id SET DEFAULT nextval('public.sample_table_id_seq'::regclass);


--
-- TOC entry 3884 (class 2604 OID 16580)
-- Name: state id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.state ALTER COLUMN id SET DEFAULT nextval('public.state_id_seq'::regclass);


--
-- TOC entry 3890 (class 2604 OID 16581)
-- Name: tour id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour ALTER COLUMN id SET DEFAULT nextval('public.tour_id_seq'::regclass);


--
-- TOC entry 3895 (class 2604 OID 16582)
-- Name: tour_currency_rates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_currency_rates ALTER COLUMN id SET DEFAULT nextval('public.tour_currency_rates_id_seq'::regclass);


--
-- TOC entry 3900 (class 2604 OID 16583)
-- Name: tour_margin id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_margin ALTER COLUMN id SET DEFAULT nextval('public.tour_margin_id_seq'::regclass);


--
-- TOC entry 3903 (class 2604 OID 16584)
-- Name: tour_passengers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_passengers ALTER COLUMN id SET DEFAULT nextval('public.tour_passengers_id_seq'::regclass);


--
-- TOC entry 3906 (class 2604 OID 16585)
-- Name: tour_pax_quote id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_pax_quote ALTER COLUMN id SET DEFAULT nextval('public.tour_pax_quote_id_seq'::regclass);


--
-- TOC entry 3909 (class 2604 OID 16586)
-- Name: tour_taxes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_taxes ALTER COLUMN id SET DEFAULT nextval('public.tour_taxes_id_seq'::regclass);


--
-- TOC entry 3912 (class 2604 OID 16587)
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- TOC entry 4220 (class 0 OID 16418)
-- Dependencies: 243
-- Data for Name: carrier; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.carrier (id, name, transport_mode_lid, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	INDIGO	2	2023-08-31 11:01:23.998048+05:30	\N	1	\N	t
\.


--
-- TOC entry 4222 (class 0 OID 16424)
-- Dependencies: 245
-- Data for Name: city; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.city (id, name, country_lid, state_lid, postal_code, created_at, updated_at, created_by, updated_by, active) FROM stdin;
2	Navi Mumbai	2	1	410206	2023-08-31 10:14:35.452569	\N	1	\N	f
3	Navi Mumbai	2	1	410206	2023-08-31 10:14:48.670191	\N	1	\N	f
1	Ulwe	2	1	4102064	2023-08-31 10:05:49.785543	\N	1	\N	f
4	Navi Mumbai	2	1	410206	2023-08-31 10:15:08.892631	\N	1	\N	f
5	Imphal New	2	1	795001	2023-08-31 10:18:37.134983	\N	1	\N	f
6	Navi Mumbai	2	1	410206	2023-08-31 10:18:42.295429	\N	1	\N	f
7	Imphal new	2	1	7950014	2023-08-31 10:20:18.683083	\N	1	\N	t
8	Hyderabad	2	1	425452	2023-08-31 10:24:14.145838	\N	1	\N	t
\.


--
-- TOC entry 4271 (class 0 OID 25379)
-- Dependencies: 294
-- Data for Name: company; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.company (id, name, company_code, company_type, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	JEAN FENDI	SELF	SELF	2025-08-24 01:36:17.147313	\N	1	\N	t
2	Premium Watch Boutique	PWB001	VENDOR	2025-08-24 19:20:09.65235	\N	1	\N	t
3	Luxury Timepieces Pvt Ltd	LTP002	VENDOR	2025-08-24 19:20:09.65235	\N	1	\N	t
4	Watch World Express	WWE003	VENDOR	2025-08-24 19:20:09.65235	\N	1	\N	t
6	Timekeeper Distributors	TKD005	VENDOR	2025-08-24 19:20:09.65235	\N	1	\N	t
7	Royal Watch House	RWH006	VENDOR	2025-08-24 19:20:09.65235	\N	1	\N	t
8	Metro Watch Mart	MWM007	VENDOR	2025-08-24 19:20:09.65235	\N	1	\N	t
9	Vintage Timepiece Co.	VTC008	VENDOR	2025-08-24 19:20:09.65235	\N	1	\N	t
5	Elite Watch Gallery	EWG004	VENDOR	2025-08-24 19:20:09.65235	2025-08-24 19:30:00.245284	1	1	t
13	Owais Company	OW1	VENDOR	2025-08-24 19:30:21.984978	\N	1	\N	t
17	Arif Co.	AC1	VENDOR	2025-09-14 17:49:48.656395	\N	1	\N	t
\.


--
-- TOC entry 4267 (class 0 OID 25329)
-- Dependencies: 290
-- Data for Name: company_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.company_type (id, name, description, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	SELF	Self-owned company (main company)	2025-08-24 19:24:30.728437	\N	1	\N	t
2	VENDOR	External vendor/supplier company	2025-08-24 19:24:30.728437	\N	1	\N	t
\.


--
-- TOC entry 4224 (class 0 OID 16430)
-- Dependencies: 247
-- Data for Name: country; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.country (id, name, code, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	Gabon	GA	2023-09-11 01:01:08.627873	\N	1	\N	t
2	Norfolk Island	NF	2023-09-11 01:01:08.627873	\N	1	\N	t
3	Mauritania	MR	2023-09-11 01:01:08.627873	\N	1	\N	t
4	Aruba	AW	2023-09-11 01:01:08.627873	\N	1	\N	t
5	Finland	FI	2023-09-11 01:01:08.627873	\N	1	\N	t
6	Armenia	AM	2023-09-11 01:01:08.627873	\N	1	\N	t
7	Malta	MT	2023-09-11 01:01:08.627873	\N	1	\N	t
8	Belgium	BE	2023-09-11 01:01:08.627873	\N	1	\N	t
9	Sweden	SE	2023-09-11 01:01:08.627873	\N	1	\N	t
10	Iran, Islamic Republic Of	IR	2023-09-11 01:01:08.627873	\N	1	\N	t
11	Eritrea	ER	2023-09-11 01:01:08.627873	\N	1	\N	t
12	Jordan	JO	2023-09-11 01:01:08.627873	\N	1	\N	t
13	Iraq	IQ	2023-09-11 01:01:08.627873	\N	1	\N	t
14	Angola	AO	2023-09-11 01:01:08.627873	\N	1	\N	t
15	Western Sahara	EH	2023-09-11 01:01:08.627873	\N	1	\N	t
16	Saint Lucia	LC	2023-09-11 01:01:08.627873	\N	1	\N	t
17	Qatar	QA	2023-09-11 01:01:08.627873	\N	1	\N	t
18	Syrian Arab Republic	SY	2023-09-11 01:01:08.627873	\N	1	\N	t
19	Romania	RO	2023-09-11 01:01:08.627873	\N	1	\N	t
20	Burundi	BI	2023-09-11 01:01:08.627873	\N	1	\N	t
21	Bermuda	BM	2023-09-11 01:01:08.627873	\N	1	\N	t
22	Tanzania, United Republic of	TZ	2023-09-11 01:01:08.627873	\N	1	\N	t
23	Djibouti	DJ	2023-09-11 01:01:08.627873	\N	1	\N	t
24	Monaco	MC	2023-09-11 01:01:08.627873	\N	1	\N	t
25	Slovakia	SK	2023-09-11 01:01:08.627873	\N	1	\N	t
26	Oman	OM	2023-09-11 01:01:08.627873	\N	1	\N	t
27	Liechtenstein	LI	2023-09-11 01:01:08.627873	\N	1	\N	t
28	Saint Helena	SH	2023-09-11 01:01:08.627873	\N	1	\N	t
29	Samoa	WS	2023-09-11 01:01:08.627873	\N	1	\N	t
30	Slovenia	SI	2023-09-11 01:01:08.627873	\N	1	\N	t
31	Pakistan	PK	2023-09-11 01:01:08.627873	\N	1	\N	t
32	Canada	CA	2023-09-11 01:01:08.627873	\N	1	\N	t
33	Afghanistan	AF	2023-09-11 01:01:08.627873	\N	1	\N	t
34	French Polynesia	PF	2023-09-11 01:01:08.627873	\N	1	\N	t
35	United States Minor Outlying Islands	UM	2023-09-11 01:01:08.627873	\N	1	\N	t
36	United States	US	2023-09-11 01:01:08.627873	\N	1	\N	t
37	Taiwan, Province of China	TW	2023-09-11 01:01:08.627873	\N	1	\N	t
38	United Arab Emirates	AE	2023-09-11 01:01:08.627873	\N	1	\N	t
39	Timor-Leste	TL	2023-09-11 01:01:08.627873	\N	1	\N	t
40	Vanuatu	VU	2023-09-11 01:01:08.627873	\N	1	\N	t
41	Luxembourg	LU	2023-09-11 01:01:08.627873	\N	1	\N	t
42	Czech Republic	CZ	2023-09-11 01:01:08.627873	\N	1	\N	t
43	Cook Islands	CK	2023-09-11 01:01:08.627873	\N	1	\N	t
44	Falkland Islands (Malvinas)	FK	2023-09-11 01:01:08.627873	\N	1	\N	t
45	British Indian Ocean Territory	IO	2023-09-11 01:01:08.627873	\N	1	\N	t
46	Norway	NO	2023-09-11 01:01:08.627873	\N	1	\N	t
47	Cocos (Keeling) Islands	CC	2023-09-11 01:01:08.627873	\N	1	\N	t
48	Korea, Republic of	KR	2023-09-11 01:01:08.627873	\N	1	\N	t
49	Botswana	BW	2023-09-11 01:01:08.627873	\N	1	\N	t
50	Bahamas	BS	2023-09-11 01:01:08.627873	\N	1	\N	t
51	Madagascar	MG	2023-09-11 01:01:08.627873	\N	1	\N	t
52	Saint Pierre and Miquelon	PM	2023-09-11 01:01:08.627873	\N	1	\N	t
53	French Southern Territories	TF	2023-09-11 01:01:08.627873	\N	1	\N	t
54	Cuba	CU	2023-09-11 01:01:08.627873	\N	1	\N	t
55	Central African Republic	CF	2023-09-11 01:01:08.627873	\N	1	\N	t
56	Greenland	GL	2023-09-11 01:01:08.627873	\N	1	\N	t
57	Denmark	DK	2023-09-11 01:01:08.627873	\N	1	\N	t
58	Ukraine	UA	2023-09-11 01:01:08.627873	\N	1	\N	t
59	Benin	BJ	2023-09-11 01:01:08.627873	\N	1	\N	t
60	Chile	CL	2023-09-11 01:01:08.627873	\N	1	\N	t
61	Belarus	BY	2023-09-11 01:01:08.627873	\N	1	\N	t
62	Thailand	TH	2023-09-11 01:01:08.627873	\N	1	\N	t
63	Congo, The Democratic Republic of the	CD	2023-09-11 01:01:08.627873	\N	1	\N	t
64	Mauritius	MU	2023-09-11 01:01:08.627873	\N	1	\N	t
65	Argentina	AR	2023-09-11 01:01:08.627873	\N	1	\N	t
66	Spain	ES	2023-09-11 01:01:08.627873	\N	1	\N	t
67	Bosnia and Herzegovina	BA	2023-09-11 01:01:08.627873	\N	1	\N	t
68	Poland	PL	2023-09-11 01:01:08.627873	\N	1	\N	t
69	Guinea	GN	2023-09-11 01:01:08.627873	\N	1	\N	t
70	Kyrgyzstan	KG	2023-09-11 01:01:08.627873	\N	1	\N	t
71	Holy See (Vatican City State)	VA	2023-09-11 01:01:08.627873	\N	1	\N	t
72	Brazil	BR	2023-09-11 01:01:08.627873	\N	1	\N	t
73	Lebanon	LB	2023-09-11 01:01:08.627873	\N	1	\N	t
74	Guatemala	GT	2023-09-11 01:01:08.627873	\N	1	\N	t
75	Virgin Islands, U.S.	VI	2023-09-11 01:01:08.627873	\N	1	\N	t
76	Maldives	MV	2023-09-11 01:01:08.627873	\N	1	\N	t
77	American Samoa	AS	2023-09-11 01:01:08.627873	\N	1	\N	t
78	Serbia and Montenegro	CS	2023-09-11 01:01:08.627873	\N	1	\N	t
79	Turks and Caicos Islands	TC	2023-09-11 01:01:08.627873	\N	1	\N	t
80	Comoros	KM	2023-09-11 01:01:08.627873	\N	1	\N	t
81	Somalia	SO	2023-09-11 01:01:08.627873	\N	1	\N	t
82	Germany	DE	2023-09-11 01:01:08.627873	\N	1	\N	t
83	Lesotho	LS	2023-09-11 01:01:08.627873	\N	1	\N	t
84	Croatia	HR	2023-09-11 01:01:08.627873	\N	1	\N	t
85	Anguilla	AI	2023-09-11 01:01:08.627873	\N	1	\N	t
86	Montserrat	MS	2023-09-11 01:01:08.627873	\N	1	\N	t
87	Grenada	GD	2023-09-11 01:01:08.627873	\N	1	\N	t
88	Uzbekistan	UZ	2023-09-11 01:01:08.627873	\N	1	\N	t
89	Zambia	ZM	2023-09-11 01:01:08.627873	\N	1	\N	t
90	Congo	CG	2023-09-11 01:01:08.627873	\N	1	\N	t
91	Colombia	CO	2023-09-11 01:01:08.627873	\N	1	\N	t
92	South Georgia and the South Sandwich Islands	GS	2023-09-11 01:01:08.627873	\N	1	\N	t
93	Niger	NE	2023-09-11 01:01:08.627873	\N	1	\N	t
94	Malaysia	MY	2023-09-11 01:01:08.627873	\N	1	\N	t
95	Liberia	LR	2023-09-11 01:01:08.627873	\N	1	\N	t
96	Moldova, Republic of	MD	2023-09-11 01:01:08.627873	\N	1	\N	t
97	Swaziland	SZ	2023-09-11 01:01:08.627873	\N	1	\N	t
98	South Africa	ZA	2023-09-11 01:01:08.627873	\N	1	\N	t
99	Tuvalu	TV	2023-09-11 01:01:08.627873	\N	1	\N	t
100	Cote D"Ivoire	CI	2023-09-11 01:01:08.627873	\N	1	\N	t
101	Greece	GR	2023-09-11 01:01:08.627873	\N	1	\N	t
102	Uruguay	UY	2023-09-11 01:01:08.627873	\N	1	\N	t
103	Belize	BZ	2023-09-11 01:01:08.627873	\N	1	\N	t
104	Barbados	BB	2023-09-11 01:01:08.627873	\N	1	\N	t
105	Heard Island and Mcdonald Islands	HM	2023-09-11 01:01:08.627873	\N	1	\N	t
106	RWANDA	RW	2023-09-11 01:01:08.627873	\N	1	\N	t
107	Lao People"s Democratic Republic	LA	2023-09-11 01:01:08.627873	\N	1	\N	t
108	Antarctica	AQ	2023-09-11 01:01:08.627873	\N	1	\N	t
109	Philippines	PH	2023-09-11 01:01:08.627873	\N	1	\N	t
110	El Salvador	SV	2023-09-11 01:01:08.627873	\N	1	\N	t
111	Guyana	GY	2023-09-11 01:01:08.627873	\N	1	\N	t
112	Fiji	FJ	2023-09-11 01:01:08.627873	\N	1	\N	t
113	Marshall Islands	MH	2023-09-11 01:01:08.627873	\N	1	\N	t
114	Guam	GU	2023-09-11 01:01:08.627873	\N	1	\N	t
115	Martinique	MQ	2023-09-11 01:01:08.627873	\N	1	\N	t
116	Christmas Island	CX	2023-09-11 01:01:08.627873	\N	1	\N	t
117	Jersey	JE	2023-09-11 01:01:08.627873	\N	1	\N	t
118	Chad	TD	2023-09-11 01:01:08.627873	\N	1	\N	t
119	Guinea-Bissau	GW	2023-09-11 01:01:08.627873	\N	1	\N	t
120	Ethiopia	ET	2023-09-11 01:01:08.627873	\N	1	\N	t
121	Trinidad and Tobago	TT	2023-09-11 01:01:08.627873	\N	1	\N	t
122	Italy	IT	2023-09-11 01:01:08.627873	\N	1	\N	t
123	Albania	AL	2023-09-11 01:01:08.627873	\N	1	\N	t
124	Kiribati	KI	2023-09-11 01:01:08.627873	\N	1	\N	t
125	Guernsey	GG	2023-09-11 01:01:08.627873	\N	1	\N	t
126	Mozambique	MZ	2023-09-11 01:01:08.627873	\N	1	\N	t
127	Virgin Islands, British	VG	2023-09-11 01:01:08.627873	\N	1	\N	t
128	Indonesia	ID	2023-09-11 01:01:08.627873	\N	1	\N	t
129	Bulgaria	BG	2023-09-11 01:01:08.627873	\N	1	\N	t
130	Palestinian Territory, Occupied	PS	2023-09-11 01:01:08.627873	\N	1	\N	t
131	Libyan Arab Jamahiriya	LY	2023-09-11 01:01:08.627873	\N	1	\N	t
132	Åland Islands	AX	2023-09-11 01:01:08.627873	\N	1	\N	t
133	Pitcairn	PN	2023-09-11 01:01:08.627873	\N	1	\N	t
134	Egypt	EG	2023-09-11 01:01:08.627873	\N	1	\N	t
135	Venezuela	VE	2023-09-11 01:01:08.627873	\N	1	\N	t
136	France	FR	2023-09-11 01:01:08.627873	\N	1	\N	t
137	Yemen	YE	2023-09-11 01:01:08.627873	\N	1	\N	t
138	Tonga	TO	2023-09-11 01:01:08.627873	\N	1	\N	t
139	Tokelau	TK	2023-09-11 01:01:08.627873	\N	1	\N	t
140	Mongolia	MN	2023-09-11 01:01:08.627873	\N	1	\N	t
141	Macao	MO	2023-09-11 01:01:08.627873	\N	1	\N	t
142	Sierra Leone	SL	2023-09-11 01:01:08.627873	\N	1	\N	t
143	Korea, Democratic People"s Republic of	KP	2023-09-11 01:01:08.627873	\N	1	\N	t
144	Nepal	NP	2023-09-11 01:01:08.627873	\N	1	\N	t
145	Burkina Faso	BF	2023-09-11 01:01:08.627873	\N	1	\N	t
146	Wallis and Futuna	WF	2023-09-11 01:01:08.627873	\N	1	\N	t
147	Macedonia, The Former Yugoslav Republic of	MK	2023-09-11 01:01:08.627873	\N	1	\N	t
148	Papua New Guinea	PG	2023-09-11 01:01:08.627873	\N	1	\N	t
149	Hungary	HU	2023-09-11 01:01:08.627873	\N	1	\N	t
150	Palau	PW	2023-09-11 01:01:08.627873	\N	1	\N	t
151	Nicaragua	NI	2023-09-11 01:01:08.627873	\N	1	\N	t
152	Panama	PA	2023-09-11 01:01:08.627873	\N	1	\N	t
153	Ghana	GH	2023-09-11 01:01:08.627873	\N	1	\N	t
154	Equatorial Guinea	GQ	2023-09-11 01:01:08.627873	\N	1	\N	t
155	Svalbard and Jan Mayen	SJ	2023-09-11 01:01:08.627873	\N	1	\N	t
156	Turkey	TR	2023-09-11 01:01:08.627873	\N	1	\N	t
157	Cape Verde	CV	2023-09-11 01:01:08.627873	\N	1	\N	t
158	Dominica	DM	2023-09-11 01:01:08.627873	\N	1	\N	t
159	Russian Federation	RU	2023-09-11 01:01:08.627873	\N	1	\N	t
160	Bahrain	BH	2023-09-11 01:01:08.627873	\N	1	\N	t
161	Dominican Republic	DO	2023-09-11 01:01:08.627873	\N	1	\N	t
162	Seychelles	SC	2023-09-11 01:01:08.627873	\N	1	\N	t
163	Nigeria	NG	2023-09-11 01:01:08.627873	\N	1	\N	t
164	San Marino	SM	2023-09-11 01:01:08.627873	\N	1	\N	t
165	Malawi	MW	2023-09-11 01:01:08.627873	\N	1	\N	t
166	Cambodia	KH	2023-09-11 01:01:08.627873	\N	1	\N	t
167	Peru	PE	2023-09-11 01:01:08.627873	\N	1	\N	t
168	Saint Kitts and Nevis	KN	2023-09-11 01:01:08.627873	\N	1	\N	t
169	Faroe Islands	FO	2023-09-11 01:01:08.627873	\N	1	\N	t
170	Niue	NU	2023-09-11 01:01:08.627873	\N	1	\N	t
171	Nauru	NR	2023-09-11 01:01:08.627873	\N	1	\N	t
172	Singapore	SG	2023-09-11 01:01:08.627873	\N	1	\N	t
173	Ireland	IE	2023-09-11 01:01:08.627873	\N	1	\N	t
174	Georgia	GE	2023-09-11 01:01:08.627873	\N	1	\N	t
175	Latvia	LV	2023-09-11 01:01:08.627873	\N	1	\N	t
176	Togo	TG	2023-09-11 01:01:08.627873	\N	1	\N	t
177	Solomon Islands	SB	2023-09-11 01:01:08.627873	\N	1	\N	t
178	Kazakhstan	KZ	2023-09-11 01:01:08.627873	\N	1	\N	t
179	Saudi Arabia	SA	2023-09-11 01:01:08.627873	\N	1	\N	t
180	Bolivia	BO	2023-09-11 01:01:08.627873	\N	1	\N	t
181	New Caledonia	NC	2023-09-11 01:01:08.627873	\N	1	\N	t
182	Paraguay	PY	2023-09-11 01:01:08.627873	\N	1	\N	t
183	Iceland	IS	2023-09-11 01:01:08.627873	\N	1	\N	t
184	Guadeloupe	GP	2023-09-11 01:01:08.627873	\N	1	\N	t
185	Haiti	HT	2023-09-11 01:01:08.627873	\N	1	\N	t
186	Cameroon	CM	2023-09-11 01:01:08.627873	\N	1	\N	t
187	Netherlands Antilles	AN	2023-09-11 01:01:08.627873	\N	1	\N	t
188	Jamaica	JM	2023-09-11 01:01:08.627873	\N	1	\N	t
189	Uganda	UG	2023-09-11 01:01:08.627873	\N	1	\N	t
190	Cyprus	CY	2023-09-11 01:01:08.627873	\N	1	\N	t
191	Sao Tome and Principe	ST	2023-09-11 01:01:08.627873	\N	1	\N	t
192	United Kingdom	GB	2023-09-11 01:01:08.627873	\N	1	\N	t
193	Mayotte	YT	2023-09-11 01:01:08.627873	\N	1	\N	t
194	Zimbabwe	ZW	2023-09-11 01:01:08.627873	\N	1	\N	t
195	Bangladesh	BD	2023-09-11 01:01:08.627873	\N	1	\N	t
196	French Guiana	GF	2023-09-11 01:01:08.627873	\N	1	\N	t
197	Lithuania	LT	2023-09-11 01:01:08.627873	\N	1	\N	t
198	China	CN	2023-09-11 01:01:08.627873	\N	1	\N	t
199	Bouvet Island	BV	2023-09-11 01:01:08.627873	\N	1	\N	t
200	Puerto Rico	PR	2023-09-11 01:01:08.627873	\N	1	\N	t
201	Morocco	MA	2023-09-11 01:01:08.627873	\N	1	\N	t
202	Portugal	PT	2023-09-11 01:01:08.627873	\N	1	\N	t
203	Myanmar	MM	2023-09-11 01:01:08.627873	\N	1	\N	t
204	Costa Rica	CR	2023-09-11 01:01:08.627873	\N	1	\N	t
205	Estonia	EE	2023-09-11 01:01:08.627873	\N	1	\N	t
206	New Zealand	NZ	2023-09-11 01:01:08.627873	\N	1	\N	t
207	Brunei Darussalam	BN	2023-09-11 01:01:08.627873	\N	1	\N	t
208	Japan	JP	2023-09-11 01:01:08.627873	\N	1	\N	t
209	Saint Vincent and the Grenadines	VC	2023-09-11 01:01:08.627873	\N	1	\N	t
210	Australia	AU	2023-09-11 01:01:08.627873	\N	1	\N	t
211	Senegal	SN	2023-09-11 01:01:08.627873	\N	1	\N	t
212	Viet Nam	VN	2023-09-11 01:01:08.627873	\N	1	\N	t
213	Reunion	RE	2023-09-11 01:01:08.627873	\N	1	\N	t
214	Sudan	SD	2023-09-11 01:01:08.627873	\N	1	\N	t
215	Kuwait	KW	2023-09-11 01:01:08.627873	\N	1	\N	t
216	Austria	AT	2023-09-11 01:01:08.627873	\N	1	\N	t
217	Honduras	HN	2023-09-11 01:01:08.627873	\N	1	\N	t
218	Ecuador	EC	2023-09-11 01:01:08.627873	\N	1	\N	t
219	Antigua and Barbuda	AG	2023-09-11 01:01:08.627873	\N	1	\N	t
220	Andorra	AD	2023-09-11 01:01:08.627873	\N	1	\N	t
221	Azerbaijan	AZ	2023-09-11 01:01:08.627873	\N	1	\N	t
222	Tunisia	TN	2023-09-11 01:01:08.627873	\N	1	\N	t
223	Isle of Man	IM	2023-09-11 01:01:08.627873	\N	1	\N	t
224	Namibia	NA	2023-09-11 01:01:08.627873	\N	1	\N	t
225	Sri Lanka	LK	2023-09-11 01:01:08.627873	\N	1	\N	t
226	Northern Mariana Islands	MP	2023-09-11 01:01:08.627873	\N	1	\N	t
227	Tajikistan	TJ	2023-09-11 01:01:08.627873	\N	1	\N	t
228	Micronesia, Federated States of	FM	2023-09-11 01:01:08.627873	\N	1	\N	t
229	Suriname	SR	2023-09-11 01:01:08.627873	\N	1	\N	t
230	Cayman Islands	KY	2023-09-11 01:01:08.627873	\N	1	\N	t
231	Hong Kong	HK	2023-09-11 01:01:08.627873	\N	1	\N	t
232	Gibraltar	GI	2023-09-11 01:01:08.627873	\N	1	\N	t
233	Algeria	DZ	2023-09-11 01:01:08.627873	\N	1	\N	t
234	Bhutan	BT	2023-09-11 01:01:08.627873	\N	1	\N	t
235	Turkmenistan	TM	2023-09-11 01:01:08.627873	\N	1	\N	t
236	Mali	ML	2023-09-11 01:01:08.627873	\N	1	\N	t
237	Switzerland	CH	2023-09-11 01:01:08.627873	\N	1	\N	t
238	Gambia	GM	2023-09-11 01:01:08.627873	\N	1	\N	t
239	Mexico	MX	2023-09-11 01:01:08.627873	\N	1	\N	t
240	India	IN	2023-09-11 01:01:08.627873	\N	1	\N	t
241	Israel	IL	2023-09-11 01:01:08.627873	\N	1	\N	t
242	Kenya	KE	2023-09-11 01:01:08.627873	\N	1	\N	t
243	Netherlands	NL	2023-09-11 01:01:08.627873	\N	1	\N	t
\.


--
-- TOC entry 4226 (class 0 OID 16436)
-- Dependencies: 249
-- Data for Name: currency_rates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.currency_rates (currency_code, price, created_at, updated_at, created_by, updated_by, active, id) FROM stdin;
AED	3.673055	2023-09-13 23:46:23.012362	\N	1	\N	t	1
AFN	78.901895	2023-09-13 23:46:23.012362	\N	1	\N	t	2
ALL	99.117346	2023-09-13 23:46:23.012362	\N	1	\N	t	3
AMD	385.384079	2023-09-13 23:46:23.012362	\N	1	\N	t	4
ANG	1.802743	2023-09-13 23:46:23.012362	\N	1	\N	t	5
AOA	827.402833	2023-09-13 23:46:23.012362	\N	1	\N	t	6
ARS	349.9703	2023-09-13 23:46:23.012362	\N	1	\N	t	7
AUD	1.559841	2023-09-13 23:46:23.012362	\N	1	\N	t	8
AWG	1.8	2023-09-13 23:46:23.012362	\N	1	\N	t	9
AZN	1.7	2023-09-13 23:46:23.012362	\N	1	\N	t	10
BAM	1.82195	2023-09-13 23:46:23.012362	\N	1	\N	t	11
BBD	2	2023-09-13 23:46:23.012362	\N	1	\N	t	12
BDT	109.775347	2023-09-13 23:46:23.012362	\N	1	\N	t	13
BGN	1.82192	2023-09-13 23:46:23.012362	\N	1	\N	t	14
BHD	0.37696	2023-09-13 23:46:23.012362	\N	1	\N	t	15
BIF	2833.331536	2023-09-13 23:46:23.012362	\N	1	\N	t	16
BMD	1	2023-09-13 23:46:23.012362	\N	1	\N	t	17
BND	1.362118	2023-09-13 23:46:23.012362	\N	1	\N	t	18
BOB	6.912131	2023-09-13 23:46:23.012362	\N	1	\N	t	19
BRL	4.9351	2023-09-13 23:46:23.012362	\N	1	\N	t	20
BSD	1	2023-09-13 23:46:23.012362	\N	1	\N	t	21
BTC	0.000038151681	2023-09-13 23:46:23.012362	\N	1	\N	t	22
BTN	82.975093	2023-09-13 23:46:23.012362	\N	1	\N	t	23
BWP	13.637337	2023-09-13 23:46:23.012362	\N	1	\N	t	24
BYN	2.524862	2023-09-13 23:46:23.012362	\N	1	\N	t	25
BZD	2.016237	2023-09-13 23:46:23.012362	\N	1	\N	t	26
CAD	1.355327	2023-09-13 23:46:23.012362	\N	1	\N	t	27
CDF	2482.655363	2023-09-13 23:46:23.012362	\N	1	\N	t	28
CHF	0.89242	2023-09-13 23:46:23.012362	\N	1	\N	t	29
CLF	0.032324	2023-09-13 23:46:23.012362	\N	1	\N	t	30
CLP	891.56	2023-09-13 23:46:23.012362	\N	1	\N	t	31
CNH	7.279042	2023-09-13 23:46:23.012362	\N	1	\N	t	32
CNY	7.2812	2023-09-13 23:46:23.012362	\N	1	\N	t	33
COP	3983.812907	2023-09-13 23:46:23.012362	\N	1	\N	t	34
CRC	535.0845	2023-09-13 23:46:23.012362	\N	1	\N	t	35
CUC	1	2023-09-13 23:46:23.012362	\N	1	\N	t	36
CUP	25.75	2023-09-13 23:46:23.012362	\N	1	\N	t	37
CVE	102.718763	2023-09-13 23:46:23.012362	\N	1	\N	t	38
CZK	22.769782	2023-09-13 23:46:23.012362	\N	1	\N	t	39
DJF	178.094505	2023-09-13 23:46:23.012362	\N	1	\N	t	40
DKK	6.9419	2023-09-13 23:46:23.012362	\N	1	\N	t	41
DOP	56.78753	2023-09-13 23:46:23.012362	\N	1	\N	t	42
DZD	137.148706	2023-09-13 23:46:23.012362	\N	1	\N	t	43
EGP	30.892335	2023-09-13 23:46:23.012362	\N	1	\N	t	44
ERN	15	2023-09-13 23:46:23.012362	\N	1	\N	t	45
ETB	55.164392	2023-09-13 23:46:23.012362	\N	1	\N	t	46
FJD	2.26815	2023-09-13 23:46:23.012362	\N	1	\N	t	47
FKP	0.800877	2023-09-13 23:46:23.012362	\N	1	\N	t	48
GBP	0.800877	2023-09-13 23:46:23.012362	\N	1	\N	t	49
GEL	2.62	2023-09-13 23:46:23.012362	\N	1	\N	t	50
GGP	0.800877	2023-09-13 23:46:23.012362	\N	1	\N	t	51
GHS	11.452526	2023-09-13 23:46:23.012362	\N	1	\N	t	52
GIP	0.800877	2023-09-13 23:46:23.012362	\N	1	\N	t	53
GMD	60.5	2023-09-13 23:46:23.012362	\N	1	\N	t	54
GNF	8587.115723	2023-09-13 23:46:23.012362	\N	1	\N	t	55
GTQ	7.873495	2023-09-13 23:46:23.012362	\N	1	\N	t	56
GYD	209.431994	2023-09-13 23:46:23.012362	\N	1	\N	t	57
HKD	7.82471	2023-09-13 23:46:23.012362	\N	1	\N	t	58
HNL	24.642972	2023-09-13 23:46:23.012362	\N	1	\N	t	59
HRK	7.00902	2023-09-13 23:46:23.012362	\N	1	\N	t	60
HTG	135.55518	2023-09-13 23:46:23.012362	\N	1	\N	t	61
HUF	357.182449	2023-09-13 23:46:23.012362	\N	1	\N	t	62
IDR	15361.338735	2023-09-13 23:46:23.012362	\N	1	\N	t	63
ILS	3.819538	2023-09-13 23:46:23.012362	\N	1	\N	t	64
IMP	0.800877	2023-09-13 23:46:23.012362	\N	1	\N	t	65
INR	82.97844	2023-09-13 23:46:23.012362	\N	1	\N	t	66
IQD	1309.986637	2023-09-13 23:46:23.012362	\N	1	\N	t	67
IRR	42252.5	2023-09-13 23:46:23.012362	\N	1	\N	t	68
ISK	133.69	2023-09-13 23:46:23.012362	\N	1	\N	t	69
JEP	0.800877	2023-09-13 23:46:23.012362	\N	1	\N	t	70
JMD	154.506095	2023-09-13 23:46:23.012362	\N	1	\N	t	71
JOD	0.7082	2023-09-13 23:46:23.012362	\N	1	\N	t	72
JPY	147.43457143	2023-09-13 23:46:23.012362	\N	1	\N	t	73
KES	146.7	2023-09-13 23:46:23.012362	\N	1	\N	t	74
KGS	88.39	2023-09-13 23:46:23.012362	\N	1	\N	t	75
KHR	4113.763622	2023-09-13 23:46:23.012362	\N	1	\N	t	76
KMF	458.949862	2023-09-13 23:46:23.012362	\N	1	\N	t	77
KPW	900	2023-09-13 23:46:23.012362	\N	1	\N	t	78
KRW	1328.406581	2023-09-13 23:46:23.012362	\N	1	\N	t	79
KWD	0.308647	2023-09-13 23:46:23.012362	\N	1	\N	t	80
KYD	0.833574	2023-09-13 23:46:23.012362	\N	1	\N	t	81
KZT	466.310659	2023-09-13 23:46:23.012362	\N	1	\N	t	82
LAK	19859.778383	2023-09-13 23:46:23.012362	\N	1	\N	t	83
LBP	15034.090163	2023-09-13 23:46:23.012362	\N	1	\N	t	84
LKR	323.596832	2023-09-13 23:46:23.012362	\N	1	\N	t	85
LRD	186.450039	2023-09-13 23:46:23.012362	\N	1	\N	t	86
LSL	18.936886	2023-09-13 23:46:23.012362	\N	1	\N	t	87
LYD	4.851646	2023-09-13 23:46:23.012362	\N	1	\N	t	88
MAD	10.166048	2023-09-13 23:46:23.012362	\N	1	\N	t	89
MDL	17.979925	2023-09-13 23:46:23.012362	\N	1	\N	t	90
MGA	4515.248868	2023-09-13 23:46:23.012362	\N	1	\N	t	91
MKD	57.267538	2023-09-13 23:46:23.012362	\N	1	\N	t	92
MMK	2100.61562	2023-09-13 23:46:23.012362	\N	1	\N	t	93
MNT	3450	2023-09-13 23:46:23.012362	\N	1	\N	t	94
MOP	8.06083	2023-09-13 23:46:23.012362	\N	1	\N	t	95
MRU	38.180568	2023-09-13 23:46:23.012362	\N	1	\N	t	96
MUR	44.800671	2023-09-13 23:46:23.012362	\N	1	\N	t	97
MVR	15.38	2023-09-13 23:46:23.012362	\N	1	\N	t	98
MWK	1099.328736	2023-09-13 23:46:23.012362	\N	1	\N	t	99
MXN	17.190389	2023-09-13 23:46:23.012362	\N	1	\N	t	100
MYR	4.68	2023-09-13 23:46:23.012362	\N	1	\N	t	101
MZN	63.875002	2023-09-13 23:46:23.012362	\N	1	\N	t	102
NAD	18.91	2023-09-13 23:46:23.012362	\N	1	\N	t	103
NGN	744.68	2023-09-13 23:46:23.012362	\N	1	\N	t	104
NIO	36.601782	2023-09-13 23:46:23.012362	\N	1	\N	t	105
NOK	10.679603	2023-09-13 23:46:23.012362	\N	1	\N	t	106
NPR	132.760445	2023-09-13 23:46:23.012362	\N	1	\N	t	107
NZD	1.6922	2023-09-13 23:46:23.012362	\N	1	\N	t	108
OMR	0.384994	2023-09-13 23:46:23.012362	\N	1	\N	t	109
PAB	1	2023-09-13 23:46:23.012362	\N	1	\N	t	110
PEN	3.700971	2023-09-13 23:46:23.012362	\N	1	\N	t	111
PGK	3.674947	2023-09-13 23:46:23.012362	\N	1	\N	t	112
PHP	56.778501	2023-09-13 23:46:23.012362	\N	1	\N	t	113
PKR	295.325645	2023-09-13 23:46:23.012362	\N	1	\N	t	114
PLN	4.299235	2023-09-13 23:46:23.012362	\N	1	\N	t	115
PYG	7279.201061	2023-09-13 23:46:23.012362	\N	1	\N	t	116
QAR	3.649518	2023-09-13 23:46:23.012362	\N	1	\N	t	117
RON	4.6227	2023-09-13 23:46:23.012362	\N	1	\N	t	118
RSD	109.156478	2023-09-13 23:46:23.012362	\N	1	\N	t	119
RUB	96.225005	2023-09-13 23:46:23.012362	\N	1	\N	t	120
RWF	1205.365903	2023-09-13 23:46:23.012362	\N	1	\N	t	121
SAR	3.751017	2023-09-13 23:46:23.012362	\N	1	\N	t	122
SBD	8.418851	2023-09-13 23:46:23.012362	\N	1	\N	t	123
SCR	12.874554	2023-09-13 23:46:23.012362	\N	1	\N	t	124
SDG	601.5	2023-09-13 23:46:23.012362	\N	1	\N	t	125
SEK	11.110656	2023-09-13 23:46:23.012362	\N	1	\N	t	126
SGD	1.3613	2023-09-13 23:46:23.012362	\N	1	\N	t	127
SHP	0.800877	2023-09-13 23:46:23.012362	\N	1	\N	t	128
SLL	20969.5	2023-09-13 23:46:23.012362	\N	1	\N	t	129
SOS	571.601989	2023-09-13 23:46:23.012362	\N	1	\N	t	130
SRD	38.212	2023-09-13 23:46:23.012362	\N	1	\N	t	131
SSP	130.26	2023-09-13 23:46:23.012362	\N	1	\N	t	132
STD	22281.8	2023-09-13 23:46:23.012362	\N	1	\N	t	133
STN	22.823606	2023-09-13 23:46:23.012362	\N	1	\N	t	134
SVC	8.752032	2023-09-13 23:46:23.012362	\N	1	\N	t	135
SYP	2512.53	2023-09-13 23:46:23.012362	\N	1	\N	t	136
SZL	18.942839	2023-09-13 23:46:23.012362	\N	1	\N	t	137
THB	35.7065	2023-09-13 23:46:23.012362	\N	1	\N	t	138
TJS	10.987671	2023-09-13 23:46:23.012362	\N	1	\N	t	139
TMT	3.51	2023-09-13 23:46:23.012362	\N	1	\N	t	140
TND	3.13125	2023-09-13 23:46:23.012362	\N	1	\N	t	141
TOP	2.392269	2023-09-13 23:46:23.012362	\N	1	\N	t	142
TRY	26.940406	2023-09-13 23:46:23.012362	\N	1	\N	t	143
TTD	6.790098	2023-09-13 23:46:23.012362	\N	1	\N	t	144
TWD	31.941387	2023-09-13 23:46:23.012362	\N	1	\N	t	145
TZS	2505.601	2023-09-13 23:46:23.012362	\N	1	\N	t	146
UAH	36.941823	2023-09-13 23:46:23.012362	\N	1	\N	t	147
UGX	3723.537745	2023-09-13 23:46:23.012362	\N	1	\N	t	148
USD	1	2023-09-13 23:46:23.012362	\N	1	\N	t	149
UYU	38.092132	2023-09-13 23:46:23.012362	\N	1	\N	t	150
UZS	12165.492557	2023-09-13 23:46:23.012362	\N	1	\N	t	151
VES	33.295446	2023-09-13 23:46:23.012362	\N	1	\N	t	152
VND	24163.347381	2023-09-13 23:46:23.012362	\N	1	\N	t	153
VUV	118.722	2023-09-13 23:46:23.012362	\N	1	\N	t	154
WST	2.7185	2023-09-13 23:46:23.012362	\N	1	\N	t	155
XAF	610.31822	2023-09-13 23:46:23.012362	\N	1	\N	t	156
XAG	0.04360243	2023-09-13 23:46:23.012362	\N	1	\N	t	157
XAU	0.00052296	2023-09-13 23:46:23.012362	\N	1	\N	t	158
XCD	2.70255	2023-09-13 23:46:23.012362	\N	1	\N	t	159
XDR	0.757002	2023-09-13 23:46:23.012362	\N	1	\N	t	160
XOF	610.31822	2023-09-13 23:46:23.012362	\N	1	\N	t	161
XPD	0.00080487	2023-09-13 23:46:23.012362	\N	1	\N	t	162
XPF	111.029132	2023-09-13 23:46:23.012362	\N	1	\N	t	163
XPT	0.00110942	2023-09-13 23:46:23.012362	\N	1	\N	t	164
YER	250.324945	2023-09-13 23:46:23.012362	\N	1	\N	t	165
ZAR	18.863757	2023-09-13 23:46:23.012362	\N	1	\N	t	166
ZMW	21.04008	2023-09-13 23:46:23.012362	\N	1	\N	t	167
ZWL	322	2023-09-13 23:46:23.012362	\N	1	\N	t	168
EUR	0.9118	2023-09-13 23:46:23.012362	\N	1	\N	t	169
\.


--
-- TOC entry 4228 (class 0 OID 16444)
-- Dependencies: 251
-- Data for Name: currency_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.currency_type (id, name, symbol, symbol_native, decimal_digits, rounding, code, name_plural, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	US Dollar	$	$	2	0	USD	US dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
2	Canadian Dollar	CA$	$	2	0	CAD	Canadian dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
4	United Arab Emirates Dirham	AED	د.إ.‏	2	0	AED	UAE dirhams	2023-09-11 02:02:39.375796	\N	1	\N	t
5	Afghan Afghani	Af	؋	0	0	AFN	Afghan Afghanis	2023-09-11 02:02:39.375796	\N	1	\N	t
6	Albanian Lek	ALL	Lek	0	0	ALL	Albanian lekë	2023-09-11 02:02:39.375796	\N	1	\N	t
7	Armenian Dram	AMD	դր.	0	0	AMD	Armenian drams	2023-09-11 02:02:39.375796	\N	1	\N	t
8	Argentine Peso	AR$	$	2	0	ARS	Argentine pesos	2023-09-11 02:02:39.375796	\N	1	\N	t
9	Australian Dollar	AU$	$	2	0	AUD	Australian dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
10	Azerbaijani Manat	man.	ман.	2	0	AZN	Azerbaijani manats	2023-09-11 02:02:39.375796	\N	1	\N	t
11	Bosnia-Herzegovina Convertible Mark	KM	KM	2	0	BAM	Bosnia-Herzegovina convertible marks	2023-09-11 02:02:39.375796	\N	1	\N	t
12	Bangladeshi Taka	Tk	৳	2	0	BDT	Bangladeshi takas	2023-09-11 02:02:39.375796	\N	1	\N	t
13	Bulgarian Lev	BGN	лв.	2	0	BGN	Bulgarian leva	2023-09-11 02:02:39.375796	\N	1	\N	t
14	Bahraini Dinar	BD	د.ب.‏	3	0	BHD	Bahraini dinars	2023-09-11 02:02:39.375796	\N	1	\N	t
15	Burundian Franc	FBu	FBu	0	0	BIF	Burundian francs	2023-09-11 02:02:39.375796	\N	1	\N	t
16	Brunei Dollar	BN$	$	2	0	BND	Brunei dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
17	Bolivian Boliviano	Bs	Bs	2	0	BOB	Bolivian bolivianos	2023-09-11 02:02:39.375796	\N	1	\N	t
18	Brazilian Real	R$	R$	2	0	BRL	Brazilian reals	2023-09-11 02:02:39.375796	\N	1	\N	t
19	Botswanan Pula	BWP	P	2	0	BWP	Botswanan pulas	2023-09-11 02:02:39.375796	\N	1	\N	t
20	Belarusian Ruble	Br	руб.	2	0	BYN	Belarusian rubles	2023-09-11 02:02:39.375796	\N	1	\N	t
21	Belize Dollar	BZ$	$	2	0	BZD	Belize dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
22	Congolese Franc	CDF	FrCD	2	0	CDF	Congolese francs	2023-09-11 02:02:39.375796	\N	1	\N	t
23	Swiss Franc	CHF	CHF	2	0.05	CHF	Swiss francs	2023-09-11 02:02:39.375796	\N	1	\N	t
24	Chilean Peso	CL$	$	0	0	CLP	Chilean pesos	2023-09-11 02:02:39.375796	\N	1	\N	t
25	Chinese Yuan	CN¥	CN¥	2	0	CNY	Chinese yuan	2023-09-11 02:02:39.375796	\N	1	\N	t
26	Colombian Peso	CO$	$	0	0	COP	Colombian pesos	2023-09-11 02:02:39.375796	\N	1	\N	t
27	Costa Rican Colón	₡	₡	0	0	CRC	Costa Rican colóns	2023-09-11 02:02:39.375796	\N	1	\N	t
28	Cape Verdean Escudo	CV$	CV$	2	0	CVE	Cape Verdean escudos	2023-09-11 02:02:39.375796	\N	1	\N	t
29	Czech Republic Koruna	Kč	Kč	2	0	CZK	Czech Republic korunas	2023-09-11 02:02:39.375796	\N	1	\N	t
30	Djiboutian Franc	Fdj	Fdj	0	0	DJF	Djiboutian francs	2023-09-11 02:02:39.375796	\N	1	\N	t
31	Danish Krone	Dkr	kr	2	0	DKK	Danish kroner	2023-09-11 02:02:39.375796	\N	1	\N	t
32	Dominican Peso	RD$	RD$	2	0	DOP	Dominican pesos	2023-09-11 02:02:39.375796	\N	1	\N	t
33	Algerian Dinar	DA	د.ج.‏	2	0	DZD	Algerian dinars	2023-09-11 02:02:39.375796	\N	1	\N	t
34	Estonian Kroon	Ekr	kr	2	0	EEK	Estonian kroons	2023-09-11 02:02:39.375796	\N	1	\N	t
35	Egyptian Pound	EGP	ج.م.‏	2	0	EGP	Egyptian pounds	2023-09-11 02:02:39.375796	\N	1	\N	t
36	Eritrean Nakfa	Nfk	Nfk	2	0	ERN	Eritrean nakfas	2023-09-11 02:02:39.375796	\N	1	\N	t
37	Ethiopian Birr	Br	Br	2	0	ETB	Ethiopian birrs	2023-09-11 02:02:39.375796	\N	1	\N	t
38	British Pound Sterling	£	£	2	0	GBP	British pounds sterling	2023-09-11 02:02:39.375796	\N	1	\N	t
39	Georgian Lari	GEL	GEL	2	0	GEL	Georgian laris	2023-09-11 02:02:39.375796	\N	1	\N	t
40	Ghanaian Cedi	GH₵	GH₵	2	0	GHS	Ghanaian cedis	2023-09-11 02:02:39.375796	\N	1	\N	t
41	Guinean Franc	FG	FG	0	0	GNF	Guinean francs	2023-09-11 02:02:39.375796	\N	1	\N	t
42	Guatemalan Quetzal	GTQ	Q	2	0	GTQ	Guatemalan quetzals	2023-09-11 02:02:39.375796	\N	1	\N	t
43	Hong Kong Dollar	HK$	$	2	0	HKD	Hong Kong dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
44	Honduran Lempira	HNL	L	2	0	HNL	Honduran lempiras	2023-09-11 02:02:39.375796	\N	1	\N	t
45	Croatian Kuna	kn	kn	2	0	HRK	Croatian kunas	2023-09-11 02:02:39.375796	\N	1	\N	t
46	Hungarian Forint	Ft	Ft	0	0	HUF	Hungarian forints	2023-09-11 02:02:39.375796	\N	1	\N	t
47	Indonesian Rupiah	Rp	Rp	0	0	IDR	Indonesian rupiahs	2023-09-11 02:02:39.375796	\N	1	\N	t
48	Israeli New Sheqel	₪	₪	2	0	ILS	Israeli new sheqels	2023-09-11 02:02:39.375796	\N	1	\N	t
49	Indian Rupee	Rs	টকা	2	0	INR	Indian rupees	2023-09-11 02:02:39.375796	\N	1	\N	t
50	Iraqi Dinar	IQD	د.ع.‏	0	0	IQD	Iraqi dinars	2023-09-11 02:02:39.375796	\N	1	\N	t
51	Iranian Rial	IRR	﷼	0	0	IRR	Iranian rials	2023-09-11 02:02:39.375796	\N	1	\N	t
52	Icelandic Króna	Ikr	kr	0	0	ISK	Icelandic krónur	2023-09-11 02:02:39.375796	\N	1	\N	t
53	Jamaican Dollar	J$	$	2	0	JMD	Jamaican dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
54	Jordanian Dinar	JD	د.أ.‏	3	0	JOD	Jordanian dinars	2023-09-11 02:02:39.375796	\N	1	\N	t
55	Japanese Yen	¥	￥	0	0	JPY	Japanese yen	2023-09-11 02:02:39.375796	\N	1	\N	t
56	Kenyan Shilling	Ksh	Ksh	2	0	KES	Kenyan shillings	2023-09-11 02:02:39.375796	\N	1	\N	t
57	Cambodian Riel	KHR	៛	2	0	KHR	Cambodian riels	2023-09-11 02:02:39.375796	\N	1	\N	t
58	Comorian Franc	CF	FC	0	0	KMF	Comorian francs	2023-09-11 02:02:39.375796	\N	1	\N	t
59	South Korean Won	₩	₩	0	0	KRW	South Korean won	2023-09-11 02:02:39.375796	\N	1	\N	t
60	Kuwaiti Dinar	KD	د.ك.‏	3	0	KWD	Kuwaiti dinars	2023-09-11 02:02:39.375796	\N	1	\N	t
61	Kazakhstani Tenge	KZT	тңг.	2	0	KZT	Kazakhstani tenges	2023-09-11 02:02:39.375796	\N	1	\N	t
62	Lebanese Pound	LB£	ل.ل.‏	0	0	LBP	Lebanese pounds	2023-09-11 02:02:39.375796	\N	1	\N	t
63	Sri Lankan Rupee	SLRs	SL Re	2	0	LKR	Sri Lankan rupees	2023-09-11 02:02:39.375796	\N	1	\N	t
64	Lithuanian Litas	Lt	Lt	2	0	LTL	Lithuanian litai	2023-09-11 02:02:39.375796	\N	1	\N	t
65	Latvian Lats	Ls	Ls	2	0	LVL	Latvian lati	2023-09-11 02:02:39.375796	\N	1	\N	t
66	Libyan Dinar	LD	د.ل.‏	3	0	LYD	Libyan dinars	2023-09-11 02:02:39.375796	\N	1	\N	t
67	Moroccan Dirham	MAD	د.م.‏	2	0	MAD	Moroccan dirhams	2023-09-11 02:02:39.375796	\N	1	\N	t
68	Moldovan Leu	MDL	MDL	2	0	MDL	Moldovan lei	2023-09-11 02:02:39.375796	\N	1	\N	t
69	Malagasy Ariary	MGA	MGA	0	0	MGA	Malagasy Ariaries	2023-09-11 02:02:39.375796	\N	1	\N	t
70	Macedonian Denar	MKD	MKD	2	0	MKD	Macedonian denari	2023-09-11 02:02:39.375796	\N	1	\N	t
71	Myanma Kyat	MMK	K	0	0	MMK	Myanma kyats	2023-09-11 02:02:39.375796	\N	1	\N	t
72	Macanese Pataca	MOP$	MOP$	2	0	MOP	Macanese patacas	2023-09-11 02:02:39.375796	\N	1	\N	t
73	Mauritian Rupee	MURs	MURs	0	0	MUR	Mauritian rupees	2023-09-11 02:02:39.375796	\N	1	\N	t
74	Mexican Peso	MX$	$	2	0	MXN	Mexican pesos	2023-09-11 02:02:39.375796	\N	1	\N	t
75	Malaysian Ringgit	RM	RM	2	0	MYR	Malaysian ringgits	2023-09-11 02:02:39.375796	\N	1	\N	t
76	Mozambican Metical	MTn	MTn	2	0	MZN	Mozambican meticals	2023-09-11 02:02:39.375796	\N	1	\N	t
77	Namibian Dollar	N$	N$	2	0	NAD	Namibian dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
78	Nigerian Naira	₦	₦	2	0	NGN	Nigerian nairas	2023-09-11 02:02:39.375796	\N	1	\N	t
79	Nicaraguan Córdoba	C$	C$	2	0	NIO	Nicaraguan córdobas	2023-09-11 02:02:39.375796	\N	1	\N	t
80	Norwegian Krone	Nkr	kr	2	0	NOK	Norwegian kroner	2023-09-11 02:02:39.375796	\N	1	\N	t
81	Nepalese Rupee	NPRs	नेरू	2	0	NPR	Nepalese rupees	2023-09-11 02:02:39.375796	\N	1	\N	t
82	New Zealand Dollar	NZ$	$	2	0	NZD	New Zealand dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
83	Omani Rial	OMR	ر.ع.‏	3	0	OMR	Omani rials	2023-09-11 02:02:39.375796	\N	1	\N	t
84	Panamanian Balboa	B/.	B/.	2	0	PAB	Panamanian balboas	2023-09-11 02:02:39.375796	\N	1	\N	t
85	Peruvian Nuevo Sol	S/.	S/.	2	0	PEN	Peruvian nuevos soles	2023-09-11 02:02:39.375796	\N	1	\N	t
86	Philippine Peso	₱	₱	2	0	PHP	Philippine pesos	2023-09-11 02:02:39.375796	\N	1	\N	t
87	Pakistani Rupee	PKRs	₨	0	0	PKR	Pakistani rupees	2023-09-11 02:02:39.375796	\N	1	\N	t
88	Polish Zloty	zł	zł	2	0	PLN	Polish zlotys	2023-09-11 02:02:39.375796	\N	1	\N	t
89	Paraguayan Guarani	₲	₲	0	0	PYG	Paraguayan guaranis	2023-09-11 02:02:39.375796	\N	1	\N	t
90	Qatari Rial	QR	ر.ق.‏	2	0	QAR	Qatari rials	2023-09-11 02:02:39.375796	\N	1	\N	t
91	Romanian Leu	RON	RON	2	0	RON	Romanian lei	2023-09-11 02:02:39.375796	\N	1	\N	t
92	Serbian Dinar	din.	дин.	0	0	RSD	Serbian dinars	2023-09-11 02:02:39.375796	\N	1	\N	t
93	Russian Ruble	RUB	₽.	2	0	RUB	Russian rubles	2023-09-11 02:02:39.375796	\N	1	\N	t
94	Rwandan Franc	RWF	FR	0	0	RWF	Rwandan francs	2023-09-11 02:02:39.375796	\N	1	\N	t
95	Saudi Riyal	SR	ر.س.‏	2	0	SAR	Saudi riyals	2023-09-11 02:02:39.375796	\N	1	\N	t
96	Sudanese Pound	SDG	SDG	2	0	SDG	Sudanese pounds	2023-09-11 02:02:39.375796	\N	1	\N	t
97	Swedish Krona	Skr	kr	2	0	SEK	Swedish kronor	2023-09-11 02:02:39.375796	\N	1	\N	t
98	Singapore Dollar	S$	$	2	0	SGD	Singapore dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
99	Somali Shilling	Ssh	Ssh	0	0	SOS	Somali shillings	2023-09-11 02:02:39.375796	\N	1	\N	t
100	Syrian Pound	SY£	ل.س.‏	0	0	SYP	Syrian pounds	2023-09-11 02:02:39.375796	\N	1	\N	t
101	Thai Baht	฿	฿	2	0	THB	Thai baht	2023-09-11 02:02:39.375796	\N	1	\N	t
102	Tunisian Dinar	DT	د.ت.‏	3	0	TND	Tunisian dinars	2023-09-11 02:02:39.375796	\N	1	\N	t
103	Tongan Paʻanga	T$	T$	2	0	TOP	Tongan paʻanga	2023-09-11 02:02:39.375796	\N	1	\N	t
104	Turkish Lira	TL	TL	2	0	TRY	Turkish Lira	2023-09-11 02:02:39.375796	\N	1	\N	t
105	Trinidad and Tobago Dollar	TT$	$	2	0	TTD	Trinidad and Tobago dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
106	New Taiwan Dollar	NT$	NT$	2	0	TWD	New Taiwan dollars	2023-09-11 02:02:39.375796	\N	1	\N	t
107	Tanzanian Shilling	TSh	TSh	0	0	TZS	Tanzanian shillings	2023-09-11 02:02:39.375796	\N	1	\N	t
108	Ukrainian Hryvnia	₴	₴	2	0	UAH	Ukrainian hryvnias	2023-09-11 02:02:39.375796	\N	1	\N	t
109	Ugandan Shilling	USh	USh	0	0	UGX	Ugandan shillings	2023-09-11 02:02:39.375796	\N	1	\N	t
110	Uruguayan Peso	$U	$	2	0	UYU	Uruguayan pesos	2023-09-11 02:02:39.375796	\N	1	\N	t
111	Uzbekistan Som	UZS	UZS	0	0	UZS	Uzbekistan som	2023-09-11 02:02:39.375796	\N	1	\N	t
112	Venezuelan Bolívar	Bs.F.	Bs.F.	2	0	VEF	Venezuelan bolívars	2023-09-11 02:02:39.375796	\N	1	\N	t
113	Vietnamese Dong	₫	₫	0	0	VND	Vietnamese dong	2023-09-11 02:02:39.375796	\N	1	\N	t
114	CFA Franc BEAC	FCFA	FCFA	0	0	XAF	CFA francs BEAC	2023-09-11 02:02:39.375796	\N	1	\N	t
115	CFA Franc BCEAO	CFA	CFA	0	0	XOF	CFA francs BCEAO	2023-09-11 02:02:39.375796	\N	1	\N	t
116	Yemeni Rial	YR	ر.ي.‏	0	0	YER	Yemeni rials	2023-09-11 02:02:39.375796	\N	1	\N	t
117	South African Rand	R	R	2	0	ZAR	South African rand	2023-09-11 02:02:39.375796	\N	1	\N	t
118	Zambian Kwacha	ZK	ZK	0	0	ZMK	Zambian kwachas	2023-09-11 02:02:39.375796	\N	1	\N	t
119	Zimbabwean Dollar	ZWL$	ZWL$	0	0	ZWL	Zimbabwean Dollar	2023-09-11 02:02:39.375796	\N	1	\N	t
3	Euro	€	€	2	0	EUR	euros	2023-09-11 02:02:39.375796	\N	1	7	t
\.


--
-- TOC entry 4279 (class 0 OID 25563)
-- Dependencies: 302
-- Data for Name: customer_order; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_order (id, company_lid, order_number, notes, created_at, created_by, active) FROM stdin;
\.


--
-- TOC entry 4281 (class 0 OID 25615)
-- Dependencies: 304
-- Data for Name: customer_order_item; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer_order_item (id, order_lid, product_lid, inventory_unit_lid, created_at, created_by, active) FROM stdin;
\.


--
-- TOC entry 4230 (class 0 OID 16452)
-- Dependencies: 253
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expenses (id, name, created_by, created_at, updated_by, updated_at, active) FROM stdin;
1	VISA	owais	2023-08-25 11:31:52.629165	\N	\N	t
2	FOOD	owais	2023-08-25 11:31:52.629165	\N	\N	t
3	Water	owais	2023-08-25 11:31:52.629165	\N	\N	t
4	Air Ticket	1	2023-09-14 11:09:49.217186	\N	\N	t
5	HOTEL	1	2023-09-14 11:15:26.720239	\N	\N	t
6	Bus	1	2023-09-14 11:21:01.084984	\N	\N	t
7	Entrances	1	2023-09-14 11:26:13.565269	\N	\N	t
8	Misc.	1	2023-09-14 11:27:45.457623	\N	\N	t
9	docket	1	2023-09-16 23:12:43.858291	\N	\N	t
10	Insurance	1	2023-10-03 11:47:33.651124	\N	\N	t
11	Train	1	2023-10-03 11:48:11.026934	\N	\N	t
12	Extra Baggage 	1	2023-10-03 11:48:50.914279	\N	\N	t
13	Guide	1	2023-10-03 11:49:09.137836	\N	\N	t
14	Tips	1	2023-10-03 11:49:25.586189	\N	\N	t
15	Tour manager cost	1	2023-10-03 11:49:46.431516	\N	\N	t
16	Gifts	1	2023-10-03 11:50:21.864642	\N	\N	t
17	snacks	1	2023-10-03 11:50:56.134124	\N	\N	t
\.


--
-- TOC entry 4232 (class 0 OID 16460)
-- Dependencies: 255
-- Data for Name: fare_class; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fare_class (id, name, transport_mode_lid, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	BUSINESS	2	2023-08-31 11:01:40.181454+05:30	\N	1	\N	t
2	ECONOMY	2	2023-08-31 11:01:51.918042+05:30	\N	1	\N	t
\.


--
-- TOC entry 4283 (class 0 OID 25640)
-- Dependencies: 306
-- Data for Name: inventory_company_mapping; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventory_company_mapping (id, inventory_unit_lid, company_lid, label_lid, notes, created_at, updated_at, created_by, updated_by, active) FROM stdin;
64	64	13	2	Manual mapping	2025-08-24 19:20:09.65235	2025-08-24 19:31:59.291947	1	1	t
28	28	13	2	Manual mapping	2025-08-24 19:20:09.65235	2025-08-24 19:31:59.291947	1	1	t
1	1	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
2	2	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
3	3	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
4	4	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
5	5	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
6	6	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
7	7	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
8	8	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
9	9	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
10	10	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
11	11	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
12	12	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
13	13	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
14	14	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
15	15	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
16	16	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
17	17	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
18	18	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
19	19	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
20	20	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
21	21	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
22	22	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
23	23	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
24	24	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
25	25	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
26	26	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
27	27	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
29	29	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
30	30	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
31	31	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
32	32	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
33	33	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
34	34	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
35	35	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
36	36	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
37	37	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
38	38	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
39	39	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
40	40	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
41	41	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
42	42	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
43	43	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
44	44	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
45	45	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
46	46	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
47	47	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
48	48	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
49	49	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
50	50	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
51	51	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
52	52	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
53	53	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
54	54	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
55	55	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
56	56	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
57	57	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
58	58	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
59	59	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
60	60	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
61	61	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
62	62	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
63	63	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
65	65	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
66	66	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
67	67	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
68	68	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
69	69	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
70	70	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
71	71	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
72	72	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
73	73	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
74	74	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
75	75	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
76	76	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
77	77	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
79	79	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
80	80	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
81	81	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
82	82	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
83	83	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
84	84	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
85	85	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
86	86	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
87	87	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
88	88	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
89	89	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
90	90	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
91	91	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
92	92	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
93	93	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
94	94	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
95	95	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
105	105	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
106	106	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
107	107	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
108	108	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
109	109	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
110	110	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
111	111	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
112	112	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
113	113	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
114	114	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
115	115	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
116	116	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
117	117	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
118	118	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
119	119	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
120	120	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
121	121	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
122	122	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
123	123	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
124	124	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
125	125	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
126	126	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
127	127	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
128	128	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
129	129	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
130	130	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
131	131	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
132	132	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
133	133	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
134	134	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
136	136	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
137	137	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
138	138	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
139	139	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
140	140	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
141	141	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
142	142	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
143	143	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
144	144	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
145	145	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
146	146	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
147	147	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
148	148	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
149	149	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
150	150	1	1	Auto-map on product create	2025-08-24 19:20:09.65235	\N	1	\N	t
96	96	13	2	Manual mapping	2025-08-24 19:20:09.65235	2025-08-24 19:31:59.291947	1	1	t
97	97	13	2	Manual mapping	2025-08-24 19:20:09.65235	2025-08-24 19:31:59.291947	1	1	t
135	135	13	2	Manual mapping	2025-08-24 19:20:09.65235	2025-08-24 19:31:59.291947	1	1	t
78	78	13	1	Manual mapping	2025-08-24 19:20:09.65235	2025-08-24 19:31:59.294567	1	1	t
99	99	17	1	Manual mapping	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.210283	1	1	t
100	100	17	1	Manual mapping	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.211879	1	1	t
101	101	17	1	Manual mapping	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.212927	1	1	t
102	102	17	1	Manual mapping	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.214075	1	1	t
103	103	17	1	Manual mapping	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.215499	1	1	t
104	104	17	1	Manual mapping	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.216594	1	1	t
98	98	1	1	Transferred back to SELF	2025-08-24 19:20:09.65235	2025-09-14 17:54:00.939557	1	1	t
\.


--
-- TOC entry 4275 (class 0 OID 25407)
-- Dependencies: 298
-- Data for Name: inventory_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventory_status (id, name, description, created_at, active) FROM stdin;
1	AVAILABLE	Unit is available for mapping	2025-08-24 01:38:03.765279	t
2	MAPPED	Unit is mapped to a company	2025-08-24 01:38:03.765279	t
3	SOLD	Unit has been sold	2025-08-24 01:38:03.765279	t
4	RESERVED	Unit is reserved for an order	2025-08-24 01:38:03.765279	t
\.


--
-- TOC entry 4277 (class 0 OID 25421)
-- Dependencies: 300
-- Data for Name: inventory_unit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventory_unit (id, product_lid, status_lid, current_company_lid, created_at, updated_at, created_by, updated_by, active) FROM stdin;
64	6	2	13	2025-08-24 19:20:09.65235	2025-08-24 19:31:36.721457	1	1	t
28	4	2	13	2025-08-24 19:20:09.65235	2025-08-24 19:31:36.723851	1	1	t
78	7	2	13	2025-08-24 19:20:09.65235	2025-08-24 19:31:59.293443	1	1	t
1	1	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
2	1	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
3	1	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
4	1	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
5	1	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
6	2	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
7	2	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
8	2	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
9	2	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
10	2	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
11	2	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
12	2	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
13	2	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
14	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
15	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
16	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
17	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
18	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
19	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
20	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
21	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
22	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
23	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
24	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
25	3	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
26	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
27	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
29	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
30	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
31	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
32	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
33	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
34	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
35	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
36	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
37	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
38	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
39	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
40	4	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
41	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
42	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
43	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
44	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
45	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
46	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
47	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
48	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
49	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
50	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
51	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
52	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
53	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
54	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
55	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
56	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
57	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
58	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
59	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
60	5	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
61	6	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
62	6	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
63	6	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
65	6	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
66	6	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
67	6	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
68	6	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
69	6	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
70	6	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
71	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
72	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
73	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
74	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
75	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
76	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
77	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
79	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
80	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
81	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
82	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
83	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
84	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
96	8	2	13	2025-08-24 19:20:09.65235	2025-08-24 19:31:36.714318	1	1	t
97	8	2	13	2025-08-24 19:20:09.65235	2025-08-24 19:31:36.720061	1	1	t
135	10	2	13	2025-08-24 19:20:09.65235	2025-08-24 19:31:36.725099	1	1	t
100	8	2	17	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.210986	1	1	t
101	8	2	17	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.212266	1	1	t
102	8	2	17	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.213389	1	1	t
103	8	2	17	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.214492	1	1	t
104	8	2	17	2025-08-24 19:20:09.65235	2025-09-14 17:53:38.216033	1	1	t
98	8	1	1	2025-08-24 19:20:09.65235	2025-09-14 17:54:00.937745	1	1	t
99	8	3	17	2025-08-24 19:20:09.65235	2025-09-14 17:54:21.723229	1	1	t
85	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
86	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
87	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
88	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
89	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
90	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
91	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
92	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
93	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
94	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
95	7	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
105	8	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
106	8	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
107	8	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
108	8	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
109	8	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
110	8	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
111	8	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
112	8	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
113	8	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
114	9	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
115	9	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
116	9	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
117	9	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
118	9	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
119	9	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
120	9	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
121	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
122	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
123	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
124	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
125	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
126	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
127	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
128	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
129	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
130	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
131	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
132	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
133	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
134	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
136	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
137	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
138	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
139	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
140	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
141	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
142	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
143	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
144	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
145	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
146	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
147	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
148	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
149	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
150	10	1	1	2025-08-24 19:20:09.65235	\N	1	\N	t
\.


--
-- TOC entry 4269 (class 0 OID 25340)
-- Dependencies: 292
-- Data for Name: mapping_label; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mapping_label (id, name, description, created_at, active) FROM stdin;
1	NEW	Newly added inventory for company	2025-08-24 01:32:34.160578	t
2	OLD	Previously existing inventory for company	2025-08-24 01:32:34.160578	t
\.


--
-- TOC entry 4263 (class 0 OID 17146)
-- Dependencies: 286
-- Data for Name: mapping_receipt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mapping_receipt (id, receipt_number, company_lid, total_products, mapping_date, notes, created_by, active) FROM stdin;
14	RCP-20250810-001	12	2	2025-08-10 19:14:55.96713		1	t
15	RCP-20250810-002	12	10	2025-08-10 19:19:28.311441		1	t
\.


--
-- TOC entry 4234 (class 0 OID 16466)
-- Dependencies: 257
-- Data for Name: mode_of_transport; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mode_of_transport (id, name, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	FLIGHTS	2023-08-31 11:00:36.940318+05:30	\N	1	\N	f
2	FLIGHT	2023-08-31 11:01:09.140189+05:30	\N	1	\N	t
\.


--
-- TOC entry 4236 (class 0 OID 16472)
-- Dependencies: 259
-- Data for Name: passenger_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.passenger_type (id, name, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	Student	2023-08-30 17:59:46.946131	\N	1	\N	t
2	Faculty-Sponsored	2023-08-30 17:59:46.946131	\N	1	\N	t
3	Faculty-Unsponsored	2023-08-30 17:59:46.946131	\N	1	\N	t
5	Trip-Manager	2023-08-31 10:59:17.570389	2023-08-31 10:59:26.443554	1	1	f
4	Tour manager	2023-08-30 17:59:46.946131	2023-10-04 07:06:22.224689	1	7	t
8	Pax	2023-10-04 07:08:15.239577	\N	1	\N	t
6	Rajesh Fixed	2023-09-13 18:28:41.502017	\N	1	7	f
7	Owais Percent	2023-09-13 18:28:55.132157	\N	1	7	f
\.


--
-- TOC entry 4273 (class 0 OID 25394)
-- Dependencies: 296
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product (id, name, product_code, description, category, price, created_at, updated_at, created_by, updated_by, active, specifications) FROM stdin;
1	Rolex Submariner Classic	RSC001	Luxury diving watch with stainless steel case and ceramic bezel	Luxury Watches	850000.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 40mm Stainless Steel, Movement: Automatic, Water Resistance: 300m
2	Omega Speedmaster Professional	OSP002	Iconic chronograph watch, the first watch worn on the moon	Sport Watches	520000.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 42mm Stainless Steel, Movement: Manual Wind, Chronograph Function
3	TAG Heuer Formula 1	THF003	Racing-inspired sports watch with precision timing	Sport Watches	125000.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 41mm Steel, Movement: Quartz, Tachymeter Bezel
4	Seiko Prospex Diver	SPD004	Professional diving watch with automatic movement	Diving Watches	35000.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 44mm Steel, Movement: Automatic, Water Resistance: 200m
5	Casio G-Shock Mudmaster	CGM005	Rugged outdoor watch with mud and shock resistance	Outdoor Watches	28000.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 56mm Resin, Movement: Digital, Solar Powered
6	Citizen Eco-Drive Titanium	CET006	Lightweight titanium watch powered by light	Eco Watches	45000.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 40mm Titanium, Movement: Solar Quartz, Sapphire Crystal
7	Fossil Grant Chronograph	FGC007	Classic chronograph with leather strap and Roman numerals	Fashion Watches	18000.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 44mm Steel, Movement: Quartz Chronograph, Leather Strap
8	Apple Watch Series 9	AWS008	Advanced smartwatch with health monitoring and GPS	Smart Watches	42000.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 41mm Aluminum, Display: Always-On Retina, Health Sensors
9	Garmin Fenix 7 Solar	GFS009	Multisport GPS watch with solar charging capability	GPS Watches	75000.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 47mm Polymer, Movement: Digital, Solar Charging, GPS
10	Timex Weekender Classic	TWC010	Simple, reliable everyday watch with interchangeable straps	Casual Watches	8500.00	2025-08-24 19:20:09.65235	\N	1	\N	t	Case: 38mm Brass, Movement: Quartz, Nylon Strap, Indiglo
\.


--
-- TOC entry 4265 (class 0 OID 17223)
-- Dependencies: 288
-- Data for Name: product_sale; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_sale (id, product_lid, company_lid, quantity, sale_date, notes, receipt_lid, created_by, created_at, active) FROM stdin;
3	33	12	1	2025-08-10 19:19:28.34049		\N	1	2025-08-10 19:19:28.34049	t
\.


--
-- TOC entry 4238 (class 0 OID 16478)
-- Dependencies: 261
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	super_admin	2023-10-03 06:45:55.423291	\N	\N	\N	t
2	admin	2023-10-03 06:45:55.423291	\N	\N	\N	t
\.


--
-- TOC entry 4285 (class 0 OID 25746)
-- Dependencies: 308
-- Data for Name: sample_table; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sample_table (id, name, category, count, created_at) FROM stdin;
1	Item A	Electronics	15	2025-09-09 17:06:08.564963
2	Item B	Books	23	2025-09-09 17:06:08.564963
3	Item C	Electronics	8	2025-09-09 17:06:08.564963
4	Item D	Clothing	42	2025-09-09 17:06:08.564963
5	Item E	Books	17	2025-09-09 17:06:08.564963
6	Item F	Electronics	31	2025-09-09 17:06:08.564963
\.


--
-- TOC entry 4240 (class 0 OID 16484)
-- Dependencies: 263
-- Data for Name: state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.state (id, name, country_lid, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	MAHARSHTRA	2	2023-08-24 16:41:31.140225	\N	owais	\N	t
2	HARYANA	2	2023-08-24 16:41:31.140225	\N	owais	\N	t
3	KERALA	2	2023-08-24 16:41:31.140225	\N	owais	\N	t
4	GUJARAT	2	2023-08-24 16:41:31.140225	\N	owais	\N	t
5	RAJASTHAN	2	2023-08-24 16:41:31.140225	\N	owais	\N	t
6	MANIPUR	2	2023-08-31 10:25:24.763008	2023-08-31 10:30:07.056759	admin	admin	f
\.


--
-- TOC entry 4242 (class 0 OID 16492)
-- Dependencies: 265
-- Data for Name: tax; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tax (id, name, percentage, created_at, updated_at, created_by, updated_by, active, compounding) FROM stdin;
1	GST	5	2023-09-09 00:04:50.449416	\N	1	\N	t	0
3	CGST	7	2023-09-17 14:52:35.381202	\N	1	\N	f	0
2	TCS	5	2023-09-13 13:37:04.737442	\N	1	\N	t	1
\.


--
-- TOC entry 4244 (class 0 OID 16501)
-- Dependencies: 267
-- Data for Name: tour; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tour (id, name, duration_days, duration_nights, created_at, updated_at, created_by, updated_by, active, sealed) FROM stdin;
14	FIT Spain	13	12	2023-10-03 12:31:25.50096	2023-10-03 12:34:26.650091	9	9	f	0
13	BSSA Indore	14	13	2023-10-03 12:20:15.744146	2023-10-03 12:36:12.291239	7	7	f	0
21	FB october	11	10	2023-10-05 12:42:37.43701	2023-10-05 12:42:37.43701	11	\N	t	0
22	FB - October '23	11	10	2023-10-06 04:38:26.757146	2023-10-06 04:38:26.757146	7	\N	t	0
17	BSSA Ujjain, Maheshwar and Bhopal 	14	13	2023-10-05 06:55:18.319902	2023-10-13 05:52:04.712679	8	7	f	0
24	Feb - FB	11	10	2023-10-15 04:42:01.220747	2023-10-15 05:08:20.787579	7	7	t	1
16	BSSA EASTERN EUROUP GROUP 	10	9	2023-10-04 06:35:43.295921	2023-10-18 05:28:36.583212	9	9	t	0
18	Bangalore / Mangalore 	10	9	2023-10-05 09:23:06.678197	2023-10-21 05:33:16.036221	7	7	t	1
20	BSSA- Kolkata	11	10	2023-10-05 10:35:49.246931	2023-11-20 08:26:03.757528	7	7	f	1
23	Ujjain Bhopal	12	11	2023-10-13 05:52:31.491007	2023-11-20 08:26:11.574975	7	7	f	1
15	BSSA Bhopal	14	13	2023-10-04 05:09:33.889963	2023-11-20 08:26:19.689831	7	7	f	1
19	BSSA - Blr to BLR	10	9	2023-10-05 10:01:20.046992	2023-11-20 08:26:30.589971	7	7	f	1
12	BSSA Europe October 	11	10	2023-10-03 11:19:01.005938	2023-11-20 08:26:42.176569	7	7	f	1
25	Bali -J V Parekh	6	5	2023-10-20 00:41:49.118773	2023-11-20 08:26:49.872556	7	7	f	1
26	Kolkata - BSSA - 2023 	11	10	2023-11-20 08:29:37.218297	2023-11-20 10:44:13.480722	7	7	t	1
27	Indore Ujjain Bhopal	12	11	2023-11-20 10:48:18.402992	2023-11-20 11:43:07.989045	7	7	t	1
28	FEB - 2024 - Europe 	11	10	2023-11-27 00:55:52.996674	2023-11-27 03:50:27.406636	7	7	t	1
29	Bangalore & Dubai	10	9	2023-11-30 07:55:41.854616	2023-11-30 07:55:41.854616	9	\N	t	0
30	Feb 2024 western Europe	11	10	2023-12-06 22:59:18.007539	2024-01-03 04:43:33.847402	7	7	t	1
31	Eastern Europe 2024	10	9	2023-12-14 15:01:34.273775	2024-01-04 05:07:34.645426	7	7	t	1
32	Hyderabad 2024	4	3	2024-02-06 10:31:29.099538	2024-02-06 10:31:29.099538	7	\N	t	0
33	Blr / Mysore 2024	4	3	2024-02-06 10:55:07.445671	2024-02-06 10:55:07.445671	7	\N	t	0
\.


--
-- TOC entry 4245 (class 0 OID 16508)
-- Dependencies: 268
-- Data for Name: tour_currency_rates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tour_currency_rates (id, currency_type_lid, currency_rate, price, actual_price, tour_lid, created_at, updated_at, created_by, updated_by, active) FROM stdin;
2	3	0.930424	90.68	89.18	24	2023-10-15 05:08:20.778646	\N	1	\N	t
3	1	1	84.48	82.98	25	2023-10-20 00:55:45.835318	\N	1	\N	t
4	3	0.930424	90.68	89.18	28	2023-11-27 03:50:27.392347	\N	1	\N	t
5	3	0.91184	92.50	91	30	2023-12-06 23:29:42.609989	\N	1	\N	t
6	3	0.922	91.50	90	31	2023-12-17 05:20:33.349782	\N	1	\N	t
7	3	0.922	91.50	90	30	2023-12-17 05:34:34.504046	\N	1	\N	t
\.


--
-- TOC entry 4247 (class 0 OID 16516)
-- Dependencies: 270
-- Data for Name: tour_expenses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tour_expenses (id, tour_lid, expense_lid, pax_lid, pax_count, currency_lid, unit_price, nightly_recurring, daily_recurring, total_price, created_at, updated_at, created_by, updated_by, active, remark, recurring_nights, recurring_days) FROM stdin;
104	12	1	1	70	49	9755	f	f	682850	2023-10-03 11:23:45.162963	\N	7	\N	t	\N	\N	\N
105	12	1	2	3	49	9755	f	f	29265	2023-10-03 11:24:03.629866	\N	7	\N	t	\N	\N	\N
106	12	4	2	3	49	0	f	f	284351	2023-10-03 11:24:52.275755	\N	7	\N	t	\N	\N	\N
107	12	5	1	70	49	0	f	f	4316768	2023-10-03 11:25:31.645261	\N	7	\N	t	\N	\N	\N
108	12	6	1	70	49	0	f	f	134782	2023-10-03 11:26:03.777758	\N	7	\N	t	\N	\N	\N
109	12	8	1	70	49	0	f	f	47500	2023-10-03 11:27:24.797336	\N	7	\N	t	\N	\N	\N
117	15	10	1	56	49	700	f	f	39200	2023-10-04 05:20:20.149557	\N	7	\N	t	\N	\N	\N
118	15	10	2	3	49	700	f	f	2100	2023-10-04 05:20:36.606386	\N	7	\N	t	\N	\N	\N
119	15	10	4	2	49	700	f	f	1400	2023-10-04 05:20:46.722135	\N	7	\N	t	\N	\N	\N
120	15	3	1	56	49	300	f	f	16800	2023-10-04 05:21:57.983917	\N	7	\N	t	\N	\N	\N
121	15	3	2	3	49	300	f	f	900	2023-10-04 05:22:07.05691	\N	7	\N	t	\N	\N	\N
122	15	3	4	2	49	300	f	f	600	2023-10-04 05:22:16.733635	\N	7	\N	t	\N	\N	\N
125	15	14	1	56	49	0	f	f	2000	2023-10-04 05:24:21.660338	\N	7	\N	t	\N	\N	\N
126	15	17	1	56	49	150	f	f	8400	2023-10-04 05:25:34.343624	\N	7	\N	t	\N	\N	\N
127	15	2	1	56	49	500	f	t	392000	2023-10-04 05:26:14.325898	\N	7	\N	t	\N	\N	\N
128	15	2	2	3	49	500	f	t	21000	2023-10-04 05:26:28.561199	\N	7	\N	t	\N	\N	\N
129	15	2	4	2	49	500	f	t	14000	2023-10-04 05:26:39.603417	\N	7	\N	t	\N	\N	\N
130	15	13	1	56	49	0	f	f	50000	2023-10-04 05:27:35.374265	\N	7	\N	t	\N	\N	\N
131	15	7	1	56	49	200	f	f	11200	2023-10-04 05:28:25.115332	\N	7	\N	t	\N	\N	\N
132	16	5	1	62	3	0	f	f	48715	2023-10-04 06:42:14.828732	\N	9	\N	t	\N	\N	\N
133	16	2	1	62	3	0	f	f	14339	2023-10-04 06:43:41.666223	\N	9	\N	t	\N	\N	\N
134	16	6	1	62	3	0	f	f	15780	2023-10-04 06:44:11.38865	\N	9	\N	t	\N	\N	\N
135	16	7	1	62	3	0	f	f	6872	2023-10-04 06:45:18.676307	\N	9	\N	t	\N	\N	\N
148	17	3	1	56	49	354	f	f	19824	2023-10-05 07:10:51.372024	\N	8	8	t	\N	\N	\N
154	17	2	2	3	49	625	f	f	1875	2023-10-05 07:16:46.892846	\N	8	8	f	\N	\N	\N
116	15	6	1	56	49	9375	f	f	525000	2023-10-04 05:19:36.834952	\N	7	7	t	\N	\N	\N
155	17	2	4	2	49	625	f	f	1250	2023-10-05 07:17:00.811118	\N	8	8	f	\N	\N	\N
115	15	5	4	2	49	2792	t	f	72592	2023-10-04 05:19:08.98187	\N	7	7	t	\N	\N	\N
114	15	5	2	3	49	4942	t	f	192738	2023-10-04 05:18:30.688703	\N	7	7	t	\N	\N	\N
113	15	5	1	56	49	2410	t	f	1754480	2023-10-04 05:17:02.131146	\N	7	7	t	\N	\N	\N
151	17	15	1	56	49	1250	f	f	70000	2023-10-05 07:11:55.240209	\N	8	\N	t	\N	\N	\N
152	17	6	1	56	49	10200	f	f	571200	2023-10-05 07:13:19.935316	\N	8	\N	t	\N	\N	\N
137	17	4	2	3	49	1563	f	f	4689	2023-10-05 07:02:37.126733	\N	8	8	f	\N	\N	\N
138	17	4	4	2	49	1563	f	f	3126	2023-10-05 07:02:55.706492	\N	8	8	f	\N	\N	\N
140	17	10	2	3	49	63	f	f	189	2023-10-05 07:04:36.139018	\N	8	8	f	\N	\N	\N
141	17	10	4	2	49	63	f	f	126	2023-10-05 07:04:45.003363	\N	8	8	f	\N	\N	\N
139	17	10	1	56	49	826	f	f	46256	2023-10-05 07:04:12.349052	\N	8	8	t	\N	\N	\N
143	17	16	2	3	49	89	f	f	267	2023-10-05 07:05:52.921685	\N	8	8	f	\N	\N	\N
144	17	16	4	2	49	89	f	f	178	2023-10-05 07:06:12.157686	\N	8	8	f	\N	\N	\N
146	17	13	2	3	49	80	f	f	240	2023-10-05 07:09:52.503128	\N	8	8	f	\N	\N	\N
147	17	13	4	2	49	80	f	f	160	2023-10-05 07:10:00.354129	\N	8	8	f	\N	\N	\N
149	17	3	2	3	49	27	f	f	81	2023-10-05 07:11:06.894788	\N	8	8	f	\N	\N	\N
150	17	3	4	2	49	27	f	f	54	2023-10-05 07:11:13.464779	\N	8	8	f	\N	\N	\N
153	17	2	1	56	49	8250	f	f	462000	2023-10-05 07:16:08.429548	\N	8	8	t	\N	\N	\N
157	17	17	2	3	49	13	f	f	39	2023-10-05 07:17:45.448664	\N	8	8	f	\N	\N	\N
158	17	17	4	2	49	13	f	f	26	2023-10-05 07:17:54.936172	\N	8	8	f	\N	\N	\N
156	17	17	1	56	49	176	f	f	9856	2023-10-05 07:17:25.740831	\N	8	8	t	\N	\N	\N
161	17	7	4	2	49	27	f	f	54	2023-10-05 07:18:52.063815	\N	8	8	f	\N	\N	\N
160	17	7	2	3	49	27	f	f	81	2023-10-05 07:18:40.731665	\N	8	8	f	\N	\N	\N
159	17	7	1	56	49	354	f	f	19824	2023-10-05 07:18:24.834567	\N	8	8	t	\N	\N	\N
173	18	2	2	4	49	500	f	t	20000	2023-10-05 09:53:27.40354	\N	7	7	t	\N	\N	\N
167	18	5	2	4	49	12949	t	f	466164	2023-10-05 09:40:50.461665	\N	7	7	t	\N	\N	\N
136	17	4	1	56	49	18000	f	f	1008000	2023-10-05 07:01:15.364209	\N	8	7	t	\N	\N	\N
162	17	5	1	56	49	35000	f	f	1960000	2023-10-05 07:42:30.761911	\N	8	7	t	\N	\N	\N
169	18	6	1	66	49	0	f	f	440000	2023-10-05 09:50:18.54167	\N	7	\N	t	\N	\N	\N
170	18	10	1	66	49	700	f	f	46200	2023-10-05 09:50:50.771814	\N	7	\N	t	\N	\N	\N
171	18	10	2	4	49	800	f	f	3200	2023-10-05 09:51:05.917807	\N	7	\N	t	\N	\N	\N
172	18	10	4	2	49	800	f	f	1600	2023-10-05 09:51:15.665565	\N	7	\N	t	\N	\N	\N
165	18	4	4	2	49	17000	f	f	34000	2023-10-05 09:25:52.153332	\N	7	7	t	\N	\N	\N
110	15	4	1	56	49	15500	f	f	868000	2023-10-04 05:12:26.153967	\N	7	7	t	\N	\N	\N
112	15	4	4	2	49	15500	f	f	31000	2023-10-04 05:12:58.375216	\N	7	7	t	\N	\N	\N
111	15	4	2	3	49	15500	f	f	46500	2023-10-04 05:12:44.68149	\N	7	7	t	\N	\N	\N
168	18	5	4	2	49	5541	t	f	99738	2023-10-05 09:49:54.396587	\N	7	7	t	\N	\N	\N
124	15	16	1	56	49	500	f	f	28000	2023-10-04 05:23:50.083019	\N	7	7	t	\N	\N	\N
123	15	15	1	56	49	1000	f	f	56000	2023-10-04 05:23:27.179318	\N	7	7	t	\N	\N	\N
166	18	5	1	66	49	2259	t	f	1341846	2023-10-05 09:35:07.745972	\N	7	7	t	\N	\N	\N
145	17	13	1	56	49	900	f	f	50400	2023-10-05 07:07:16.523658	\N	8	7	t	\N	\N	\N
142	17	16	1	56	49	500	f	f	28000	2023-10-05 07:05:33.82151	\N	8	7	t	\N	\N	\N
174	18	2	4	2	49	500	f	t	10000	2023-10-05 09:53:40.527354	\N	7	7	t	\N	\N	\N
163	18	4	1	66	49	17000	f	f	1122000	2023-10-05 09:25:23.238871	\N	7	7	t	\N	\N	\N
164	18	4	2	4	49	17000	f	f	68000	2023-10-05 09:25:39.500925	\N	7	7	t	\N	\N	\N
175	18	3	1	66	49	300	f	f	19800	2023-10-05 09:53:58.8192	\N	7	\N	t	\N	\N	\N
176	18	3	2	4	49	300	f	f	1200	2023-10-05 09:54:20.152593	\N	7	\N	t	\N	\N	\N
177	18	3	4	2	49	300	f	f	600	2023-10-05 09:54:35.385695	\N	7	\N	t	\N	\N	\N
181	18	17	1	66	49	160	f	f	10560	2023-10-05 09:58:13.310533	\N	7	\N	t	\N	\N	\N
182	18	7	1	66	49	330	f	f	21780	2023-10-05 09:58:38.275736	\N	7	\N	t	\N	\N	\N
190	19	6	1	66	49	0	f	f	440000	2023-10-05 10:11:05.147753	\N	7	\N	t	\N	\N	\N
191	19	10	1	66	49	700	f	f	46200	2023-10-05 10:11:19.477777	\N	7	\N	t	\N	\N	\N
192	19	10	2	4	49	800	f	f	3200	2023-10-05 10:11:29.011326	\N	7	\N	t	\N	\N	\N
193	19	10	4	2	49	800	f	f	1600	2023-10-05 10:11:38.292918	\N	7	\N	t	\N	\N	\N
198	19	3	1	66	49	300	f	f	19800	2023-10-05 10:13:59.676463	\N	7	\N	t	\N	\N	\N
199	19	17	1	66	49	150	f	f	9900	2023-10-05 10:14:56.876782	\N	7	\N	t	\N	\N	\N
201	19	2	2	4	49	500	f	t	20000	2023-10-05 10:28:33.307472	\N	7	\N	t	\N	\N	\N
202	19	2	4	2	49	500	f	t	10000	2023-10-05 10:28:53.852223	\N	7	\N	t	\N	\N	\N
209	20	6	1	77	49	0	f	f	419580	2023-10-05 10:47:38.177181	\N	7	\N	t	\N	\N	\N
210	20	10	1	77	49	700	f	f	53900	2023-10-05 10:47:56.572005	\N	7	\N	t	\N	\N	\N
211	20	10	2	4	49	800	f	f	3200	2023-10-05 10:48:06.714748	\N	7	\N	t	\N	\N	\N
212	20	10	4	2	49	800	f	f	1600	2023-10-05 10:48:21.0501	\N	7	\N	t	\N	\N	\N
216	20	17	1	77	49	160	f	f	12320	2023-10-05 10:49:37.570598	\N	7	\N	t	\N	\N	\N
217	20	7	1	77	49	550	f	f	42350	2023-10-05 10:49:57.89089	\N	7	7	t	\N	\N	\N
219	20	3	1	77	49	330	f	f	25410	2023-10-05 10:51:17.582353	\N	7	\N	t	\N	\N	\N
246	23	5	2	3	49	3718	f	t	133848	2023-10-13 05:56:22.609886	\N	7	7	t	\N	\N	\N
221	22	4	1	63	49	98400	f	f	6199200	2023-10-06 04:44:58.655014	\N	7	\N	t	\N	\N	\N
222	22	4	2	2	49	98400	f	f	196800	2023-10-06 04:45:17.144168	\N	7	\N	t	\N	\N	\N
223	22	4	4	2	49	98400	f	f	196800	2023-10-06 04:45:30.042877	\N	7	\N	t	\N	\N	\N
224	22	1	1	63	49	14500	f	f	913500	2023-10-06 05:24:14.507925	\N	7	\N	t	\N	\N	\N
225	22	1	2	2	49	14500	f	f	29000	2023-10-06 05:24:26.256667	\N	7	\N	t	\N	\N	\N
226	22	1	4	2	49	14500	f	f	29000	2023-10-06 05:24:36.974365	\N	7	\N	t	\N	\N	\N
227	22	5	2	2	49	6450	t	f	129000	2023-10-06 05:29:42.110935	\N	7	\N	t	\N	\N	\N
228	22	5	4	2	49	6450	t	f	129000	2023-10-06 05:29:58.758428	\N	7	\N	t	\N	\N	\N
229	22	5	1	63	49	6450	t	f	4063500	2023-10-06 05:30:55.259781	\N	7	\N	t	\N	\N	\N
230	22	2	1	63	3	48	f	t	33264	2023-10-06 05:33:35.544682	\N	7	\N	t	\N	\N	\N
232	22	14	1	63	3	2	f	t	1386	2023-10-06 05:36:41.553419	\N	7	\N	t	\N	\N	\N
233	22	14	2	2	3	2	f	t	44	2023-10-06 05:36:59.9608	\N	7	\N	t	\N	\N	\N
234	22	13	1	63	3	0	f	f	1250	2023-10-06 05:38:15.157374	\N	7	\N	t	\N	\N	\N
235	22	15	4	2	3	50	f	t	1100	2023-10-06 05:40:51.259019	\N	7	\N	t	\N	\N	\N
236	22	10	1	63	49	800	f	f	50400	2023-10-06 05:41:45.498145	\N	7	\N	t	\N	\N	\N
237	22	10	2	2	49	1000	f	f	2000	2023-10-06 05:41:56.567241	\N	7	\N	t	\N	\N	\N
238	22	10	4	2	49	1000	f	f	2000	2023-10-06 05:42:08.398426	\N	7	\N	t	\N	\N	\N
187	19	5	1	66	49	2139	t	f	1270566	2023-10-05 10:09:17.129038	\N	7	7	t	\N	\N	\N
231	22	6	1	63	3	0	f	f	15180	2023-10-06 05:34:34.438124	\N	7	7	f	\N	\N	\N
239	22	6	1	63	3	0	f	f	15180	2023-10-06 05:44:17.084833	\N	7	\N	t	\N	\N	\N
180	18	15	4	2	49	2500	f	t	50000	2023-10-05 09:57:52.755288	\N	7	7	t	\N	\N	\N
179	18	13	1	66	49	758	f	f	50028	2023-10-05 09:56:22.565136	\N	7	7	f	\N	\N	\N
183	18	8	1	66	49	1000	f	f	66000	2023-10-05 09:59:17.990073	\N	7	7	t	\N	\N	\N
184	19	4	1	66	49	15000	f	f	990000	2023-10-05 10:08:01.669873	\N	7	7	t	\N	\N	\N
185	19	4	2	4	49	15000	f	f	60000	2023-10-05 10:08:12.520151	\N	7	7	t	\N	\N	\N
186	19	4	4	2	49	15000	f	f	30000	2023-10-05 10:08:22.801722	\N	7	7	t	\N	\N	\N
200	19	16	1	66	49	500	f	f	33000	2023-10-05 10:28:11.807331	\N	7	7	t	\N	\N	\N
196	19	2	1	66	49	500	f	t	330000	2023-10-05 10:12:51.097244	\N	7	7	t	\N	\N	\N
214	20	15	4	2	49	2500	f	t	55000	2023-10-05 10:49:07.79437	\N	7	7	t	\N	\N	\N
220	18	2	1	66	49	500	f	t	330000	2023-10-05 12:17:17.180597	\N	7	7	t	\N	\N	\N
245	23	5	1	56	49	2165	t	f	1333640	2023-10-13 05:55:29.518548	\N	7	7	t	\N	\N	\N
206	20	5	1	77	49	2891	t	f	2226070	2023-10-05 10:46:35.447141	\N	7	7	t	\N	\N	\N
189	19	5	4	2	49	6111	f	f	12222	2023-10-05 10:10:34.111756	\N	7	7	t	\N	\N	\N
194	19	13	1	66	49	1	f	f	66	2023-10-05 10:12:03.167672	\N	7	7	t	\N	\N	\N
240	17	4	2	3	49	18000	f	f	54000	2023-10-13 05:33:42.789045	\N	7	\N	t	\N	\N	\N
241	17	4	4	2	49	18000	f	f	36000	2023-10-13 05:33:55.062366	\N	7	\N	t	\N	\N	\N
242	23	4	1	56	49	18000	f	f	1008000	2023-10-13 05:54:16.665606	\N	7	\N	t	\N	\N	\N
243	23	4	2	3	49	18000	f	f	54000	2023-10-13 05:54:38.534043	\N	7	\N	t	\N	\N	\N
244	23	4	4	2	49	18000	f	f	36000	2023-10-13 05:54:49.092841	\N	7	\N	t	\N	\N	\N
249	23	3	2	3	49	40	f	t	1680	2023-10-13 05:58:02.637616	\N	7	\N	t	\N	\N	\N
250	23	3	4	2	49	40	f	t	1120	2023-10-13 05:58:15.862804	\N	7	\N	t	\N	\N	\N
253	23	7	2	3	49	500	f	f	1500	2023-10-13 05:59:36.943059	\N	7	\N	t	\N	\N	\N
254	23	7	4	2	49	500	f	f	1000	2023-10-13 05:59:45.897042	\N	7	\N	t	\N	\N	\N
255	23	10	1	56	49	700	f	f	39200	2023-10-13 06:00:03.804656	\N	7	\N	t	\N	\N	\N
248	23	3	1	56	49	550	f	f	30800	2023-10-13 05:57:25.080743	\N	7	7	t	\N	\N	\N
247	23	5	4	2	49	2272	t	f	49984	2023-10-13 05:56:50.670543	\N	7	7	t	\N	\N	\N
251	23	6	1	56	49	8200	f	f	459200	2023-10-13 05:58:52.5551	\N	7	7	t	\N	\N	\N
218	20	2	1	77	49	1	f	t	847	2023-10-05 10:51:03.252293	\N	7	7	f	\N	\N	\N
252	23	7	1	56	49	500	f	f	28000	2023-10-13 05:59:27.091963	\N	7	7	t	\N	\N	\N
204	20	4	2	4	49	20000	f	f	80000	2023-10-05 10:45:47.380471	\N	7	7	t	\N	\N	\N
205	20	4	4	2	49	20000	f	f	40000	2023-10-05 10:45:59.473903	\N	7	7	t	\N	\N	\N
203	20	4	1	77	49	20000	f	f	1540000	2023-10-05 10:45:32.832072	\N	7	7	t	\N	\N	\N
207	20	5	2	4	49	5927	f	f	23708	2023-10-05 10:46:56.631989	\N	7	7	t	\N	\N	\N
208	20	5	4	2	49	3495	t	f	69900	2023-10-05 10:47:11.362308	\N	7	7	t	\N	\N	\N
213	20	13	1	77	49	1	f	f	77	2023-10-05 10:48:48.325155	\N	7	7	t	\N	\N	\N
215	20	16	1	77	49	1000	f	f	77000	2023-10-05 10:49:22.075903	\N	7	7	t	\N	\N	\N
188	19	5	2	4	49	20889	t	f	752004	2023-10-05 10:10:17.033095	\N	7	7	t	\N	\N	\N
197	19	7	1	66	49	500	f	f	33000	2023-10-05 10:13:27.546244	\N	7	7	t	\N	\N	\N
178	18	13	1	66	49	1	f	f	66	2023-10-05 09:55:11.277742	\N	7	7	t	\N	\N	\N
195	19	15	4	2	49	2500	f	t	50000	2023-10-05 10:12:25.249522	\N	7	7	t	\N	\N	\N
256	23	10	2	3	49	800	f	f	2400	2023-10-13 06:00:13.854949	\N	7	\N	t	\N	\N	\N
257	23	10	4	2	49	800	f	f	1600	2023-10-13 06:00:22.44121	\N	7	\N	t	\N	\N	\N
259	23	17	1	56	49	155	f	f	8680	2023-10-13 06:00:54.109689	\N	7	\N	t	\N	\N	\N
260	23	13	1	56	49	800	f	f	44800	2023-10-13 06:01:54.666312	\N	7	\N	t	\N	\N	\N
262	24	4	1	50	49	80000	f	f	4000000	2023-10-15 04:45:08.20611	\N	7	\N	t	\N	\N	\N
263	24	4	4	2	49	80000	f	f	160000	2023-10-15 04:45:22.21082	\N	7	\N	t	\N	\N	\N
264	24	4	2	2	49	190000	f	f	380000	2023-10-15 04:46:02.375833	\N	7	\N	t	\N	\N	\N
266	24	5	2	2	3	1800	f	f	3600	2023-10-15 04:55:53.903196	\N	7	\N	t	\N	\N	\N
267	24	5	4	2	3	105	t	f	2100	2023-10-15 04:56:20.65424	\N	7	\N	t	\N	\N	\N
268	24	1	1	50	49	15000	f	f	750000	2023-10-15 04:56:53.318191	\N	7	\N	t	\N	\N	\N
269	24	1	2	2	49	15000	f	f	30000	2023-10-15 04:57:06.124605	\N	7	\N	t	\N	\N	\N
270	24	1	4	2	49	15000	f	f	30000	2023-10-15 04:57:16.647648	\N	7	\N	t	\N	\N	\N
271	24	2	1	50	3	50	f	t	27500	2023-10-15 04:57:49.367965	\N	7	\N	t	\N	\N	\N
272	24	2	2	2	3	50	f	t	1100	2023-10-15 04:58:04.398231	\N	7	\N	t	\N	\N	\N
273	24	2	4	2	3	50	f	t	1100	2023-10-15 04:58:18.670575	\N	7	\N	t	\N	\N	\N
274	24	3	1	50	3	1	f	t	550	2023-10-15 04:59:22.626012	\N	7	\N	t	\N	\N	\N
275	24	3	2	2	3	1	f	t	22	2023-10-15 04:59:35.558738	\N	7	\N	t	\N	\N	\N
276	24	3	4	2	3	1	f	f	2	2023-10-15 04:59:44.03601	\N	7	\N	t	\N	\N	\N
277	24	6	1	50	3	300	f	f	15000	2023-10-15 05:01:26.128292	\N	7	\N	t	\N	\N	\N
278	24	10	1	50	49	1000	f	f	50000	2023-10-15 05:01:55.913232	\N	7	\N	t	\N	\N	\N
279	24	10	2	2	49	1000	f	f	2000	2023-10-15 05:02:05.245601	\N	7	\N	t	\N	\N	\N
280	24	10	4	2	49	1000	f	f	2000	2023-10-15 05:02:13.7293	\N	7	\N	t	\N	\N	\N
281	24	14	1	50	3	2	f	t	1100	2023-10-15 05:02:46.551701	\N	7	\N	t	\N	\N	\N
282	24	14	2	2	3	2	f	t	44	2023-10-15 05:02:58.869553	\N	7	\N	t	\N	\N	\N
283	24	7	1	50	3	220	f	f	11000	2023-10-15 05:03:57.881276	\N	7	\N	t	\N	\N	\N
284	24	15	4	2	3	100	f	t	2200	2023-10-15 05:10:16.953939	\N	7	\N	t	\N	\N	\N
292	25	10	2	1	49	750	f	f	750	2023-10-20 00:46:24.724684	\N	7	\N	t	\N	\N	\N
293	25	10	4	1	49	750	f	f	750	2023-10-20 00:46:35.54886	\N	7	\N	t	\N	\N	\N
291	25	10	1	25	49	600	f	f	15000	2023-10-20 00:46:14.888505	\N	7	7	t	\N	\N	\N
294	25	16	1	25	49	1000	f	f	25000	2023-10-20 00:46:57.893853	\N	7	7	t	\N	\N	\N
258	23	16	1	56	49	1000	f	f	56000	2023-10-13 06:00:40.290707	\N	7	7	t	\N	\N	\N
300	23	2	2	3	49	500	t	f	19500	2023-10-20 06:07:00.5144	\N	7	7	f	\N	\N	\N
301	23	2	4	2	49	500	t	f	13000	2023-10-20 06:07:11.206256	\N	7	7	f	\N	\N	\N
299	23	2	1	56	49	500	t	f	364000	2023-10-20 06:06:47.728346	\N	7	7	f	\N	\N	\N
288	25	1	1	25	1	35	f	f	875	2023-10-20 00:45:21.072165	\N	7	7	t	\N	\N	\N
290	25	1	4	1	1	35	f	f	35	2023-10-20 00:45:42.286459	\N	7	7	t	\N	\N	\N
285	25	4	1	25	49	66000	f	f	1650000	2023-10-20 00:43:51.014956	\N	7	7	t	\N	\N	\N
287	25	4	4	1	49	66000	f	f	66000	2023-10-20 00:44:16.464029	\N	7	7	t	\N	\N	\N
296	25	5	1	25	1	270	f	f	6750	2023-10-20 00:48:27.162517	\N	7	7	t	\N	\N	\N
297	25	5	2	1	1	662	f	f	662	2023-10-20 00:48:41.442088	\N	7	7	t	\N	\N	\N
298	25	5	4	1	1	200	f	f	200	2023-10-20 00:48:55.299748	\N	7	7	t	\N	\N	\N
295	25	15	4	1	1	50	f	t	300	2023-10-20 00:47:49.175573	\N	7	7	t	\N	\N	\N
286	25	4	2	2	49	66000	f	f	132000	2023-10-20 00:44:04.593067	\N	7	7	t	\N	\N	\N
289	25	1	2	2	1	35	f	f	70	2023-10-20 00:45:31.245281	\N	7	7	t	\N	\N	\N
302	20	2	1	77	49	500	f	t	423500	2023-10-20 07:46:04.684703	\N	7	\N	t	\N	\N	\N
303	20	2	2	4	49	500	f	t	22000	2023-10-20 07:46:17.080749	\N	7	\N	t	\N	\N	\N
261	23	15	4	2	49	2000	f	t	48000	2023-10-13 06:02:40.660806	\N	7	7	t	\N	\N	\N
305	23	2	1	56	49	500	f	t	336000	2023-10-20 12:39:37.624557	\N	7	\N	t	\N	\N	\N
306	23	2	2	3	49	500	f	t	18000	2023-10-20 12:39:50.496486	\N	7	\N	t	\N	\N	\N
307	23	2	4	2	49	500	f	t	12000	2023-10-20 12:40:01.005406	\N	7	\N	t	\N	\N	\N
304	20	2	4	2	49	500	f	t	11000	2023-10-20 07:46:27.87224	\N	7	7	t	\N	\N	\N
265	24	5	1	50	3	120	t	f	60000	2023-10-15 04:53:58.147532	\N	7	7	t	\N	\N	\N
308	26	4	1	73	49	20000	f	f	1460000	2023-11-20 09:04:18.679295	\N	7	\N	t	Indigo 5122 / 5227	0	0
309	26	4	2	4	49	20000	f	f	80000	2023-11-20 09:04:18.679295	\N	7	\N	t	Indigo 5122 / 5227	0	0
310	26	4	4	1	49	20000	f	f	20000	2023-11-20 09:04:18.679295	\N	7	\N	t	Indigo 5122 / 5227	0	0
311	26	5	1	73	49	2734	t	f	997910	2023-11-20 09:15:00.889202	\N	7	\N	t	Monotel	5	0
312	26	5	2	4	49	5300	t	f	106000	2023-11-20 09:24:34.311808	\N	7	\N	t	Monotel	5	0
313	26	5	4	1	49	6300	t	f	31500	2023-11-20 09:26:04.239044	\N	7	\N	t	monotel	5	0
314	26	5	1	73	49	3333	t	f	486618	2023-11-20 09:38:31.134839	\N	7	\N	t	Annapurna - Bhishnupur	2	0
315	26	5	2	4	49	6150	t	f	49200	2023-11-20 09:40:06.811494	\N	7	\N	t	Annapurna - Bhishunpur	2	0
316	26	5	1	73	49	2850	t	f	624150	2023-11-20 09:42:46.610626	\N	7	\N	t	The Creek - Shantiniketan	3	0
317	26	5	2	4	49	7800	t	f	93600	2023-11-20 10:15:17.410892	\N	7	\N	t	The Creek - Stantiniketan	3	0
318	26	2	1	73	49	400	f	t	321200	2023-11-20 10:16:35.359991	\N	7	\N	t	lunches	0	11
319	26	2	2	4	49	400	f	t	17600	2023-11-20 10:16:35.359991	\N	7	\N	t	lunches	0	11
320	26	2	4	1	49	400	f	t	4400	2023-11-20 10:16:35.359991	\N	7	\N	t	lunches	0	11
321	26	6	1	73	49	0	f	f	283500	2023-11-20 10:17:16.91945	\N	7	7	t		0	0
322	26	3	1	73	49	40	f	t	32120	2023-11-20 10:36:10.238852	\N	7	\N	t	3 bottles	0	11
323	26	3	2	4	49	40	f	t	1760	2023-11-20 10:36:10.238852	\N	7	\N	t	3 bottles	0	11
324	26	3	4	1	49	40	f	t	440	2023-11-20 10:36:10.238852	\N	7	\N	t	3 bottles	0	11
325	26	7	1	73	49	1000	f	f	73000	2023-11-20 10:37:04.580797	\N	7	\N	t	all	0	0
326	26	7	2	4	49	1000	f	f	4000	2023-11-20 10:37:04.580797	\N	7	\N	t	all	0	0
327	26	7	4	1	49	1000	f	f	1000	2023-11-20 10:37:04.580797	\N	7	\N	t	all	0	0
328	26	15	4	1	49	2000	f	t	22000	2023-11-20 10:37:39.042222	\N	7	\N	t	2	0	11
329	26	8	1	73	49	1000	f	f	73000	2023-11-20 10:38:12.849383	\N	7	\N	t		0	0
330	26	10	1	73	49	400	f	f	29200	2023-11-20 10:41:48.48516	\N	7	\N	t	all	0	0
331	26	10	2	4	49	400	f	f	1600	2023-11-20 10:41:48.48516	\N	7	\N	t	all	0	0
332	26	10	4	1	49	400	f	f	400	2023-11-20 10:41:48.48516	\N	7	\N	t	all	0	0
333	27	4	1	50	49	14356	f	f	717800	2023-11-20 10:51:50.243581	\N	7	\N	t	Indigo 5181 / 826	0	0
334	27	4	2	3	49	14356	f	f	43068	2023-11-20 10:51:50.243581	\N	7	\N	t	Indigo 5181 / 826	0	0
335	27	4	4	1	49	14356	f	f	14356	2023-11-20 10:51:50.243581	\N	7	\N	t	Indigo 5181 / 826	0	0
336	27	2	1	50	49	500	f	t	300000	2023-11-20 10:52:36.727746	\N	7	\N	t	all lunches	0	12
337	27	2	2	3	49	500	f	t	18000	2023-11-20 10:52:36.727746	\N	7	\N	t	all lunches	0	12
338	27	2	4	1	49	500	f	t	6000	2023-11-20 10:52:36.727746	\N	7	\N	t	all lunches	0	12
339	27	3	1	50	49	40	f	t	24000	2023-11-20 10:53:15.317026	\N	7	\N	t	3 bottles	0	12
340	27	3	2	3	49	40	f	t	1440	2023-11-20 10:53:15.317026	\N	7	\N	t	3 bottles	0	12
341	27	3	4	1	49	40	f	t	480	2023-11-20 10:53:15.317026	\N	7	\N	t	3 bottles	0	12
342	27	5	1	50	49	2725	t	f	272500	2023-11-20 10:56:43.970029	\N	7	\N	t	Ujjai - Rudraksh	2	0
343	27	5	2	3	49	5000	t	f	30000	2023-11-20 10:57:50.490372	\N	7	\N	t	Ujjain- Rudraksh	2	0
344	27	5	4	1	49	6000	t	f	12000	2023-11-20 10:58:29.52799	\N	7	\N	t	Ujjain - Rudraksh	2	0
345	27	5	1	50	49	2145	t	f	429000	2023-11-20 10:59:54.066307	\N	7	\N	t	Bhopal - Kanha Palm	4	0
346	27	5	2	3	49	3600	t	f	43200	2023-11-20 11:00:34.140711	\N	7	\N	t	Bhopal - KanhaPalm	4	0
347	27	5	4	1	49	4500	t	f	18000	2023-11-20 11:01:37.058639	\N	7	\N	t	Bhopal - Kanha	4	0
348	27	5	1	50	49	2850	t	f	712500	2023-11-20 11:15:42.053918	\N	7	\N	t	Indore - Eifottel	5	0
349	27	5	2	3	49	2850	t	f	42750	2023-11-20 11:15:42.053918	\N	7	\N	t	Indore - Eifottel	5	0
350	27	5	4	1	49	2850	t	f	14250	2023-11-20 11:15:42.053918	\N	7	\N	t	Indore - Eifottel	5	0
351	27	6	1	50	49	0	f	f	358400	2023-11-20 11:20:36.660491	\N	7	\N	t		0	0
352	27	10	1	50	49	300	f	f	15000	2023-11-20 11:21:17.05678	\N	7	\N	t		0	0
353	27	10	2	3	49	300	f	f	900	2023-11-20 11:21:17.05678	\N	7	\N	t		0	0
354	27	10	4	1	49	300	f	f	300	2023-11-20 11:21:17.05678	\N	7	\N	t		0	0
355	28	4	1	45	49	85000	f	f	3825000	2023-11-27 00:58:55.094891	\N	7	\N	t	Etihad	0	0
356	28	4	2	2	49	85000	f	f	170000	2023-11-27 00:58:55.094891	\N	7	\N	t	Etihad	0	0
357	28	4	4	2	49	85000	f	f	170000	2023-11-27 00:58:55.094891	\N	7	\N	t	Etihad	0	0
358	28	1	1	45	49	15000	f	f	675000	2023-11-27 00:59:31.669176	\N	7	\N	t	Germany	0	0
360	28	1	4	2	49	15000	f	f	30000	2023-11-27 00:59:31.669176	\N	7	\N	t	Germany	0	0
361	28	2	1	45	3	50	t	f	22500	2023-11-27 01:01:23.876514	\N	7	\N	t	Lunches & Dinner @ 25 euros	10	0
362	28	2	2	2	3	50	t	f	1000	2023-11-27 01:01:23.876514	\N	7	\N	t	Lunches & Dinner @ 25 euros	10	0
363	28	2	4	2	3	50	t	f	1000	2023-11-27 01:01:23.876514	\N	7	\N	t	Lunches & Dinner @ 25 euros	10	0
365	28	5	2	2	3	90	t	f	1800	2023-11-27 01:03:21.274136	\N	7	\N	t	8 nights for 175 euros	10	0
366	28	5	4	2	3	90	t	f	1800	2023-11-27 01:03:21.274136	\N	7	\N	t	8 nights for 175 euros	10	0
367	28	5	1	45	3	200	t	f	18000	2023-11-27 01:04:09.730552	\N	7	\N	t	Lucerne	2	0
368	28	5	2	2	3	200	t	f	800	2023-11-27 01:04:09.730552	\N	7	\N	t	Lucerne	2	0
369	28	5	4	2	3	200	t	f	800	2023-11-27 01:04:09.730552	\N	7	\N	t	Lucerne	2	0
364	28	5	1	45	3	90	t	f	32400	2023-11-27 01:03:21.274136	\N	7	7	t	8 nights for 175 euros	10	0
370	28	3	1	45	3	2	f	t	990	2023-11-27 01:07:18.084935	\N	7	\N	t	2 euro per day	0	11
371	28	3	2	2	3	2	f	t	44	2023-11-27 01:07:18.084935	\N	7	\N	t	2 euro per day	0	11
372	28	3	4	2	3	2	f	t	44	2023-11-27 01:07:18.084935	\N	7	\N	t	2 euro per day	0	11
373	28	6	1	45	3	0	f	f	12000	2023-11-27 01:07:55.052985	\N	7	\N	t		0	0
374	28	7	1	45	3	200	f	f	9000	2023-11-27 01:08:34.745075	\N	7	\N	t		0	0
375	28	7	2	2	3	200	f	f	400	2023-11-27 01:08:34.745075	\N	7	\N	t		0	0
376	28	7	4	2	3	200	f	f	400	2023-11-27 01:08:34.745075	\N	7	\N	t		0	0
377	28	15	1	45	3	0	f	f	1100	2023-11-27 01:09:47.873476	\N	7	\N	t	one person 100 euros per day	0	0
378	28	14	1	45	3	2	f	t	990	2023-11-27 01:10:18.750273	\N	7	\N	t		0	11
379	28	14	2	2	3	2	f	t	44	2023-11-27 01:10:18.750273	\N	7	\N	t		0	11
380	28	10	1	45	49	1000	f	f	45000	2023-11-27 03:49:12.82262	\N	7	\N	t		0	0
381	28	10	2	2	49	1000	f	f	2000	2023-11-27 03:49:12.82262	\N	7	\N	t		0	0
382	28	10	4	2	49	1000	f	f	2000	2023-11-27 03:49:12.82262	\N	7	\N	t		0	0
383	28	8	1	45	49	5000	f	f	225000	2023-11-27 03:49:41.598987	\N	7	\N	t		0	0
384	29	5	8	20	49	18333	t	f	3299940	2023-12-01 02:04:01.506305	\N	9	\N	t		9	0
385	29	1	8	20	1	90	f	f	1800	2023-12-01 02:04:39.234624	\N	9	\N	t		0	0
359	28	1	2	3	49	15000	f	f	45000	2023-11-27 00:59:31.669176	\N	7	7	t	Germany	0	0
387	30	1	2	3	49	15000	f	f	45000	2023-12-06 23:01:52.39566	\N	7	\N	t	Germany / Belgium	0	0
388	30	1	4	2	49	15000	f	f	30000	2023-12-06 23:01:52.39566	\N	7	\N	t	Germany / Belgium	0	0
393	30	2	2	3	3	50	f	t	1650	2023-12-06 23:05:08.882614	\N	7	\N	t	25 euros per meal	0	11
394	30	2	4	2	3	50	f	t	1100	2023-12-06 23:05:08.882614	\N	7	\N	t	25 euros per meal	0	11
399	30	3	2	3	3	2	f	t	66	2023-12-06 23:07:43.70613	\N	7	\N	t	2 euros per person	0	11
400	30	3	4	2	3	2	f	t	44	2023-12-06 23:07:43.70613	\N	7	\N	t	2 euros per person	0	11
403	30	7	2	3	3	200	f	f	600	2023-12-06 23:10:17.216958	\N	7	\N	t	200 euros per person	0	0
404	30	7	4	2	3	200	f	f	400	2023-12-06 23:10:17.216958	\N	7	\N	t	200 euros per person	0	0
407	30	10	2	3	49	1000	f	f	3000	2023-12-06 23:11:48.471824	\N	7	\N	t	1000	0	0
408	30	10	4	2	49	1000	f	f	2000	2023-12-06 23:11:48.471824	\N	7	\N	t	1000	0	0
410	30	14	2	3	3	2	f	t	66	2023-12-06 23:12:31.315335	\N	7	\N	t	2 euros per day	0	11
396	30	5	2	2	3	175	t	f	3500	2023-12-06 23:06:46.155428	\N	7	7	t	average  175 euros per night	10	0
386	30	1	1	49	49	15000	f	f	735000	2023-12-06 23:01:52.39566	\N	7	7	t	Germany / Belgium	0	0
392	30	2	1	49	3	50	f	t	26950	2023-12-06 23:05:08.882614	\N	7	7	t	25 euros per meal	0	11
413	31	1	2	2	49	18500	f	f	37000	2023-12-14 15:04:56.737598	\N	7	\N	t	ODMV	0	0
414	31	1	4	2	49	18500	f	f	37000	2023-12-14 15:04:56.737598	\N	7	\N	t	ODMV	0	0
419	31	3	2	2	3	2	f	t	40	2023-12-14 15:06:49.807362	\N	7	\N	t	2 euro per person	0	10
420	31	3	4	2	3	2	f	t	40	2023-12-14 15:06:49.807362	\N	7	\N	t	2 euro per person	0	10
429	31	10	2	2	49	1000	f	f	2000	2023-12-14 15:12:21.472359	\N	7	\N	t	1000	0	0
430	31	10	4	2	49	1000	f	f	2000	2023-12-14 15:12:21.472359	\N	7	\N	t	1000	0	0
432	31	14	2	2	3	2	f	t	40	2023-12-14 15:13:06.847958	\N	7	\N	t	2 euro pp day	0	10
433	31	14	4	2	3	2	f	t	40	2023-12-14 15:13:06.847958	\N	7	\N	t	2 euro pp day	0	10
435	31	7	2	2	3	200	f	f	400	2023-12-14 15:14:55.221391	\N	7	\N	t	200 with guide	0	0
436	31	7	4	2	3	200	f	f	400	2023-12-14 15:14:55.221391	\N	7	\N	t	200 with guide	0	0
437	31	8	1	38	49	5000	f	f	190000	2023-12-14 15:15:49.113669	\N	7	\N	t	5000	0	0
398	30	3	1	49	3	2	f	t	1078	2023-12-06 23:07:43.70613	\N	7	7	t	2 euros per person	0	11
426	31	5	4	2	3	110	t	f	1980	2023-12-14 15:09:52.866886	\N	7	7	t	110 euro PP	9	0
405	30	8	1	49	3	0	f	f	8500	2023-12-06 23:11:14.687048	\N	7	7	t	consultation fees	0	0
406	30	10	1	49	49	1000	f	f	49000	2023-12-06 23:11:48.471824	\N	7	7	t	1000	0	0
409	30	14	1	49	3	2	f	t	1078	2023-12-06 23:12:31.315335	\N	7	7	t	2 euros per day	0	11
411	30	15	1	49	3	0	f	f	110	2023-12-06 23:14:19.600115	\N	7	7	t	75 euros per day	0	0
389	30	4	1	49	49	80000	f	f	3920000	2023-12-06 23:03:06.68848	\N	7	7	t	Etihad	0	0
423	31	4	4	2	49	72000	f	f	144000	2023-12-14 15:08:30.669022	\N	7	7	t	LH & LH	0	0
422	31	4	2	2	49	72000	f	f	144000	2023-12-14 15:08:30.669022	\N	7	7	t	LX & LH	0	0
421	31	4	1	40	49	72000	f	f	2880000	2023-12-14 15:08:30.669022	\N	7	7	t	LX & LH	0	0
425	31	5	2	2	3	200	t	f	3600	2023-12-14 15:09:52.866886	\N	7	7	t	110 euro PP	9	0
390	30	4	2	2	49	95000	f	f	190000	2023-12-06 23:03:06.68848	\N	7	7	t	Etihad	0	0
412	31	1	1	40	49	18500	f	f	740000	2023-12-14 15:04:56.737598	\N	7	7	t	ODMV	0	0
424	31	5	1	40	3	100	t	f	36000	2023-12-14 15:09:52.866886	\N	7	7	t	100 euro PP	9	0
427	31	6	1	40	3	0	f	f	13894.74	2023-12-14 15:11:01.454397	\N	7	7	t		0	0
434	31	7	1	40	3	200	f	f	8000	2023-12-14 15:14:55.221391	\N	7	7	t	200 with guide	0	0
391	30	4	4	2	49	90000	f	f	180000	2023-12-06 23:03:06.68848	\N	7	7	t	Etihad	0	0
397	30	5	4	2	3	160	t	f	3200	2023-12-06 23:06:46.155428	\N	7	7	t	average  125 euros per night	10	0
395	30	5	1	49	3	100	t	f	49000	2023-12-06 23:06:46.155428	\N	7	7	t	average  100 euros per night	10	0
401	30	6	1	49	3	0	f	f	14074.47	2023-12-06 23:09:23.264937	\N	7	7	t		0	0
402	30	7	1	49	3	150	f	f	7350	2023-12-06 23:10:17.216958	\N	7	7	t	150 euros per person	0	0
415	31	2	1	40	3	45	f	t	18000	2023-12-14 15:06:04.316473	\N	7	7	t	22 euro	0	10
416	31	2	2	2	3	45	f	t	900	2023-12-14 15:06:04.316473	\N	7	7	t	22 euro	0	10
417	31	2	4	2	3	45	f	t	900	2023-12-14 15:06:04.316473	\N	7	7	t	22 euro	0	10
418	31	3	1	40	3	2	f	t	800	2023-12-14 15:06:49.807362	\N	7	7	t	2 euro per person	0	10
428	31	10	1	40	49	1000	f	f	40000	2023-12-14 15:12:21.472359	\N	7	7	t	1000	0	0
431	31	14	1	40	3	2	f	t	800	2023-12-14 15:13:06.847958	\N	7	7	t	2 euro pp day	0	10
438	31	15	1	40	3	0	f	f	1000	2023-12-14 15:16:50.775215	\N	7	7	t	75	0	0
439	31	8	1	40	49	5000	f	f	200000	2024-01-04 05:06:52.718113	\N	7	\N	t	5000	0	0
448	32	8	4	2	49	1000	f	f	2000	2024-02-06 10:39:05.412772	\N	7	\N	t		0	0
455	32	3	4	2	49	150	f	f	300	2024-02-06 10:42:51.495695	\N	7	\N	t		0	0
458	32	10	4	2	49	250	f	f	500	2024-02-06 10:43:30.685086	\N	7	\N	t		0	0
440	32	4	1	70	49	9500	f	f	665000	2024-02-06 10:33:55.359493	\N	7	7	t		0	0
444	32	5	2	2	49	4500	t	f	27000	2024-02-06 10:37:05.593892	\N	7	7	t		3	0
447	32	8	2	2	49	1000	f	f	2000	2024-02-06 10:39:05.412772	\N	7	7	t		0	0
446	32	8	1	70	49	1000	f	f	70000	2024-02-06 10:39:05.412772	\N	7	7	t		0	0
457	32	10	2	2	49	250	f	f	500	2024-02-06 10:43:30.685086	\N	7	7	t		0	0
456	32	10	1	70	49	250	f	f	17500	2024-02-06 10:43:30.685086	\N	7	7	t		0	0
449	32	6	1	70	49	0	f	f	112000	2024-02-06 10:41:11.854429	\N	7	7	t		0	0
452	32	2	4	2	49	500	f	f	1000	2024-02-06 10:42:03.331593	\N	7	7	t		0	0
451	32	2	2	2	49	500	f	f	1000	2024-02-06 10:42:03.331593	\N	7	7	t		0	0
454	32	3	2	2	49	150	f	f	300	2024-02-06 10:42:51.495695	\N	7	7	t		0	0
453	32	3	1	70	49	150	f	f	10500	2024-02-06 10:42:51.495695	\N	7	7	t		0	0
442	32	4	4	2	49	9500	f	f	19000	2024-02-06 10:33:55.359493	\N	7	7	t		0	0
441	32	4	2	2	49	9500	f	f	19000	2024-02-06 10:33:55.359493	\N	7	7	t		0	0
461	32	7	4	2	49	1000	f	f	2000	2024-02-06 10:51:28.995627	\N	7	\N	t		0	0
462	33	2	1	80	49	2000	f	f	160000	2024-02-06 10:56:32.987322	\N	7	\N	t		0	0
463	33	2	2	5	49	2000	f	f	10000	2024-02-06 10:56:32.987322	\N	7	\N	t		0	0
464	33	2	4	2	49	2000	f	f	4000	2024-02-06 10:56:32.987322	\N	7	\N	t		0	0
465	33	4	1	80	49	10500	f	f	840000	2024-02-06 10:57:01.472873	\N	7	\N	t		0	0
466	33	4	2	5	49	10500	f	f	52500	2024-02-06 10:57:01.472873	\N	7	\N	t		0	0
467	33	4	4	2	49	10500	f	f	21000	2024-02-06 10:57:01.472873	\N	7	\N	t		0	0
468	33	3	1	80	49	150	f	f	12000	2024-02-06 10:57:24.896563	\N	7	\N	t		0	0
469	33	3	2	5	49	150	f	f	750	2024-02-06 10:57:24.896563	\N	7	\N	t		0	0
470	33	3	4	2	49	150	f	f	300	2024-02-06 10:57:24.896563	\N	7	\N	t		0	0
471	33	8	1	80	49	1000	f	f	80000	2024-02-06 10:58:26.003248	\N	7	\N	t		0	0
472	33	8	2	5	49	1000	f	f	5000	2024-02-06 10:58:26.003248	\N	7	\N	t		0	0
473	33	8	4	2	49	1000	f	f	2000	2024-02-06 10:58:26.003248	\N	7	\N	t		0	0
474	33	10	1	80	49	250	f	f	20000	2024-02-06 10:58:59.115693	\N	7	\N	t		0	0
475	33	10	2	5	49	250	f	f	1250	2024-02-06 10:58:59.115693	\N	7	\N	t		0	0
476	33	10	4	2	49	250	f	f	500	2024-02-06 10:58:59.115693	\N	7	\N	t		0	0
477	33	7	1	80	49	1000	f	f	80000	2024-02-06 10:59:26.196726	\N	7	\N	t		0	0
478	33	7	2	5	49	1000	f	f	5000	2024-02-06 10:59:26.196726	\N	7	\N	t		0	0
479	33	7	4	2	49	1000	f	f	2000	2024-02-06 10:59:26.196726	\N	7	\N	t		0	0
480	33	5	1	80	49	3100	t	f	744000	2024-02-06 11:01:13.16614	\N	7	\N	t		3	0
481	33	5	2	5	49	3100	t	f	46500	2024-02-06 11:01:13.16614	\N	7	\N	t		3	0
482	33	5	4	2	49	3100	t	f	18600	2024-02-06 11:01:13.16614	\N	7	\N	t		3	0
443	32	5	1	70	49	2600	t	f	546000	2024-02-06 10:37:05.593892	\N	7	7	t		3	0
460	32	7	2	2	49	1000	f	f	2000	2024-02-06 10:51:28.995627	\N	7	7	t		0	0
445	32	5	4	2	49	3500	t	f	21000	2024-02-06 10:37:05.593892	\N	7	7	t		3	0
459	32	7	1	70	49	1000	f	f	70000	2024-02-06 10:51:28.995627	\N	7	7	t		0	0
450	32	2	1	70	49	500	f	f	35000	2024-02-06 10:42:03.331593	\N	7	7	t		0	0
\.


--
-- TOC entry 4250 (class 0 OID 16525)
-- Dependencies: 273
-- Data for Name: tour_margin; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tour_margin (id, tour_lid, margin, created_at, updated_at, created_by, updated_by, active) FROM stdin;
7	12	13	2023-10-03 11:27:57.771827	2023-10-03 11:44:43.034292	7	7	t
8	15	11.5	2023-10-04 05:28:57.710451	2023-10-05 09:16:36.497078	7	7	t
10	18	11.5	2023-10-05 09:59:42.580053	\N	7	\N	t
11	19	11.5	2023-10-05 10:15:29.664666	\N	7	\N	t
12	20	11.5	2023-10-05 10:52:02.800231	\N	7	\N	t
13	22	1	2023-10-06 05:44:57.561943	\N	7	\N	t
9	17	11.5	2023-10-05 07:19:17.506708	2023-10-13 05:50:19.143081	8	7	t
14	23	11.5	2023-10-13 06:03:10.48879	\N	7	\N	t
15	24	6.5	2023-10-15 05:05:38.687373	\N	7	\N	t
16	25	11	2023-10-20 00:50:27.029711	\N	7	\N	t
17	26	10	2023-11-20 10:17:52.512686	2023-11-20 10:33:44.880733	7	7	t
18	27	1	2023-11-20 11:16:11.416633	\N	7	\N	t
19	28	6	2023-11-27 01:10:49.91945	2023-11-27 10:48:35.546208	7	7	t
21	31	1	2023-12-14 15:17:22.273113	2023-12-17 05:19:23.794839	7	7	t
20	30	1	2023-12-06 23:15:07.515336	2023-12-17 05:31:34.560856	7	7	t
22	32	10	2024-02-06 10:44:45.335965	2024-02-06 10:51:44.899932	7	7	t
23	33	10	2024-02-06 11:01:36.4034	\N	7	\N	t
\.


--
-- TOC entry 4252 (class 0 OID 16533)
-- Dependencies: 275
-- Data for Name: tour_passengers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tour_passengers (id, tour_lid, pax_type_lid, no_of_passengers, is_payable, payment_percentage, payment_amount, occupancy_preference, created_at, updated_at, created_by, updated_by, active) FROM stdin;
26	12	1	70	t	0	0	2	2023-10-03 11:21:45.424731	\N	7	7	f
25	12	2	3	f	0	0	1	2023-10-03 11:20:10.120036	\N	7	7	f
28	12	2	3	f	0	0	1	2023-10-03 11:41:51.333569	\N	7	7	t
27	12	1	70	t	100	0	2	2023-10-03 11:41:34.591751	\N	7	7	t
29	13	1	50	t	0	0	2	2023-10-03 12:21:41.74188	\N	7	\N	t
30	15	1	56	t	100	0	2	2023-10-04 05:10:49.047859	\N	7	\N	t
31	15	2	3	f	0	0	1	2023-10-04 05:11:13.845646	\N	7	\N	t
32	15	4	2	f	0	0	2	2023-10-04 05:11:41.608323	\N	7	\N	t
82	32	4	2	f	0	0	2	2024-02-06 10:32:36.367605	\N	7	\N	t
34	16	2	2	f	0	0	2	2023-10-04 06:39:57.776873	\N	9	\N	t
35	16	4	2	f	0	0	1	2023-10-04 06:40:42.296444	\N	9	\N	t
37	17	2	3	f	0	0	1	2023-10-05 06:59:39.542729	\N	8	8	t
38	17	4	2	f	0	0	2	2023-10-05 07:00:04.593549	\N	8	8	t
36	17	1	56	t	0	41038	2	2023-10-05 06:58:07.887644	\N	8	8	t
39	18	1	66	t	100	0	3	2023-10-05 09:23:37.964819	\N	7	\N	t
40	18	2	4	f	0	0	1	2023-10-05 09:23:58.919689	\N	7	\N	t
41	18	4	2	f	0	0	2	2023-10-05 09:24:27.442725	\N	7	\N	t
42	19	1	66	t	100	0	3	2023-10-05 10:01:47.667364	\N	7	\N	t
43	19	2	4	f	0	0	1	2023-10-05 10:02:05.082672	\N	7	\N	t
44	19	4	2	f	0	0	2	2023-10-05 10:02:24.042461	\N	7	\N	t
45	20	1	77	t	100	0	3	2023-10-05 10:36:09.502773	\N	7	\N	t
46	20	2	4	f	0	0	1	2023-10-05 10:36:24.285515	\N	7	\N	t
47	20	4	2	f	0	0	2	2023-10-05 10:36:41.377496	\N	7	\N	t
48	21	1	64	t	100	0	2	2023-10-05 12:44:21.64735	\N	11	\N	t
50	21	4	2	f	0	0	2	2023-10-05 12:45:52.362112	\N	11	\N	t
49	21	2	2	f	0	0	1	2023-10-05 12:45:07.853817	\N	11	11	t
51	22	1	63	t	100	0	2	2023-10-06 04:38:54.137467	\N	7	\N	t
52	22	2	2	f	0	0	1	2023-10-06 04:39:09.930162	\N	7	\N	t
53	22	4	2	f	0	0	2	2023-10-06 04:39:25.926504	\N	7	\N	t
55	23	2	3	f	0	0	1	2023-10-13 05:53:27.713293	\N	7	\N	t
56	23	4	2	f	0	0	2	2023-10-13 05:53:45.577608	\N	7	\N	t
54	23	1	56	t	100	0	3	2023-10-13 05:53:04.568532	\N	7	7	t
57	24	1	50	t	100	0	2	2023-10-15 04:42:35.102255	\N	7	\N	t
58	24	2	2	f	0	0	1	2023-10-15 04:42:59.605775	\N	7	\N	t
59	24	4	2	f	0	0	2	2023-10-15 04:43:15.462135	\N	7	\N	t
83	33	1	80	t	100	0	3	2024-02-06 10:55:37.935947	\N	7	\N	t
33	16	1	63	t	0	778	31	2023-10-04 06:39:12.545264	\N	9	9	t
62	25	4	1	f	0	0	1	2023-10-20 00:43:07.024748	\N	7	\N	t
84	33	2	5	f	0	0	2	2024-02-06 10:55:52.241702	\N	7	\N	t
60	25	1	25	t	100	0	3	2023-10-20 00:42:23.980274	\N	7	7	t
85	33	4	2	f	0	0	2	2024-02-06 10:56:02.444012	\N	7	\N	t
61	25	2	2	f	0	0	1	2023-10-20 00:42:45.632152	\N	7	7	t
80	32	1	70	t	100	0	3	2024-02-06 10:32:10.458418	\N	7	7	t
64	26	2	4	f	0	0	1	2023-11-20 09:00:39.82596	\N	7	\N	t
65	26	4	1	f	0	0	1	2023-11-20 09:01:12.706483	\N	7	\N	t
63	26	1	73	t	0	80000	3	2023-11-20 08:57:40.115551	\N	7	7	t
66	27	1	50	t	0	74857	3	2023-11-20 10:49:17.512531	\N	7	\N	t
67	27	2	3	f	0	0	1	2023-11-20 10:49:56.348938	\N	7	\N	t
68	27	4	1	f	0	0	1	2023-11-20 10:50:19.72714	\N	7	\N	t
71	28	4	2	f	0	0	2	2023-11-27 00:57:10.704423	\N	7	\N	t
72	29	8	20	t	100	0	2	2023-11-30 08:38:21.450457	\N	9	\N	t
73	29	2	1	f	0	0	1	2023-11-30 08:39:30.841028	\N	9	\N	t
69	28	1	49	t	100	0	2	2023-11-27 00:56:31.524274	\N	7	7	t
70	28	2	3	f	0	0	2	2023-11-27 00:56:51.981675	\N	7	7	t
78	31	2	2	f	0	0	2	2023-12-14 15:03:33.779516	\N	7	\N	t
79	31	4	2	f	0	0	2	2023-12-14 15:03:51.029403	\N	7	\N	t
81	32	2	2	f	0	0	2	2024-02-06 10:32:25.766549	\N	7	7	t
75	30	2	2	f	0	0	2	2023-12-06 23:00:23.71566	\N	7	7	t
76	30	4	2	f	0	0	1	2023-12-06 23:00:41.920447	\N	7	7	t
74	30	1	49	t	100	0	2	2023-12-06 23:00:07.474299	\N	7	7	t
77	31	1	40	t	100	0	2	2023-12-14 15:03:06.52143	\N	7	7	t
\.


--
-- TOC entry 4254 (class 0 OID 16541)
-- Dependencies: 277
-- Data for Name: tour_pax_quote; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tour_pax_quote (id, tour_lid, pax_type_lid, payment_percentage, per_person_quote, no_of_pax, tax_cost, total_without_tax, total_without_margin, profit, created_at, updated_at, created_by, updated_by, active) FROM stdin;
89	25	1	100	129264.72	25	12017.81	117246.91	105627.85	11619.06	2023-10-20 06:59:32.467839	\N	7	\N	t
27	12	1	100	97806.45	70	9093.12	88713.33	78507.37	10205.96	2023-10-03 12:37:42.327221	\N	7	\N	t
94	19	1	100	72933.43	66	3473.02	69460.41	62296.33	7164.08	2023-10-20 09:03:29.200326	\N	7	\N	t
98	23	1	100	77467.11	56	3688.91	73778.20	66168.79	7609.41	2023-10-20 12:40:12.094421	\N	7	\N	t
101	20	1	100	77947.85	77	3711.80	74236.05	66579.42	7656.63	2023-10-20 12:46:03.705759	\N	7	\N	t
103	18	1	100	73664.19	66	3507.82	70156.37	62920.52	7235.86	2023-10-21 05:32:51.429018	\N	7	\N	t
104	24	1	100	393763.29	50	36608.38	357154.91	335356.72	21798.19	2023-10-27 10:07:23.45206	\N	7	\N	t
110	26	1	0	80000.00	73	3809.52	76190.48	69264.07	6926.41	2023-11-20 10:42:00.349109	\N	7	\N	t
111	27	1	0	74857.00	50	3564.62	71292.38	70586.52	705.87	2023-11-20 11:22:14.928798	\N	7	\N	t
116	28	1	100	368449.00	45	17545.19	350903.81	331041.33	19862.48	2023-11-27 10:48:38.385622	\N	7	\N	t
59	22	1	100	294746.04	63	27402.69	267343.35	264696.39	2646.96	2023-10-06 05:45:01.773717	\N	7	\N	t
62	15	1	100	86424.56	56	4115.46	82309.10	73819.82	8489.28	2023-10-12 09:35:27.831814	\N	7	\N	t
128	30	1	100	346743.07	49	16511.57	330231.50	326961.88	3269.62	2024-01-03 04:41:57.825125	\N	7	\N	t
71	17	1	0	41038.00	56	1954.19	39083.81	35052.74	4031.07	2023-10-13 05:51:22.099493	\N	7	\N	t
129	31	1	100	344117.61	40	31992.79	312124.81	309034.47	3090.34	2024-01-04 05:07:13.415978	\N	7	\N	t
133	33	1	100	30396.71	80	1447.46	28949.25	26317.50	2631.75	2024-02-06 11:01:39.056081	\N	7	\N	t
80	16	1	0	778.00	63	72.33	705.67	\N	\N	2023-10-19 16:44:54.863076	\N	9	\N	t
137	32	1	100	26789.40	70	1275.69	25513.71	23194.29	2319.43	2024-02-07 16:22:32.126649	\N	7	\N	t
\.


--
-- TOC entry 4256 (class 0 OID 16549)
-- Dependencies: 279
-- Data for Name: tour_taxes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tour_taxes (id, tour_lid, tax_lid, tax_percentage, created_at, updated_at, created_by, updated_by, active) FROM stdin;
14	12	1	5	2023-10-03 11:27:43.050726	\N	7	\N	t
15	12	2	5	2023-10-03 11:27:49.337973	\N	7	\N	t
16	15	1	5	2023-10-04 05:28:46.108951	\N	7	\N	t
17	16	2	5	2023-10-04 06:45:31.87055	\N	9	\N	t
18	17	1	5	2023-10-05 07:19:08.254232	\N	8	\N	t
19	18	1	5	2023-10-05 09:59:33.246687	\N	7	\N	t
20	19	1	5	2023-10-05 10:15:15.883394	\N	7	\N	t
21	19	1	5	2023-10-05 10:29:07.486954	\N	7	7	f
22	20	1	5	2023-10-05 10:51:52.858606	\N	7	\N	t
23	22	1	5	2023-10-06 05:44:33.863548	\N	7	\N	t
24	22	2	5	2023-10-06 05:44:42.849456	\N	7	\N	t
25	23	1	5	2023-10-13 06:02:57.989776	\N	7	\N	t
26	24	1	5	2023-10-15 05:04:41.109406	\N	7	\N	t
27	24	2	5	2023-10-15 05:04:55.317607	\N	7	\N	t
28	16	1	5	2023-10-18 09:04:00.469968	\N	9	\N	t
29	25	1	5	2023-10-20 00:49:56.440498	\N	7	\N	t
30	25	2	5	2023-10-20 00:50:04.534751	\N	7	\N	t
31	26	1	5	2023-11-20 10:17:58.637443	\N	7	\N	t
32	27	1	5	2023-11-20 11:16:00.940376	\N	7	\N	t
33	28	1	5	2023-11-27 01:11:02.603266	\N	7	\N	t
34	30	1	5	2023-12-06 23:24:19.06996	\N	7	\N	t
35	31	1	5	2023-12-14 15:17:08.700799	\N	7	7	f
36	31	2	5	2023-12-14 15:17:13.68555	\N	7	7	f
37	31	1	5	2023-12-17 05:16:56.675902	\N	7	\N	t
38	31	2	5	2023-12-17 05:17:01.431913	\N	7	\N	t
39	32	1	5	2024-02-06 10:44:47.8764	\N	7	7	f
40	32	1	5	2024-02-06 10:44:55.452156	\N	7	\N	t
41	33	1	5	2024-02-06 11:01:30.45703	\N	7	\N	t
\.


--
-- TOC entry 4258 (class 0 OID 16557)
-- Dependencies: 281
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (id, user_id, role_id, created_at, updated_at, created_by, updated_by, active) FROM stdin;
1	1	1	2023-10-03 06:54:05.650699	\N	\N	\N	t
2	1	2	2023-10-03 06:54:17.933341	\N	\N	\N	t
3	7	1	2023-10-03 10:07:51.563264	\N	1	\N	t
4	7	2	2023-10-03 10:07:54.956948	\N	1	\N	t
5	8	2	2023-10-03 10:18:29.454061	\N	7	\N	t
6	9	2	2023-10-03 10:18:44.041636	\N	7	\N	t
7	10	2	2023-10-03 10:20:43.153855	\N	7	\N	t
8	11	2	2023-10-03 10:21:23.453938	\N	7	\N	t
9	11	1	2023-10-03 10:21:26.8221	\N	7	\N	t
10	12	2	2023-10-03 10:22:17.016433	\N	7	\N	t
11	13	1	2023-10-03 10:23:05.061807	\N	7	\N	t
12	13	2	2023-10-03 10:23:07.743439	\N	7	\N	t
\.


--
-- TOC entry 4260 (class 0 OID 16563)
-- Dependencies: 283
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, firstname, lastname, email, password, created_at, updated_at, created_by, updated_by, active) FROM stdin;
7	Atul	Ruparel	atul@vexploreindia.com	$2a$12$zaHNFw1bqIODedDxcP1bYe9nz149ZQfVLIiS5X/1.ceLpQ.fhhN9O	2023-10-03 13:07:59.288298+05:30	\N	1	\N	t
8	Neha	Mahajan	products1@vexploreindia.com	$2a$12$zaHNFw1bqIODedDxcP1bYe9nz149ZQfVLIiS5X/1.ceLpQ.fhhN9O	2023-10-03 15:44:37.851493+05:30	\N	1	\N	t
9	Purva	Jadyar	products@vexploreindia.com	$2a$12$zaHNFw1bqIODedDxcP1bYe9nz149ZQfVLIiS5X/1.ceLpQ.fhhN9O	2023-10-03 15:48:16.904222+05:30	\N	7	\N	t
10	Maya	Shenoy	opsmanager@vexploreindia.com	$2a$12$zaHNFw1bqIODedDxcP1bYe9nz149ZQfVLIiS5X/1.ceLpQ.fhhN9O	2023-10-03 15:50:36.53222+05:30	\N	7	\N	t
11	Maneka	Mulchandani	maneka@vexploreindia.com	$2a$12$zaHNFw1bqIODedDxcP1bYe9nz149ZQfVLIiS5X/1.ceLpQ.fhhN9O	2023-10-03 15:51:17.635172+05:30	\N	7	\N	t
12	Vijay	Shenoy	corp.sales@vexploreindia.com	$2a$12$zaHNFw1bqIODedDxcP1bYe9nz149ZQfVLIiS5X/1.ceLpQ.fhhN9O	2023-10-03 15:52:10.520085+05:30	\N	7	\N	t
13	Sunita	Amarnani	sunita@vexploreindia.com	$2a$12$zaHNFw1bqIODedDxcP1bYe9nz149ZQfVLIiS5X/1.ceLpQ.fhhN9O	2023-10-03 15:53:00.114829+05:30	\N	7	\N	t
1	owais	kapadia	owaiskapadia@gmail.com	$2b$10$Xq7AQPEhtPcLmk4AXR/eq.6LiD5Byzx8vqVnwgBNw7Kbxmx2s.1dq	2023-09-12 15:12:48.488798+05:30	2023-10-10 11:31:41.242879+05:30	1	1	t
\.


--
-- TOC entry 4321 (class 0 OID 0)
-- Dependencies: 244
-- Name: carrier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.carrier_id_seq', 1, true);


--
-- TOC entry 4322 (class 0 OID 0)
-- Dependencies: 246
-- Name: city_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.city_id_seq', 8, true);


--
-- TOC entry 4323 (class 0 OID 0)
-- Dependencies: 293
-- Name: company_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.company_id_seq', 17, true);


--
-- TOC entry 4324 (class 0 OID 0)
-- Dependencies: 289
-- Name: company_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.company_type_id_seq', 2, true);


--
-- TOC entry 4325 (class 0 OID 0)
-- Dependencies: 248
-- Name: country_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.country_id_seq', 243, true);


--
-- TOC entry 4326 (class 0 OID 0)
-- Dependencies: 250
-- Name: currency_rates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.currency_rates_id_seq', 169, true);


--
-- TOC entry 4327 (class 0 OID 0)
-- Dependencies: 252
-- Name: currency_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.currency_type_id_seq', 119, true);


--
-- TOC entry 4328 (class 0 OID 0)
-- Dependencies: 301
-- Name: customer_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_order_id_seq', 1, false);


--
-- TOC entry 4329 (class 0 OID 0)
-- Dependencies: 303
-- Name: customer_order_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_order_item_id_seq', 1, false);


--
-- TOC entry 4330 (class 0 OID 0)
-- Dependencies: 254
-- Name: expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expenses_id_seq', 17, true);


--
-- TOC entry 4331 (class 0 OID 0)
-- Dependencies: 256
-- Name: fare_class_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fare_class_id_seq', 2, true);


--
-- TOC entry 4332 (class 0 OID 0)
-- Dependencies: 305
-- Name: inventory_company_mapping_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inventory_company_mapping_id_seq', 164, true);


--
-- TOC entry 4333 (class 0 OID 0)
-- Dependencies: 297
-- Name: inventory_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inventory_status_id_seq', 4, true);


--
-- TOC entry 4334 (class 0 OID 0)
-- Dependencies: 299
-- Name: inventory_unit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inventory_unit_id_seq', 150, true);


--
-- TOC entry 4335 (class 0 OID 0)
-- Dependencies: 291
-- Name: mapping_label_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mapping_label_id_seq', 2, true);


--
-- TOC entry 4336 (class 0 OID 0)
-- Dependencies: 285
-- Name: mapping_receipt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mapping_receipt_id_seq', 15, true);


--
-- TOC entry 4337 (class 0 OID 0)
-- Dependencies: 258
-- Name: mode_of_transport_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mode_of_transport_id_seq', 2, true);


--
-- TOC entry 4338 (class 0 OID 0)
-- Dependencies: 260
-- Name: passenger_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.passenger_type_id_seq', 8, true);


--
-- TOC entry 4339 (class 0 OID 0)
-- Dependencies: 295
-- Name: product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_id_seq', 10, true);


--
-- TOC entry 4340 (class 0 OID 0)
-- Dependencies: 287
-- Name: product_sale_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_sale_id_seq', 3, true);


--
-- TOC entry 4341 (class 0 OID 0)
-- Dependencies: 262
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 2, true);


--
-- TOC entry 4342 (class 0 OID 0)
-- Dependencies: 307
-- Name: sample_table_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sample_table_id_seq', 6, true);


--
-- TOC entry 4343 (class 0 OID 0)
-- Dependencies: 264
-- Name: state_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.state_id_seq', 6, true);


--
-- TOC entry 4344 (class 0 OID 0)
-- Dependencies: 266
-- Name: tax_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tax_id_seq', 3, true);


--
-- TOC entry 4345 (class 0 OID 0)
-- Dependencies: 269
-- Name: tour_currency_rates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tour_currency_rates_id_seq', 7, true);


--
-- TOC entry 4346 (class 0 OID 0)
-- Dependencies: 271
-- Name: tour_expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tour_expenses_id_seq', 482, true);


--
-- TOC entry 4347 (class 0 OID 0)
-- Dependencies: 272
-- Name: tour_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tour_id_seq', 33, true);


--
-- TOC entry 4348 (class 0 OID 0)
-- Dependencies: 274
-- Name: tour_margin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tour_margin_id_seq', 23, true);


--
-- TOC entry 4349 (class 0 OID 0)
-- Dependencies: 276
-- Name: tour_passengers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tour_passengers_id_seq', 85, true);


--
-- TOC entry 4350 (class 0 OID 0)
-- Dependencies: 278
-- Name: tour_pax_quote_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tour_pax_quote_id_seq', 137, true);


--
-- TOC entry 4351 (class 0 OID 0)
-- Dependencies: 280
-- Name: tour_taxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tour_taxes_id_seq', 41, true);


--
-- TOC entry 4352 (class 0 OID 0)
-- Dependencies: 282
-- Name: user_roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_roles_id_seq', 12, true);


--
-- TOC entry 4353 (class 0 OID 0)
-- Dependencies: 284
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 13, true);


--
-- TOC entry 3959 (class 2606 OID 16589)
-- Name: carrier carrier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrier
    ADD CONSTRAINT carrier_pkey PRIMARY KEY (id);


--
-- TOC entry 3961 (class 2606 OID 16591)
-- Name: city city_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (id);


--
-- TOC entry 4020 (class 2606 OID 25390)
-- Name: company company_company_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company
    ADD CONSTRAINT company_company_code_key UNIQUE (company_code);


--
-- TOC entry 4022 (class 2606 OID 25388)
-- Name: company company_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company
    ADD CONSTRAINT company_pkey PRIMARY KEY (id);


--
-- TOC entry 4012 (class 2606 OID 25338)
-- Name: company_type company_type_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_type
    ADD CONSTRAINT company_type_name_key UNIQUE (name);


--
-- TOC entry 4014 (class 2606 OID 25336)
-- Name: company_type company_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_type
    ADD CONSTRAINT company_type_pkey PRIMARY KEY (id);


--
-- TOC entry 3963 (class 2606 OID 16593)
-- Name: country country_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (id);


--
-- TOC entry 3965 (class 2606 OID 16595)
-- Name: currency_type currency_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currency_type
    ADD CONSTRAINT currency_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4041 (class 2606 OID 25622)
-- Name: customer_order_item customer_order_item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order_item
    ADD CONSTRAINT customer_order_item_pkey PRIMARY KEY (id);


--
-- TOC entry 4037 (class 2606 OID 25574)
-- Name: customer_order customer_order_order_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order
    ADD CONSTRAINT customer_order_order_number_key UNIQUE (order_number);


--
-- TOC entry 4039 (class 2606 OID 25572)
-- Name: customer_order customer_order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order
    ADD CONSTRAINT customer_order_pkey PRIMARY KEY (id);


--
-- TOC entry 3967 (class 2606 OID 16597)
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- TOC entry 3969 (class 2606 OID 16599)
-- Name: fare_class fare_class_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fare_class
    ADD CONSTRAINT fare_class_pkey PRIMARY KEY (id);


--
-- TOC entry 4044 (class 2606 OID 25651)
-- Name: inventory_company_mapping inventory_company_mapping_inventory_unit_lid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_company_mapping
    ADD CONSTRAINT inventory_company_mapping_inventory_unit_lid_key UNIQUE (inventory_unit_lid);


--
-- TOC entry 4046 (class 2606 OID 25649)
-- Name: inventory_company_mapping inventory_company_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_company_mapping
    ADD CONSTRAINT inventory_company_mapping_pkey PRIMARY KEY (id);


--
-- TOC entry 4028 (class 2606 OID 25418)
-- Name: inventory_status inventory_status_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_status
    ADD CONSTRAINT inventory_status_name_key UNIQUE (name);


--
-- TOC entry 4030 (class 2606 OID 25416)
-- Name: inventory_status inventory_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_status
    ADD CONSTRAINT inventory_status_pkey PRIMARY KEY (id);


--
-- TOC entry 4035 (class 2606 OID 25428)
-- Name: inventory_unit inventory_unit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_unit
    ADD CONSTRAINT inventory_unit_pkey PRIMARY KEY (id);


--
-- TOC entry 4016 (class 2606 OID 25351)
-- Name: mapping_label mapping_label_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_label
    ADD CONSTRAINT mapping_label_name_key UNIQUE (name);


--
-- TOC entry 4018 (class 2606 OID 25349)
-- Name: mapping_label mapping_label_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_label
    ADD CONSTRAINT mapping_label_pkey PRIMARY KEY (id);


--
-- TOC entry 4003 (class 2606 OID 17156)
-- Name: mapping_receipt mapping_receipt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_receipt
    ADD CONSTRAINT mapping_receipt_pkey PRIMARY KEY (id);


--
-- TOC entry 4005 (class 2606 OID 17158)
-- Name: mapping_receipt mapping_receipt_receipt_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapping_receipt
    ADD CONSTRAINT mapping_receipt_receipt_number_key UNIQUE (receipt_number);


--
-- TOC entry 3971 (class 2606 OID 16601)
-- Name: mode_of_transport mode_of_transport_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mode_of_transport
    ADD CONSTRAINT mode_of_transport_pkey PRIMARY KEY (id);


--
-- TOC entry 3973 (class 2606 OID 16603)
-- Name: passenger_type passenger_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passenger_type
    ADD CONSTRAINT passenger_type_pkey PRIMARY KEY (id);


--
-- TOC entry 4024 (class 2606 OID 25403)
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (id);


--
-- TOC entry 4026 (class 2606 OID 25405)
-- Name: product product_product_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_product_code_key UNIQUE (product_code);


--
-- TOC entry 4010 (class 2606 OID 17234)
-- Name: product_sale product_sale_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_sale
    ADD CONSTRAINT product_sale_pkey PRIMARY KEY (id);


--
-- TOC entry 3975 (class 2606 OID 16605)
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- TOC entry 3977 (class 2606 OID 16607)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 3979 (class 2606 OID 16609)
-- Name: state state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.state
    ADD CONSTRAINT state_pkey PRIMARY KEY (id);


--
-- TOC entry 3981 (class 2606 OID 16611)
-- Name: tax tax_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tax
    ADD CONSTRAINT tax_pkey PRIMARY KEY (id);


--
-- TOC entry 3985 (class 2606 OID 16613)
-- Name: tour_currency_rates tour_currency_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_currency_rates
    ADD CONSTRAINT tour_currency_rates_pkey PRIMARY KEY (id);


--
-- TOC entry 3987 (class 2606 OID 16615)
-- Name: tour_expenses tour_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_expenses
    ADD CONSTRAINT tour_expenses_pkey PRIMARY KEY (id);


--
-- TOC entry 3989 (class 2606 OID 16617)
-- Name: tour_margin tour_margin_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_margin
    ADD CONSTRAINT tour_margin_pkey PRIMARY KEY (id);


--
-- TOC entry 3991 (class 2606 OID 16619)
-- Name: tour_passengers tour_passengers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_passengers
    ADD CONSTRAINT tour_passengers_pkey PRIMARY KEY (id);


--
-- TOC entry 3993 (class 2606 OID 16621)
-- Name: tour_pax_quote tour_pax_quote_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_pax_quote
    ADD CONSTRAINT tour_pax_quote_pkey PRIMARY KEY (id);


--
-- TOC entry 3983 (class 2606 OID 16623)
-- Name: tour tour_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour
    ADD CONSTRAINT tour_pkey PRIMARY KEY (id);


--
-- TOC entry 3995 (class 2606 OID 16625)
-- Name: tour_taxes tour_taxes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_taxes
    ADD CONSTRAINT tour_taxes_pkey PRIMARY KEY (id);


--
-- TOC entry 3997 (class 2606 OID 16627)
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- TOC entry 3999 (class 2606 OID 16629)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4042 (class 1259 OID 25667)
-- Name: idx_inventory_company_mapping_company; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_inventory_company_mapping_company ON public.inventory_company_mapping USING btree (company_lid);


--
-- TOC entry 4031 (class 1259 OID 25446)
-- Name: idx_inventory_unit_company; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_inventory_unit_company ON public.inventory_unit USING btree (current_company_lid);


--
-- TOC entry 4032 (class 1259 OID 25444)
-- Name: idx_inventory_unit_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_inventory_unit_product ON public.inventory_unit USING btree (product_lid);


--
-- TOC entry 4033 (class 1259 OID 25445)
-- Name: idx_inventory_unit_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_inventory_unit_status ON public.inventory_unit USING btree (status_lid);


--
-- TOC entry 4000 (class 1259 OID 17188)
-- Name: idx_mapping_receipt_company; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mapping_receipt_company ON public.mapping_receipt USING btree (company_lid);


--
-- TOC entry 4001 (class 1259 OID 17189)
-- Name: idx_mapping_receipt_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mapping_receipt_date ON public.mapping_receipt USING btree (mapping_date);


--
-- TOC entry 4006 (class 1259 OID 17252)
-- Name: idx_product_sale_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_sale_active ON public.product_sale USING btree (active);


--
-- TOC entry 4007 (class 1259 OID 17251)
-- Name: idx_product_sale_company; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_sale_company ON public.product_sale USING btree (company_lid);


--
-- TOC entry 4008 (class 1259 OID 17250)
-- Name: idx_product_sale_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_sale_product ON public.product_sale USING btree (product_lid);


--
-- TOC entry 4047 (class 2606 OID 16630)
-- Name: carrier carrier_transport_mode_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrier
    ADD CONSTRAINT carrier_transport_mode_lid_fkey FOREIGN KEY (transport_mode_lid) REFERENCES public.mode_of_transport(id);


--
-- TOC entry 4048 (class 2606 OID 16635)
-- Name: city city_state_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.city
    ADD CONSTRAINT city_state_lid_fkey FOREIGN KEY (state_lid) REFERENCES public.state(id);


--
-- TOC entry 4068 (class 2606 OID 25575)
-- Name: customer_order customer_order_company_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order
    ADD CONSTRAINT customer_order_company_lid_fkey FOREIGN KEY (company_lid) REFERENCES public.company(id);


--
-- TOC entry 4069 (class 2606 OID 25633)
-- Name: customer_order_item customer_order_item_inventory_unit_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order_item
    ADD CONSTRAINT customer_order_item_inventory_unit_lid_fkey FOREIGN KEY (inventory_unit_lid) REFERENCES public.inventory_unit(id);


--
-- TOC entry 4070 (class 2606 OID 25623)
-- Name: customer_order_item customer_order_item_order_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order_item
    ADD CONSTRAINT customer_order_item_order_lid_fkey FOREIGN KEY (order_lid) REFERENCES public.customer_order(id);


--
-- TOC entry 4071 (class 2606 OID 25628)
-- Name: customer_order_item customer_order_item_product_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer_order_item
    ADD CONSTRAINT customer_order_item_product_lid_fkey FOREIGN KEY (product_lid) REFERENCES public.product(id);


--
-- TOC entry 4049 (class 2606 OID 16640)
-- Name: fare_class fare_class_transport_mode_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fare_class
    ADD CONSTRAINT fare_class_transport_mode_lid_fkey FOREIGN KEY (transport_mode_lid) REFERENCES public.mode_of_transport(id);


--
-- TOC entry 4072 (class 2606 OID 25657)
-- Name: inventory_company_mapping inventory_company_mapping_company_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_company_mapping
    ADD CONSTRAINT inventory_company_mapping_company_lid_fkey FOREIGN KEY (company_lid) REFERENCES public.company(id);


--
-- TOC entry 4073 (class 2606 OID 25652)
-- Name: inventory_company_mapping inventory_company_mapping_inventory_unit_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_company_mapping
    ADD CONSTRAINT inventory_company_mapping_inventory_unit_lid_fkey FOREIGN KEY (inventory_unit_lid) REFERENCES public.inventory_unit(id);


--
-- TOC entry 4074 (class 2606 OID 25662)
-- Name: inventory_company_mapping inventory_company_mapping_label_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_company_mapping
    ADD CONSTRAINT inventory_company_mapping_label_lid_fkey FOREIGN KEY (label_lid) REFERENCES public.mapping_label(id);


--
-- TOC entry 4065 (class 2606 OID 25439)
-- Name: inventory_unit inventory_unit_current_company_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_unit
    ADD CONSTRAINT inventory_unit_current_company_lid_fkey FOREIGN KEY (current_company_lid) REFERENCES public.company(id);


--
-- TOC entry 4066 (class 2606 OID 25429)
-- Name: inventory_unit inventory_unit_product_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_unit
    ADD CONSTRAINT inventory_unit_product_lid_fkey FOREIGN KEY (product_lid) REFERENCES public.product(id);


--
-- TOC entry 4067 (class 2606 OID 25434)
-- Name: inventory_unit inventory_unit_status_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory_unit
    ADD CONSTRAINT inventory_unit_status_lid_fkey FOREIGN KEY (status_lid) REFERENCES public.inventory_status(id);


--
-- TOC entry 4064 (class 2606 OID 17245)
-- Name: product_sale product_sale_receipt_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_sale
    ADD CONSTRAINT product_sale_receipt_lid_fkey FOREIGN KEY (receipt_lid) REFERENCES public.mapping_receipt(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4050 (class 2606 OID 16645)
-- Name: tour_currency_rates tour_currency_rates_currency_type_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_currency_rates
    ADD CONSTRAINT tour_currency_rates_currency_type_lid_fkey FOREIGN KEY (currency_type_lid) REFERENCES public.currency_type(id);


--
-- TOC entry 4051 (class 2606 OID 16650)
-- Name: tour_currency_rates tour_currency_rates_tour_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_currency_rates
    ADD CONSTRAINT tour_currency_rates_tour_lid_fkey FOREIGN KEY (tour_lid) REFERENCES public.tour(id);


--
-- TOC entry 4052 (class 2606 OID 16655)
-- Name: tour_expenses tour_expenses_currency_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_expenses
    ADD CONSTRAINT tour_expenses_currency_lid_fkey FOREIGN KEY (currency_lid) REFERENCES public.currency_type(id);


--
-- TOC entry 4053 (class 2606 OID 16660)
-- Name: tour_expenses tour_expenses_expense_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_expenses
    ADD CONSTRAINT tour_expenses_expense_lid_fkey FOREIGN KEY (expense_lid) REFERENCES public.expenses(id);


--
-- TOC entry 4054 (class 2606 OID 16665)
-- Name: tour_expenses tour_expenses_pax_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_expenses
    ADD CONSTRAINT tour_expenses_pax_lid_fkey FOREIGN KEY (pax_lid) REFERENCES public.passenger_type(id);


--
-- TOC entry 4055 (class 2606 OID 16670)
-- Name: tour_expenses tour_expenses_tour_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_expenses
    ADD CONSTRAINT tour_expenses_tour_lid_fkey FOREIGN KEY (tour_lid) REFERENCES public.tour(id);


--
-- TOC entry 4056 (class 2606 OID 16675)
-- Name: tour_margin tour_margin_tour_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_margin
    ADD CONSTRAINT tour_margin_tour_lid_fkey FOREIGN KEY (tour_lid) REFERENCES public.tour(id);


--
-- TOC entry 4057 (class 2606 OID 16680)
-- Name: tour_passengers tour_passengers_pax_type_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_passengers
    ADD CONSTRAINT tour_passengers_pax_type_lid_fkey FOREIGN KEY (pax_type_lid) REFERENCES public.passenger_type(id);


--
-- TOC entry 4058 (class 2606 OID 16685)
-- Name: tour_passengers tour_passengers_tour_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_passengers
    ADD CONSTRAINT tour_passengers_tour_lid_fkey FOREIGN KEY (tour_lid) REFERENCES public.tour(id);


--
-- TOC entry 4059 (class 2606 OID 16690)
-- Name: tour_pax_quote tour_pax_quote_tour_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_pax_quote
    ADD CONSTRAINT tour_pax_quote_tour_lid_fkey FOREIGN KEY (tour_lid) REFERENCES public.tour(id);


--
-- TOC entry 4060 (class 2606 OID 16695)
-- Name: tour_taxes tour_taxes_tax_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_taxes
    ADD CONSTRAINT tour_taxes_tax_lid_fkey FOREIGN KEY (tax_lid) REFERENCES public.tax(id);


--
-- TOC entry 4061 (class 2606 OID 16700)
-- Name: tour_taxes tour_taxes_tour_lid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tour_taxes
    ADD CONSTRAINT tour_taxes_tour_lid_fkey FOREIGN KEY (tour_lid) REFERENCES public.tour(id);


--
-- TOC entry 4062 (class 2606 OID 16705)
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- TOC entry 4063 (class 2606 OID 16710)
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


-- Completed on 2025-09-16 01:28:07 IST

--
-- PostgreSQL database dump complete
--

