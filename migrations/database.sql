

-- ================== ALL TABLES HERE IN ORDER =================================================

DROP TABLE IF EXISTS country;
CREATE TABLE country (
    id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	code VARCHAR(100) NOT NULL,
	created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP ,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT true
);

DROP TABLE IF EXISTS city;
CREATE TABLE city (
    id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	country_lid INT REFERENCES country(id) NOT NULL,
	state_lid INT REFERENCES state(id) NOT NULL,
	postal_code VARCHAR(100) NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT(true)
);

DROP TABLE IF EXISTS currency_type;
CREATE TABLE currency_type (
    id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	country_lid INT REFERENCES country(id) NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT(true)
);


DROP TABLE IF EXISTS expenses;
CREATE TABLE expenses (
    id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	created_by VARCHAR(255) NOT NULL,
	created_at TIMESTAMP DEFAULT now(),
	updated_by VARCHAR(255),
    updated_at TIMESTAMP,
	active BOOLEAN NOT NULL DEFAULT TRUE
);


DROP TABLE IF EXISTS state;
CREATE TABLE state (
    id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	country_lid INT REFERENCES country(id),
	created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP ,
    created_by varchar(255) not null,
    updated_by varchar(255),
	active BOOLEAN NOT NULL DEFAULT TRUE
);

DROP TABLE IF EXISTS tour;
CREATE TABLE tour (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
	duration_days INT NOT NULL,
	duration_nights INT NOT NULL, 
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT(true)
);


CREATE TABLE hotels(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	country_lid INT,
	state_lid INT,
	city_lid INT,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP,
	created_by INT NOT NULL,
	updated_by INT,
	active BOOLEAN DEFAULT(true),
	FOREIGN KEY(country_lid) REFERENCES country(id),
	FOREIGN KEY(state_lid) REFERENCES state(id),
	FOREIGN KEY(city_lid) REFERENCES city(id)
);

CREATE TABLE room_types(
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP,
	created_by INT NOT NULL,
	updated_by INT,
	active BOOLEAN DEFAULT(true)
);


CREATE TABLE hotel_room_types (
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	hotel_lid INT NOT NULL,
	room_type_lid INT NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP,
	created_by INT NOT NULL,
	updated_by INT,
	active BOOLEAN DEFAULT(true),
	FOREIGN KEY(hotel_lid) REFERENCES hotels(id),
	FOREIGN KEY(room_type_lid) REFERENCES room_types(id)
);

DROP TABLE IF EXISTS passenger_type;
CREATE TABLE passenger_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP ,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT(TRUE)
);

CREATE TABLE IF NOT EXISTS mode_of_transport
(
    id integer NOT NULL DEFAULT nextval('mode_of_transport_id_seq'::regclass),
    name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean NOT NULL DEFAULT true,
    CONSTRAINT mode_of_transport_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS carrier
(
    id integer NOT NULL DEFAULT nextval('carrier_id_seq'::regclass),
    name character varying(100) COLLATE pg_catalog."default" NOT NULL,
    transport_mode_lid integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    created_by integer NOT NULL,
    updated_by integer,
    active boolean NOT NULL DEFAULT true,
    CONSTRAINT carrier_pkey PRIMARY KEY (id),
    CONSTRAINT carrier_transport_mode_lid_fkey FOREIGN KEY (transport_mode_lid)
	REFERENCES public.mode_of_transport (id) MATCH SIMPLE
	ON UPDATE NO ACTION
	ON DELETE NO ACTION
);

DROP TABLE IF EXISTS tax;
CREATE TABLE tax (
	id SERIAL NOT NULL,
	name VARCHAR(100) NOT NULL,
	percentage NUMERIC NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT(true)
);

DROP TABLE IF EXISTS tour_expenses;
CREATE TABLE tour_expenses (
	id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	tour_lid INT NOT NULL REFERENCES tour(id),
	expense_lid INT NOT NULL REFERENCES expenses(id),
	pax_lid INT NOT NULL REFERENCES passenger_type(id),
	pax_count INT,
	currency_lid INT REFERENCES currency_type(id),
	unit_price NUMERIC,
	nightly_recurring BOOLEAN,
	daily_recurring BOOLEAN,
	total_price NUMERIC,
	created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP,
    created_by INT not null,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT TRUE
);


DROP TABLE IF EXISTS users;
CREATE TABLE users(
	id INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	firstname varchar(255) NOT NULL,
	lastname varchar(255) ,
	email varchar(255) NOT NULL UNIQUE,
	password varchar(255) NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
	updated_at TIMESTAMP WITH TIME ZONE ,
	created_by INT NOT NULL,
	updated_by INT,
	active BOOLEAN NOT NULL DEFAULT TRUE
);


INSERT INTO users(firstname, lastname, email, password, created_by) 
values ('owais', 'kapadia', 'owaiskapadia@gmail.com', '$2a$12$zaHNFw1bqIODedDxcP1bYe9nz149ZQfVLIiS5X/1.ceLpQ.fhhN9O', 1);

DROP TABLE IF EXISTS tour_taxes;
CREATE TABLE tour_taxes (
    id SERIAL PRIMARY KEY,
	tour_lid INT REFERENCES tour(id),
	tax_lid INT REFERENCES tax(id),
	tax_percentage NUMERIC NOT NULL,
	created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP ,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT true
);

ALTER TABLE tax
ADD COLUMN compounding BIT(1) DEFAULT '0' ;
-- ================== ALL FUNCTION AND PROCEDURES HERE =================================================

CREATE OR REPLACE FUNCTION update_city(
    city_id INT,
    new_city_name VARCHAR(100),
    new_postal_code VARCHAR(100)
) RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS add_new_countries;
CREATE OR REPLACE FUNCTION add_new_countries(IN input_json json, IN username text)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
      i text;
	  output_result JSONB;
	  error_result JSONB;
	  _count int;
	  
BEGIN
			DROP TABLE IF EXISTS temp_countries;
			CREATE TEMPORARY TABLE temp_countries(
				id SERIAL PRIMARY KEY ,
				name varchar(255)
			);
			
			_count:= 0;
			
			    -- Loop through array elements and insert into the temporary table
				 FOR i IN SELECT * FROM json_array_elements_text(input_json)
				LOOP
					INSERT INTO temp_countries(name) VALUES (i);   
				END LOOP;	
				
				_count := (select count(distinct c.name) from country c 
						 	join temp_countries tc on c.name = tc.name where c.active = true);
							
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
				using (SELECT distinct name from temp_countries) tc 
				on c.name = tc.name
				WHEN MATCHED THEN
					 UPDATE SET active = true, updated_at = now(), updated_by = username
				WHEN NOT MATCHED THEN 
				INSERT (name, created_by) 
				VALUES (tc.name, username);
			
				output_result:=  (select json_build_object('status',200,'message','successfully inserted'));
				end if;
				
					
RETURN output_result;	 
END;
$BODY$;



DROP FUNCTION IF EXISTS add_new_state;
CREATE OR REPLACE FUNCTION add_new_state(IN input_json json, IN username text)
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
$BODY$;



DROP FUNCTION IF EXISTS add_new_tour;

CREATE OR REPLACE FUNCTION add_new_tour(IN tour_name text, IN tour_nights int, IN username int)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


CREATE OR REPLACE FUNCTION insert_cities(
    newCities JSONB,
	createdBy INT
) RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql;



-- INSERT EXPENSE FUNCTION

CREATE OR REPLACE FUNCTION public.insert_expense(
	new_expenses jsonb,
	var_created_by integer)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


-- INSERT PASSENGER TYPE

CREATE OR REPLACE FUNCTION public.insert_pax_type(
	input_json jsonb,
	var_created_by integer)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;


 --INSERT CURRENCY TYPE
DROP FUNCTION IF EXISTS insert_currencies;
CREATE OR REPLACE FUNCTION insert_currencies(
    newCurrency JSONB,
	createdBy INT
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
	createdBy := 1;
	
	DROP TABLE IF EXISTS temp_currencies;
	CREATE TEMP TABLE temp_currencies (
		currency_name VARCHAR(255),
		country_lid INT
	);
	
	INSERT INTO temp_currencies(currency_name, country_lid)
	SELECT
		currency->>'currency' AS currency,
		(currency->>'countryLid')::INT AS countryLid
	FROM
    jsonb_array_elements(newCurrency) AS currency;
	
	IF EXISTS (SELECT * FROM temp_currencies tc
	INNER JOIN currency_type c ON
	c.country_lid = tc.country_lid
	WHERE c.active = true) 
	THEN
        result = '{"status": "success", "message": "Data inserted successfully except for the duplicate data."}'::JSONB;
	ELSE
		result := '{"status": "success", "message": "Currencies inserted successfully!"}'::JSONB;
	END IF;
	
	-- TO BE INSERTED
  	INSERT INTO currency_type(name, country_lid, created_by)
	SELECT tc.currency_name, tc.country_lid, 1 FROM temp_currencies tc
	LEFT JOIN (SELECT * FROM currency_type WHERE active = true) c ON 
	c.country_lid = tc.country_lid 
	WHERE c.id IS NULL;
	
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
		result = '{"status": "error", "message": "Something went wrong!"}'::JSONB;
        RAISE;
END;
$$ LANGUAGE plpgsql;

-- ADD TAX FUNCTION

DROP FUNCTION IF EXISTS add_new_tax;

CREATE OR REPLACE FUNCTION add_new_tax(IN input_json json, IN username int)
    RETURNS jsonb
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
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
$BODY$;

-- UPDATE TAX FUNCTION

CREATE OR REPLACE FUNCTION update_tax(
    tax_id INT,
    new_tax_name VARCHAR(100),
    new_percentage numeric
) RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql;



DROP TABLE IF EXISTS currency_rates;
CREATE TABLE currency_rates (
	currency_code varchar(25),
	price NUMERIC NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT(true)
);


DROP FUNCTION IF EXISTS currency_calculator;
CREATE FUNCTION currency_calculator(currency_from varchar(10), currency_to varchar(10), total_price numeric) RETURNS numeric AS $$
    DECLARE
      div_result numeric;
     currency_price_from numeric;
     currency_price_to numeric;
    begin
	    
	    select price into currency_price_from from currency_rates where currency_code = currency_from;
	    select price into currency_price_to from currency_rates where currency_code = currency_to;
	    select  (currency_price_to/currency_price_from) * total_price into div_result from currency_rates where currency_code = currency_from;

      RETURN div_result;
    END;
$$ LANGUAGE 'plpgsql';

		
DROP FUNCTION IF EXISTS tour_quotations;
CREATE OR REPLACE FUNCTION tour_quotations(
    _tour_lid INT,
	_tour_price_inr NUMERIC,
	userId INT
) RETURNS JSONB AS $$
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
	
	simple_tax:= (select sum(tt.tax_percentage) from tour_taxes tt 
	join tax tx on tt.tax_lid = tx.id
	where tt.tour_lid = _tour_lid and compounding = '0' and tx.active= true and tt.active = true);
		
		RAISE NOTICE ':::::::::::::simple_tax %d', simple_tax; 
	
	compound_tax:= (select sum(tt.tax_percentage) from tour_taxes tt 
					join tax tx on tt.tax_lid = tx.id
					where tt.tour_lid = _tour_lid and compounding = '1' 
					and tx.active= true and tt.active = true);
		
		RAISE NOTICE ':::::::::::::compound_tax %d', compound_tax;
	
	totalPrice:=  (_tour_price_inr * (1 + (_margin/100)));
		
		RAISE NOTICE ':::::::::::::totalPrice %d', totalPrice;
		
	totalPriceWithTax:= (totalPrice + 2*(totalPrice*(simple_tax/100)) + (simple_tax/100)*( compound_tax/100)*totalPrice) ;
		
		RAISE NOTICE ':::::::::::::totalPriceWithTax %d', totalPriceWithTax;
	
		
	estimation_without_fixed_pax := 	(select (totalPriceWithTax - COALESCE(sum(t.fixed), 0) )
						from (select  tp.payment_amount*tp.no_of_passengers as fixed
						from  tour_passengers tp WHERE tour_lid = _tour_lid and is_payable = true and active = true 
						and payment_percentage = 0 and payment_amount > 0) t);
	
		
			RAISE NOTICE ':::::::::::::estimation_without_fixed_pax %d', estimation_without_fixed_pax;
						

	per_person_before:= (estimation_without_fixed_pax/	(select  sum(tp.no_of_passengers) from  tour_passengers tp 
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
						total_without_tax numeric
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
		
						UPDATE temp_percent_pax SET 
						tax_cost  = (per_person - (per_person/(1 + 2*(simple_tax/100) + (simple_tax/100)*(compound_tax/100)))), 
						 total_without_tax =  (per_person/(1 + 2*(simple_tax/100) + (simple_tax/100)*(compound_tax/100)));
						
						DELETE FROM tour_pax_quote where tour_lid = _tour_lid; 				
		
						INSERT INTO tour_pax_quote (tour_lid, pax_type_lid, payment_percentage, per_person_quote, no_of_pax, tax_cost, total_without_tax, created_by)
						SELECT _tour_lid, tpp.pax_type_lid, tpp.payment_percentage, ROUND(tpp.per_person, 2), tpp.no_of_pax, ROUND(tpp.tax_cost, 2), ROUND(tpp.total_without_tax, 2), userId from temp_percent_pax tpp;
						
						  result := (
									SELECT json_agg(json_build_object(
											'pax_id', p.id,
											'name', p.name,
											'per_person_quote', tpq.per_person_quote,
											'no_of_pax', tpq.no_of_pax,
											'tax_cost', tpq.tax_cost,
											'total_without_tax', tpq.total_without_tax,
											'margin', _margin,
											'total_without_margin_tax', ROUND((tpq.total_without_tax* (1+ (_margin/100))), 2)
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
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS insert_update_margin;
CREATE OR REPLACE FUNCTION insert_update_margin(_margin numeric, _tour_lid numeric, _created_by int) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    -- Check for duplicate tax names
    IF EXISTS (select * from tour_margin tm where tm.tour_lid = _tour_lid and tm.created_by = _created_by) then
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
$$ LANGUAGE plpgsql;


drop table if exists tour_pax_quote;
create  table tour_pax_quote(
id SERIAL PRIMARY KEY,
tour_lid INT REFERENCES tour(id),
pax_type_lid INT,
payment_percentage INT,
per_person_quote NUMERIC,
no_of_pax INT,
tax_cost numeric,
total_without_tax numeric,
created_at TIMESTAMP DEFAULT now(),
updated_at TIMESTAMP ,
created_by INT NOT NULL,
updated_by INT,
active BOOLEAN NOT NULL DEFAULT true
);

DROP TABLE IF EXISTS tour_margin;
CREATE TABLE tour_margin (
    id SERIAL PRIMARY KEY,
	tour_lid INT REFERENCES tour(id),
	margin NUMERIC NOT NULL,
	created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP ,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT true
);


DROP TABLE IF EXISTS tour_taxes;
CREATE TABLE tour_taxes (
    id SERIAL PRIMARY KEY,
	tour_lid INT REFERENCES tour(id),
	tax_lid INT REFERENCES tax(id),
	tax_percentage NUMERIC NOT NULL,
	created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP ,
    created_by INT NOT NULL,
    updated_by INT,
	active BOOLEAN NOT NULL DEFAULT true
);
ALTER TABLE tax
ADD COLUMN compounding BIT(1) DEFAULT '0' ;

-- ================== COMPANY MASTER SYSTEM =================================================

DROP TABLE IF EXISTS company;
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

-- COMPANY INSERT FUNCTION
DROP FUNCTION IF EXISTS insert_companies;
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
                              tax_number, company_type, website)
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
    
    -- TO BE INSERTED
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

-- COMPANY UPDATE FUNCTION
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

-- BULK COMPANY INSERT FUNCTION (similar to add_new_countries pattern)
DROP FUNCTION IF EXISTS add_new_companies;
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
        
        -- Loop through array elements and insert into the temporary table
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

-- ================== COMPANY TYPE MASTER SYSTEM =================================================

DROP TABLE IF EXISTS company_type;
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

-- Insert initial company types
INSERT INTO company_type (name, description, created_by) VALUES 
('SELF', 'Self-owned company', 1),
('VENDOR', 'External vendor company', 1);

-- COMPANY TYPE INSERT FUNCTION
DROP FUNCTION IF EXISTS insert_company_types;
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
    
    -- TO BE INSERTED
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

-- COMPANY TYPE UPDATE FUNCTION
CREATE OR REPLACE FUNCTION update_company_type(
    company_type_id INT,
    new_name VARCHAR(100),
    new_description VARCHAR(255),
    updated_by_user INT
) RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    -- Check for duplicate company type names
    IF EXISTS (SELECT 1 FROM company_type 
               WHERE name = new_name 
               AND id != company_type_id AND active = true) THEN
        result = '{"status": "error", "message": "Duplicate company type name."}'::JSONB;
    ELSE
        -- Update the company type
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

-- BULK COMPANY TYPE INSERT FUNCTION
DROP FUNCTION IF EXISTS add_new_company_types;
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
        
        -- Loop through array elements and insert into the temporary table
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

-- ================== PRODUCT MANAGEMENT SYSTEM =================================================

-- LABEL MASTER
DROP TABLE IF EXISTS label;
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

-- Insert initial labels
INSERT INTO label (name, description, created_by) VALUES 
('NEW', 'Newly added product for the company', 1),
('OLD', 'Previously added product that is no longer new', 1),
('SOLD', 'Product that has been sold', 1);

-- PRODUCT MASTER
DROP TABLE IF EXISTS product;
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

-- PRODUCT COMPANY MAPPING
DROP TABLE IF EXISTS product_company_mapping;
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

-- LABEL FUNCTIONS
DROP FUNCTION IF EXISTS insert_labels;
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

-- PRODUCT FUNCTIONS
DROP FUNCTION IF EXISTS insert_products;
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

-- PRODUCT UPDATE FUNCTION
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
    -- Check for duplicate product names or codes
    IF EXISTS (SELECT 1 FROM product 
               WHERE (name = new_name OR product_code = new_product_code) 
               AND id != product_id AND active = true) THEN
        result = '{"status": "error", "message": "Duplicate product name or code."}'::JSONB;
    ELSE
        -- Update the product
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

-- PRODUCT COMPANY MAPPING WITH BUSINESS LOGIC
DROP FUNCTION IF EXISTS map_product_to_company;
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
    -- Get label IDs
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

-- UPDATE PRODUCT MAPPING LABEL
DROP FUNCTION IF EXISTS update_product_mapping_label;
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

-- GET PRODUCT COMPANY MAPPINGS WITH DETAILS
DROP FUNCTION IF EXISTS get_product_company_mappings;
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
    
    -- Check if product is already actively mapped to new company
    IF EXISTS (SELECT 1 FROM product_company_mapping 
               WHERE product_lid = v_product_lid AND company_lid = p_new_company_lid AND active = true) THEN
        result = '{"status": "error", "message": "Product is already actively mapped to the target company."}'::JSONB;
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

