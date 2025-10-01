-- =====================================================
-- SAFE DIVISION WITH RECURSIVE ZERO CHECKING
-- =====================================================
-- This file contains PostgreSQL functions for safe mathematical
-- evaluation with recursive division by zero protection using NULLIF
-- =====================================================

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS safe_divide(NUMERIC, NUMERIC);
DROP FUNCTION IF EXISTS safe_calc_recursive(TEXT, NUMERIC[]);
DROP FUNCTION IF EXISTS safe_calc(TEXT, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC);
DROP FUNCTION IF EXISTS extract_divisions(TEXT);
DROP FUNCTION IF EXISTS check_division_safety(TEXT);

-- =====================================================
-- 1. BASIC SAFE DIVISION FUNCTION
-- =====================================================
-- Simple safe division using NULLIF to prevent division by zero
CREATE OR REPLACE FUNCTION safe_divide(
    numerator NUMERIC,
    denominator NUMERIC
) RETURNS NUMERIC AS $$
BEGIN
    -- Use NULLIF to return NULL if denominator is 0
    -- This prevents division by zero errors
    RETURN numerator / NULLIF(denominator, 0);
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Division by zero detected: % / %', numerator, denominator;
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in safe_divide: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. RECURSIVE DIVISION SAFETY CHECKER
-- =====================================================
-- Function to recursively check if an expression contains division by zero
CREATE OR REPLACE FUNCTION check_division_safety(
    expression TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    division_pattern TEXT := '\([^/]+\)/\([^/]+\)';  -- Pattern to match division operations
    matches TEXT[];
    match_record RECORD;
    numerator TEXT;
    denominator TEXT;
    denom_value NUMERIC;
    is_safe BOOLEAN := TRUE;
BEGIN
    RAISE NOTICE 'Checking division safety for: %', expression;
    
    -- Find all division operations using regex
    FOR match_record IN 
        SELECT regexp_matches(expression, '([^/\s]+)\s*/\s*([^/\s]+)', 'g') as match
    LOOP
        numerator := match_record.match[1];
        denominator := match_record.match[2];
        
        RAISE NOTICE 'Found division: % / %', numerator, denominator;
        
        -- Try to evaluate the denominator
        BEGIN
            -- Handle parentheses in denominator
            denominator := trim(both '()' from denominator);
            
            -- Check if denominator evaluates to zero
            EXECUTE 'SELECT (' || denominator || ')::NUMERIC' INTO denom_value;
            
            IF denom_value = 0 THEN
                RAISE NOTICE 'UNSAFE: Denominator evaluates to zero: %', denominator;
                RETURN FALSE;
            END IF;
            
            RAISE NOTICE 'SAFE: Denominator evaluates to: %', denom_value;
            
            -- If denominator contains division, check it recursively
            IF position('/' in denominator) > 0 THEN
                RAISE NOTICE 'Denominator contains division, checking recursively: %', denominator;
                IF NOT check_division_safety(denominator) THEN
                    RETURN FALSE;
                END IF;
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not evaluate denominator: % - Error: %', denominator, SQLERRM;
                -- Continue checking other divisions
        END;
    END LOOP;
    
    RAISE NOTICE 'Division safety check completed: %', CASE WHEN is_safe THEN 'SAFE' ELSE 'UNSAFE' END;
    RETURN is_safe;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. SAFE CALCULATION WITH RECURSIVE CHECKING
-- =====================================================
-- Main calculation function with recursive division by zero protection
CREATE OR REPLACE FUNCTION safe_calc_recursive(
    formula TEXT,
    variables NUMERIC[] DEFAULT ARRAY[]::NUMERIC[]
) RETURNS NUMERIC AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
    var_names TEXT[] := ARRAY['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];
    i INTEGER;
BEGIN
    RAISE NOTICE '=== SAFE RECURSIVE CALCULATION START ===';
    RAISE NOTICE 'Formula: %', formula;
    RAISE NOTICE 'Variables: %', variables;
    
    sql_expr := formula;
    
    -- Replace variables with their values
    FOR i IN 1..LEAST(array_length(variables, 1), array_length(var_names, 1))
    LOOP
        IF variables[i] IS NOT NULL THEN
            sql_expr := replace(sql_expr, var_names[i], '(' || variables[i]::TEXT || ')');
            RAISE NOTICE 'Replaced % with (%): %', var_names[i], variables[i], sql_expr;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Expression after substitution: %', sql_expr;
    
    -- Perform recursive division safety check
    RAISE NOTICE '--- DIVISION SAFETY CHECK ---';
    IF NOT check_division_safety(sql_expr) THEN
        RAISE EXCEPTION 'Division by zero detected in expression: %', sql_expr;
    END IF;
    
    RAISE NOTICE '--- SAFE CALCULATION ---';
    -- Replace all division operations with safe_divide calls
    -- This is a simplified approach - for complex expressions, you might need more sophisticated parsing
    sql_expr := regexp_replace(sql_expr, '([^/\s]+)\s*/\s*([^/\s]+)', 'safe_divide(\1, \2)', 'g');
    RAISE NOTICE 'Expression with safe_divide: %', sql_expr;
    
    -- Execute the safe calculation
    EXECUTE 'SELECT ' || sql_expr INTO result;
    
    RAISE NOTICE 'Calculation result: %', COALESCE(result::TEXT, 'NULL');
    RAISE NOTICE '=== SAFE RECURSIVE CALCULATION END ===';
    
    RETURN result;
    
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Division by zero error caught: %', SQLERRM;
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in safe_calc_recursive: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. CONVENIENT WRAPPER FUNCTION
-- =====================================================
-- Wrapper function with individual parameter support (like the original calc function)
CREATE OR REPLACE FUNCTION safe_calc(
    formula TEXT,
    a NUMERIC DEFAULT NULL,
    b NUMERIC DEFAULT NULL,
    c NUMERIC DEFAULT NULL,
    d NUMERIC DEFAULT NULL,
    e NUMERIC DEFAULT NULL,
    f NUMERIC DEFAULT NULL,
    g NUMERIC DEFAULT NULL,
    h NUMERIC DEFAULT NULL,
    i NUMERIC DEFAULT NULL,
    j NUMERIC DEFAULT NULL
) RETURNS NUMERIC AS $$
BEGIN
    RETURN safe_calc_recursive(
        formula, 
        ARRAY[a, b, c, d, e, f, g, h, i, j]
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. ENHANCED SAFE DIVISION WITH DETAILED LOGGING
-- =====================================================
-- More sophisticated safe division with better error handling
CREATE OR REPLACE FUNCTION safe_divide_enhanced(
    numerator NUMERIC,
    denominator NUMERIC,
    operation_context TEXT DEFAULT 'division'
) RETURNS NUMERIC AS $$
DECLARE
    safe_denominator NUMERIC;
    result NUMERIC;
BEGIN
    -- Use NULLIF to safely handle zero denominator
    safe_denominator := NULLIF(denominator, 0);
    
    IF safe_denominator IS NULL THEN
        RAISE NOTICE 'Division by zero prevented in %: % / 0', operation_context, numerator;
        RETURN NULL;
    END IF;
    
    result := numerator / safe_denominator;
    RAISE NOTICE 'Safe division completed: % / % = %', numerator, denominator, result;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in safe_divide_enhanced (%): %', operation_context, SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. COMPLEX EXPRESSION PARSER WITH SAFE DIVISIONS
-- =====================================================
-- Function to parse and safely evaluate complex mathematical expressions
CREATE OR REPLACE FUNCTION parse_and_safe_calc(
    formula TEXT,
    variables JSONB DEFAULT '{}'::JSONB
) RETURNS NUMERIC AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
    var_key TEXT;
    var_value NUMERIC;
BEGIN
    RAISE NOTICE '=== COMPLEX EXPRESSION PARSER START ===';
    RAISE NOTICE 'Formula: %', formula;
    RAISE NOTICE 'Variables: %', variables;
    
    sql_expr := formula;
    
    -- Replace variables using JSONB
    FOR var_key, var_value IN SELECT * FROM jsonb_each_text(variables)
    LOOP
        sql_expr := replace(sql_expr, var_key, '(' || var_value || ')');
        RAISE NOTICE 'Replaced % with (%)', var_key, var_value;
    END LOOP;
    
    RAISE NOTICE 'Expression after substitution: %', sql_expr;
    
    -- Check for division safety
    IF NOT check_division_safety(sql_expr) THEN
        RAISE EXCEPTION 'Unsafe division detected in: %', sql_expr;
    END IF;
    
    -- Execute with PostgreSQL's built-in BODMAS handling
    -- PostgreSQL automatically handles operator precedence
    EXECUTE 'SELECT (' || sql_expr || ')::NUMERIC' INTO result;
    
    -- Check for infinity or NaN
    IF result = 'Infinity'::NUMERIC OR result = '-Infinity'::NUMERIC OR result != result THEN
        RAISE NOTICE 'Result is infinite or NaN, returning NULL';
        RETURN NULL;
    END IF;
    
    RAISE NOTICE 'Final result: %', result;
    RAISE NOTICE '=== COMPLEX EXPRESSION PARSER END ===';
    
    RETURN result;
    
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Division by zero caught: %', SQLERRM;
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in parse_and_safe_calc: %', SQLERRM;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TEST CASES AND EXAMPLES
-- =====================================================

-- Test the functions
DO $$
BEGIN
    RAISE NOTICE '=== TESTING SAFE DIVISION FUNCTIONS ===';
    
    -- Test 1: Basic safe division
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1: Basic safe division';
    RAISE NOTICE 'safe_divide(10, 2) = %', safe_divide(10, 2);
    RAISE NOTICE 'safe_divide(10, 0) = %', safe_divide(10, 0);
    
    -- Test 2: Safe calculation with variables
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2: Safe calculation - x/y where y=0';
    RAISE NOTICE 'safe_calc(''a/b'', 10, 0) = %', safe_calc('a/b', 10, 0);
    
    -- Test 3: Complex expression that's safe
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3: Complex safe expression';
    RAISE NOTICE 'safe_calc(''a/(b+c)*d'', 12, 2, 3, 5) = %', safe_calc('a/(b+c)*d', 12, 2, 3, 5);
    
    -- Test 4: Complex expression with zero denominator
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4: Complex expression with zero denominator';
    RAISE NOTICE 'safe_calc(''a/(b-c)+d'', 10, 5, 5, 3) = %', safe_calc('a/(b-c)+d', 10, 5, 5, 3);
    
    -- Test 5: Using JSONB variables
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5: JSONB variable parsing';
    RAISE NOTICE 'parse_and_safe_calc(''x/y'', ''{"x": 20, "y": 4}'') = %', 
                 parse_and_safe_calc('x/y', '{"x": 20, "y": 4}'::JSONB);
    
    -- Test 6: JSONB with zero denominator
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 6: JSONB with zero denominator';
    RAISE NOTICE 'parse_and_safe_calc(''x/y'', ''{"x": 20, "y": 0}'') = %', 
                 parse_and_safe_calc('x/y', '{"x": 20, "y": 0}'::JSONB);
    
    RAISE NOTICE '';
    RAISE NOTICE '=== TESTING COMPLETE ===';
END $$;

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================

/*
USAGE EXAMPLES:
SELECT 10/2
1. Basic safe division:
   SELECT safe_divide(10, 2);  -- Returns 5
   SELECT safe_divide(10, 0);  -- Returns NULL

2. Safe calculation with individual parameters:
   SELECT safe_calc('a/b + c/d', 10, 2, 15, 3);  -- Returns 10
   SELECT safe_calc('a/b + c/d', 10, 2, 15, 0);  -- Returns NULL

3. Safe calculation with array parameters:
   SELECT safe_calc_recursive('a/b + c/d', ARRAY[10, 2, 15, 3]);

4. Using JSONB for variables:
   SELECT parse_and_safe_calc('x/y + z', '{"x": 10, "y": 2, "z": 3}'::JSONB);

5. Complex nested expressions:
   SELECT safe_calc('a/(b/(c+d))', 20, 8, 1, 1);  -- Returns 5
   SELECT safe_calc('a/(b/(c-d))', 20, 8, 3, 3);  -- Returns NULL (division by zero)

6. Multiple divisions:
   SELECT safe_calc('a/b + c/d + e/f', 10, 2, 15, 3, 20, 4);  -- Returns 15
*/
ALTER TABLE fospha_dashboards.fact 
ADD COLUMN activity_engaged_visits numeric;

select (20/(8/(3-3)))
select 3 - null
select null - 3





CREATE OR REPLACE FUNCTION bulk_safe_calc(
    formula TEXT,
    variable_names TEXT[],
    variable_values NUMERIC[]
) RETURNS NUMERIC AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
    i INTEGER;
    var_count INTEGER;
BEGIN
    sql_expr := formula;
    
    -- Fast array-based substitution without extensive logging
    var_count := LEAST(
        COALESCE(array_length(variable_names, 1), 0),
        COALESCE(array_length(variable_values, 1), 0)
    );
    
    FOR i IN 1..var_count
    LOOP
        IF variable_values[i] IS NOT NULL THEN
            sql_expr := replace(sql_expr, variable_names[i], '(' || variable_values[i]::TEXT || ')');
        ELSE
            sql_expr := replace(sql_expr, variable_names[i], 'NULL');
        END IF;
    END LOOP;
    
    -- Skip safety check for performance (rely on exception handling)
    EXECUTE 'SELECT (' || sql_expr || ')::NUMERIC' INTO result;
    
    -- Quick infinity/NaN check
    IF result = 'Infinity'::NUMERIC OR result = '-Infinity'::NUMERIC OR result != result THEN
        RETURN NULL;
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN division_by_zero THEN
	RAISE NOTICE 'CAME HERE';
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;


SELECT bulk_safe_calc(
        'x*y/z',
        ARRAY['x', 'y', 'z'],
        ARRAY[10, 5, 0]
    )

	
CREATE OR REPLACE FUNCTION owais_calc(
    formula TEXT,
    a NUMERIC DEFAULT NULL,
    b NUMERIC DEFAULT NULL,
    c NUMERIC DEFAULT NULL,
    d NUMERIC DEFAULT NULL,
    e NUMERIC DEFAULT NULL,
    f NUMERIC DEFAULT NULL,
    g NUMERIC DEFAULT NULL,
    h NUMERIC DEFAULT NULL,
    i NUMERIC DEFAULT NULL,
    j NUMERIC DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
    variables NUMERIC[];
    var_names TEXT[];
    idx INTEGER;
BEGIN
    sql_expr := formula;
    
    -- Set up default variable names and values
    var_names := ARRAY['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];
    variables := ARRAY[a, b, c, d, e, f, g, h, i, j];
    
    -- Fast variable substitution
    FOR idx IN 1..10
    LOOP
        IF variables[idx] IS NOT NULL THEN
            sql_expr := replace(sql_expr, var_names[idx], '(' || variables[idx]::TEXT || ')');
        ELSE
            sql_expr := replace(sql_expr, var_names[idx], 'NULL');
        END IF;
    END LOOP;
    
    -- Execute the calculation
    EXECUTE 'SELECT (' || sql_expr || ')::NUMERIC' INTO result;
    
    -- Handle special cases
    IF result = 'Infinity'::NUMERIC OR result = '-Infinity'::NUMERIC OR result != result THEN
        RETURN NULL;
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN division_by_zero THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;





-- =====================================================
-- OWAIS_CALC FUNCTION TESTS ONLY
-- =====================================================
-- Run this after creating the owais_calc function
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🧪 === COMPREHENSIVE OWAIS_CALC TEST SUITE ===';
    
    -- Basic arithmetic tests
    RAISE NOTICE '';
    RAISE NOTICE '📊 BASIC ARITHMETIC TESTS:';
    RAISE NOTICE 'Addition: owais_calc(''a+b'', 10, 5) = %', owais_calc('a+b', 10, 5);
    RAISE NOTICE 'Subtraction: owais_calc(''a-b'', 10, 3) = %', owais_calc('a-b', 10, 3);
    RAISE NOTICE 'Multiplication: owais_calc(''a*b'', 7, 8) = %', owais_calc('a*b', 7, 8);
    RAISE NOTICE 'Division: owais_calc(''a/b'', 20, 4) = %', owais_calc('a/b', 20, 4);
    
    -- BODMAS/Order of operations tests
    RAISE NOTICE '';
    RAISE NOTICE '🔢 BODMAS/ORDER OF OPERATIONS:';
    RAISE NOTICE 'a+b*c: owais_calc(''a+b*c'', 2, 3, 4) = % (should be 14)', owais_calc('a+b*c', 2, 3, 4);
    RAISE NOTICE '(a+b)*c: owais_calc(''(a+b)*c'', 2, 3, 4) = % (should be 20)', owais_calc('(a+b)*c', 2, 3, 4);
    RAISE NOTICE 'a/b+c: owais_calc(''a/b+c'', 10, 2, 3) = % (should be 8)', owais_calc('a/b+c', 10, 2, 3);
    RAISE NOTICE 'a/(b+c): owais_calc(''a/(b+c)'', 10, 2, 3) = % (should be 2)', owais_calc('a/(b+c)', 10, 2, 3);
    
    -- Complex nested expressions
    RAISE NOTICE '';
    RAISE NOTICE '🏗️ COMPLEX NESTED EXPRESSIONS:';
    RAISE NOTICE 'Nested: owais_calc(''((a+b)*c)/d'', 2, 3, 4, 2) = % (should be 10)', owais_calc('((a+b)*c)/d', 2, 3, 4, 2);
    RAISE NOTICE 'Multi-level: owais_calc(''(a-b)/(c+d)*e'', 10, 2, 3, 1, 5) = % (should be 10)', owais_calc('(a-b)/(c+d)*e', 10, 2, 3, 1, 5);
    RAISE NOTICE 'Deep nesting: owais_calc(''a/(b/(c+d))'', 20, 8, 1, 1) = % (should be 5)', owais_calc('a/(b/(c+d))', 20, 8, 1, 1);
    
    -- Division by zero safety tests
    RAISE NOTICE '';
    RAISE NOTICE '🛡️ DIVISION BY ZERO SAFETY:';
    RAISE NOTICE 'Direct zero: owais_calc(''a/b'', 10, 0) = % (should be NULL)', owais_calc('a/b', 10, 0);
    RAISE NOTICE 'Expression zero: owais_calc(''a/(b-c)'', 10, 5, 5) = % (should be NULL)', owais_calc('a/(b-c)', 10, 5, 5);
    RAISE NOTICE 'Nested zero: owais_calc(''a/(b/(c-d))'', 10, 8, 3, 3) = % (should be NULL)', owais_calc('a/(b/(c-d))', 10, 8, 3, 3);
    
    -- NULL value handling
    RAISE NOTICE '';
    RAISE NOTICE '❓ NULL VALUE HANDLING:';
    RAISE NOTICE 'NULL input: owais_calc(''a+b'', 10, NULL) = % (should be NULL)', owais_calc('a+b', 10, NULL);
    RAISE NOTICE 'NULL division: owais_calc(''a/b'', NULL, 5) = % (should be NULL)', owais_calc('a/b', NULL, 5);
    RAISE NOTICE 'Mixed NULL: owais_calc(''a+b+c'', 10, NULL, 5) = % (should be NULL)', owais_calc('a+b+c', 10, NULL, 5);
    
    -- Real-world business formulas
    RAISE NOTICE '';
    RAISE NOTICE '💼 REAL-WORLD BUSINESS FORMULAS:';
    RAISE NOTICE 'Profit Margin: owais_calc(''(a-b)/a*100'', 1000, 600) = % (should be 40)', owais_calc('(a-b)/a*100', 1000, 600);
    RAISE NOTICE 'ROI: owais_calc(''(a-b)/b*100'', 1200, 1000) = % (should be 20)', owais_calc('(a-b)/b*100', 1200, 1000);
    RAISE NOTICE 'Efficiency: owais_calc(''a/(b+c)'', 1000, 200, 50) = % (should be 4)', owais_calc('a/(b+c)', 1000, 200, 50);
    RAISE NOTICE 'Growth Rate: owais_calc(''(a-b)/b*100'', 150, 100) = % (should be 50)', owais_calc('(a-b)/b*100', 150, 100);
    
    -- Edge cases and stress tests
    RAISE NOTICE '';
    RAISE NOTICE '⚡ EDGE CASES & STRESS TESTS:';
    RAISE NOTICE 'Very small numbers: owais_calc(''a/b'', 0.001, 0.0001) = %', owais_calc('a/b', 0.001, 0.0001);
    RAISE NOTICE 'Large numbers: owais_calc(''a*b'', 1000000, 1000) = %', owais_calc('a*b', 1000000, 1000);
    RAISE NOTICE 'Negative numbers: owais_calc(''a/b'', -100, 20) = % (should be -5)', owais_calc('a/b', -100, 20);
    RAISE NOTICE 'Mixed signs: owais_calc(''(a+b)*c'', -10, 15, -2) = % (should be -10)', owais_calc('(a+b)*c', -10, 15, -2);
    
    -- All 10 variables test
    RAISE NOTICE '';
    RAISE NOTICE '🔟 ALL 10 VARIABLES TEST:';
    RAISE NOTICE 'Using a-j: owais_calc(''a+b+c+d+e+f+g+h+i+j'', 1,2,3,4,5,6,7,8,9,10) = % (should be 55)', 
                 owais_calc('a+b+c+d+e+f+g+h+i+j', 1,2,3,4,5,6,7,8,9,10);
    RAISE NOTICE 'Complex with all: owais_calc(''(a+b+c)/(d+e)*f'', 1,2,3,4,1,10) = % (should be 12)', 
                 owais_calc('(a+b+c)/(d+e)*f', 1,2,3,4,1,10);
    
    -- Performance indicators
    RAISE NOTICE '';
    RAISE NOTICE '🚀 PERFORMANCE TEST (should be very fast):';
    RAISE NOTICE 'Complex calc: owais_calc(''((a*b)+(c*d))/(e+f)'', 10,20,30,40,50,100) = %', 
                 owais_calc('((a*b)+(c*d))/(e+f)', 10,20,30,40,50,100);
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ === OWAIS_CALC TEST SUITE COMPLETE ===';
    RAISE NOTICE '💡 All tests above should show expected results for validation';
END $$;

-- =====================================================
-- QUICK INDIVIDUAL TESTS (uncomment to run specific tests)
-- =====================================================

-- Test basic division
-- SELECT owais_calc('a/b', 100, 20) as basic_division;

-- Test profit margin calculation
-- SELECT owais_calc('(a-b)/a*100', 1000, 600) as profit_margin;

-- Test complex business formula
-- SELECT owais_calc('(a*b+c)/(d+e)', 10, 5, 20, 30, 40) as complex_business;

-- Test division by zero safety
-- SELECT owais_calc('a/b', 100, 0) as division_by_zero_test;

-- Test with your actual table data
-- SELECT 
--     id,
--     revenue,
--     cost,
--     owais_calc('a/b', revenue, cost) as efficiency_ratio,
--     owais_calc('(a-b)/a*100', revenue, cost) as profit_margin
-- FROM your_table_name 
-- LIMIT 10;



select owais_calc_coalesce('a+b/0', 5, 6) 
CREATE OR REPLACE FUNCTION owais_calc_coalesce(
    formula TEXT,
    a NUMERIC DEFAULT NULL,
    b NUMERIC DEFAULT NULL,
    c NUMERIC DEFAULT NULL,
    d NUMERIC DEFAULT NULL,
    e NUMERIC DEFAULT NULL,
    f NUMERIC DEFAULT NULL,
    g NUMERIC DEFAULT NULL,
    h NUMERIC DEFAULT NULL,
    i NUMERIC DEFAULT NULL,
    j NUMERIC DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
    variables NUMERIC[];
    var_names TEXT[];
    idx INTEGER;
BEGIN
    sql_expr := formula;
    
    -- Set up default variable names and values
    var_names := ARRAY['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];
    variables := ARRAY[a, b, c, d, e, f, g, h, i, j];
    
    -- Variable substitution: COALESCE NULL variables to 0
    FOR idx IN 1..10
    LOOP
        IF variables[idx] IS NOT NULL THEN
            -- Ensure NUMERIC precision for exact calculations
            sql_expr := replace(sql_expr, var_names[idx], '(' || variables[idx]::NUMERIC::TEXT || ')');
        ELSE
            -- NULL variables become 0 during substitution
            sql_expr := replace(sql_expr, var_names[idx], '0');
        END IF;
    END LOOP;
    
    -- Execute the calculation
    EXECUTE 'SELECT (' || sql_expr || ')::NUMERIC' INTO result;
    
    -- Keep calculation-generated NULLs (like Infinity, NaN)
    IF result = 'Infinity'::NUMERIC OR result = '-Infinity'::NUMERIC OR result != result THEN
        RETURN NULL;
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN division_by_zero THEN
        -- Keep division by zero as NULL (don't convert to 0)
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- TEST CASES
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔄 === COALESCE DEMONSTRATION ===';
    
    -- Example 1: NULL variable input
    RAISE NOTICE '';
    RAISE NOTICE '📋 EXAMPLE 1: NULL VARIABLE INPUT';
    RAISE NOTICE 'Regular owais_calc(''a+b'', 10, NULL):';
    RAISE NOTICE '  -> Result: % (NULL variable makes everything NULL)', owais_calc('a+b', 10, NULL);
    RAISE NOTICE '';
    RAISE NOTICE 'Coalesce owais_calc_coalesce(''a+b'', 10, NULL):';
    RAISE NOTICE '  -> Result: % (NULL variable becomes 0, so 10+0=10)', owais_calc_coalesce('a+b', 10, NULL);
    
    -- Example 2: Division by zero (calculation-generated NULL)
    RAISE NOTICE '';
    RAISE NOTICE '📋 EXAMPLE 2: DIVISION BY ZERO (CALCULATION NULL)';
    RAISE NOTICE 'Regular owais_calc(''a/b'', 10, 0):';
    RAISE NOTICE '  -> Result: % (division by zero -> NULL)', owais_calc('a/b', 10, 0);
    RAISE NOTICE '';
    RAISE NOTICE 'Coalesce owais_calc_coalesce(''a/b'', 10, 0):';
    RAISE NOTICE '  -> Result: % (division by zero -> still NULL)', owais_calc_coalesce('a/b', 10, 0);
    
    -- Example 3: NULL variable that would cause division by zero
    RAISE NOTICE '';
    RAISE NOTICE '📋 EXAMPLE 3: NULL VARIABLE IN DENOMINATOR';
    RAISE NOTICE 'Regular owais_calc(''a/b'', 100, NULL):';
    RAISE NOTICE '  -> Result: % (NULL variable -> NULL)', owais_calc('a/b', 100, NULL);
    RAISE NOTICE '';
    RAISE NOTICE 'Coalesce owais_calc_coalesce(''a/b'', 100, NULL):';
    RAISE NOTICE '  -> Result: % (NULL becomes 0, so 100/0 -> div by zero NULL)', owais_calc_coalesce('a/b', 100, NULL);
    
    -- Example 4: Practical business case
    RAISE NOTICE '';
    RAISE NOTICE '📋 EXAMPLE 4: BUSINESS CASE - OPTIONAL BONUS';
    RAISE NOTICE 'Base salary + bonus (bonus might be NULL):';
    RAISE NOTICE 'Regular owais_calc(''a+b'', 5000, NULL):';
    RAISE NOTICE '  -> Result: % (missing bonus makes total NULL)', owais_calc('a+b', 5000, NULL);
    RAISE NOTICE '';
    RAISE NOTICE 'Coalesce owais_calc_coalesce(''a+b'', 5000, NULL):';
    RAISE NOTICE '  -> Result: % (missing bonus treated as 0)', owais_calc_coalesce('a+b', 5000, NULL);
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ === SUMMARY ===';
    RAISE NOTICE '• owais_calc: NULL variables -> NULL result';
    RAISE NOTICE '• owais_calc_coalesce: NULL variables -> treated as 0';
    RAISE NOTICE '• Both keep calculation NULLs (like div by zero) as NULL';
END $$;

-- =====================================================
-- PRACTICAL USAGE EXAMPLES
-- =====================================================

-- Use case 1: Revenue calculation where some components might be missing
-- SELECT 
--     id,
--     base_revenue,
--     bonus_revenue,  -- Might be NULL
--     -- Conservative approach: NULL bonus makes total NULL
--     owais_calc('a+b', base_revenue, bonus_revenue) as total_conservative,
--     -- Optimistic approach: NULL bonus treated as 0
--     owais_calc_coalesce('a+b', base_revenue, bonus_revenue) as total_optimistic
-- FROM revenue_table;

-- Use case 2: Cost calculation with optional expenses
-- SELECT 
--     id,
--     fixed_cost,
--     variable_cost,  -- Might be NULL
--     marketing_cost, -- Might be NULL
--     -- Only calculate if all costs are known
--     owais_calc('a+b+c', fixed_cost, variable_cost, marketing_cost) as total_cost_strict,
--     -- Treat missing costs as 0
--     owais_calc_coalesce('a+b+c', fixed_cost, variable_cost, marketing_cost) as total_cost_permissive
-- FROM cost_table;

Visits

Clicks

Costs

Impressions

(Fospha) Conversions

(Fospha) New Customers

(Fospha) Revenue

(Fospha) New Revenue

 "expression": "(fa_conversions+fa_revenue)",

type Custom_Metric @model @auth(rules: [{ allow: private, provider: iam }]) {
  id: ID!
  name: String #poas, ctr, etc.
  client_id: String
  expression: String
  type: String  #number, percentage, currency
  performance_direction: String #higher_is_better, lower_is_better
  description: String
}
select owais_calc_coalesce('a/b+c/d', 10, 2, 2, 0)

SELECT 
(select owais_calc_coalesce('a/b', (SUM(fact.ad_spend * exchange_rates.exchange_rate)),
(SUM(fact.fa_revenue * exchange_rates.exchange_rate)))) as cos
from 
fospha_dashboards.fact limit 10

COS (Cost of Sales)
Cost / Revenue
COALESCE(COALESCE(SUM( fact.ad_spend * exchange_rates.exchange_rate ), 0) / 
nullif(COALESCE(SUM( fact.fa_revenue * exchange_rates.exchange_rate ), 0), 0), 0)



















-- =====================================================
-- OWAIS_CALC_COALESCE: COMPREHENSIVE SCENARIOS & TEST CASES
-- =====================================================
-- This file shows expected behavior of owais_calc_coalesce function
-- NULL variables are treated as 0, calculation NULLs remain NULL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🧪 === OWAIS_CALC_COALESCE COMPREHENSIVE SCENARIOS ===';
    
    -- =====================================================
    -- SCENARIO 1: BASIC ARITHMETIC WITH NULL VARIABLES
    -- =====================================================
    RAISE NOTICE '';
    RAISE NOTICE '📊 SCENARIO 1: BASIC ARITHMETIC WITH NULL VARIABLES';
    
    -- Addition with NULL
    RAISE NOTICE '';
    RAISE NOTICE 'Addition Tests:';
    RAISE NOTICE 'owais_calc_coalesce(''a+b'', 10, 5) = % (Expected: 15)', owais_calc_coalesce('a+b', 10, 5);
    RAISE NOTICE 'owais_calc_coalesce(''a+b'', 10, NULL) = % (Expected: 10)', owais_calc_coalesce('a+b', 10, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a+b'', NULL, 5) = % (Expected: 5)', owais_calc_coalesce('a+b', NULL, 5);
    RAISE NOTICE 'owais_calc_coalesce(''a+b'', NULL, NULL) = % (Expected: 0)', owais_calc_coalesce('a+b', NULL, NULL);
    
    -- Subtraction with NULL
    RAISE NOTICE '';
    RAISE NOTICE 'Subtraction Tests:';
    RAISE NOTICE 'owais_calc_coalesce(''a-b'', 10, 3) = % (Expected: 7)', owais_calc_coalesce('a-b', 10, 3);
    RAISE NOTICE 'owais_calc_coalesce(''a-b'', 10, NULL) = % (Expected: 10)', owais_calc_coalesce('a-b', 10, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a-b'', NULL, 3) = % (Expected: -3)', owais_calc_coalesce('a-b', NULL, 3);
    RAISE NOTICE 'owais_calc_coalesce(''a-b'', NULL, NULL) = % (Expected: 0)', owais_calc_coalesce('a-b', NULL, NULL);
    
    -- Multiplication with NULL
    RAISE NOTICE '';
    RAISE NOTICE 'Multiplication Tests:';
    RAISE NOTICE 'owais_calc_coalesce(''a*b'', 5, 4) = % (Expected: 20)', owais_calc_coalesce('a*b', 5, 4);
    RAISE NOTICE 'owais_calc_coalesce(''a*b'', 5, NULL) = % (Expected: 0)', owais_calc_coalesce('a*b', 5, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a*b'', NULL, 4) = % (Expected: 0)', owais_calc_coalesce('a*b', NULL, 4);
    RAISE NOTICE 'owais_calc_coalesce(''a*b'', NULL, NULL) = % (Expected: 0)', owais_calc_coalesce('a*b', NULL, NULL);
    
    -- Division with NULL
    RAISE NOTICE '';
    RAISE NOTICE 'Division Tests:';
    RAISE NOTICE 'owais_calc_coalesce(''a/b'', 20, 4) = % (Expected: 5)', owais_calc_coalesce('a/b', 20, 4);
    RAISE NOTICE 'owais_calc_coalesce(''a/b'', 20, NULL) = % (Expected: NULL - div by 0)', owais_calc_coalesce('a/b', 20, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a/b'', NULL, 4) = % (Expected: 0)', owais_calc_coalesce('a/b', NULL, 4);
    RAISE NOTICE 'owais_calc_coalesce(''a/b'', NULL, NULL) = % (Expected: NULL - div by 0)', owais_calc_coalesce('a/b', NULL, NULL);
    
    -- =====================================================
    -- SCENARIO 2: BUSINESS FORMULAS WITH MISSING DATA
    -- =====================================================
    RAISE NOTICE '';
    RAISE NOTICE '💼 SCENARIO 2: BUSINESS FORMULAS WITH MISSING DATA';
    
    -- Revenue calculation (base + bonus)
    RAISE NOTICE '';
    RAISE NOTICE 'Revenue Calculation (base + bonus):';
    RAISE NOTICE 'owais_calc_coalesce(''a+b'', 5000, 1000) = % (Expected: 6000)', owais_calc_coalesce('a+b', 5000, 1000);
    RAISE NOTICE 'owais_calc_coalesce(''a+b'', 5000, NULL) = % (Expected: 5000 - no bonus)', owais_calc_coalesce('a+b', 5000, NULL);
    
    -- Profit calculation (revenue - cost)
    RAISE NOTICE '';
    RAISE NOTICE 'Profit Calculation (revenue - cost):';
    RAISE NOTICE 'owais_calc_coalesce(''a-b'', 10000, 7000) = % (Expected: 3000)', owais_calc_coalesce('a-b', 10000, 7000);
    RAISE NOTICE 'owais_calc_coalesce(''a-b'', 10000, NULL) = % (Expected: 10000 - no costs)', owais_calc_coalesce('a-b', 10000, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a-b'', NULL, 7000) = % (Expected: -7000 - loss)', owais_calc_coalesce('a-b', NULL, 7000);
    
    -- Profit margin percentage
    RAISE NOTICE '';
    RAISE NOTICE 'Profit Margin Percent ((revenue-cost)/revenue*100):';
    RAISE NOTICE 'owais_calc_coalesce(''(a-b)/a*100'', 1000, 600) = % (Expected: 40)', owais_calc_coalesce('(a-b)/a*100', 1000, 600);
    RAISE NOTICE 'owais_calc_coalesce(''(a-b)/a*100'', 1000, NULL) = % (Expected: 100)', owais_calc_coalesce('(a-b)/a*100', 1000, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''(a-b)/a*100'', NULL, 600) = % (Expected: NULL - div by 0)', owais_calc_coalesce('(a-b)/a*100', NULL, 600);
    
    -- ROI calculation
    RAISE NOTICE '';
    RAISE NOTICE 'ROI Percent ((profit)/investment*100):';
    RAISE NOTICE 'owais_calc_coalesce(''a/b*100'', 500, 2000) = % (Expected: 25)', owais_calc_coalesce('a/b*100', 500, 2000);
    RAISE NOTICE 'owais_calc_coalesce(''a/b*100'', 500, NULL) = % (Expected: NULL - div by 0)', owais_calc_coalesce('a/b*100', 500, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a/b*100'', NULL, 2000) = % (Expected: 0)', owais_calc_coalesce('a/b*100', NULL, 2000);
    
    -- =====================================================
    -- SCENARIO 3: COMPLEX MULTI-VARIABLE FORMULAS
    -- =====================================================
    RAISE NOTICE '';
    RAISE NOTICE '🏗️ SCENARIO 3: COMPLEX MULTI-VARIABLE FORMULAS';
    
    -- Total cost (fixed + variable + overhead)
    RAISE NOTICE '';
    RAISE NOTICE 'Total Cost (fixed + variable + overhead):';
    RAISE NOTICE 'owais_calc_coalesce(''a+b+c'', 1000, 500, 200) = % (Expected: 1700)', owais_calc_coalesce('a+b+c', 1000, 500, 200);
    RAISE NOTICE 'owais_calc_coalesce(''a+b+c'', 1000, NULL, 200) = % (Expected: 1200)', owais_calc_coalesce('a+b+c', 1000, NULL, 200);
    RAISE NOTICE 'owais_calc_coalesce(''a+b+c'', 1000, NULL, NULL) = % (Expected: 1000)', owais_calc_coalesce('a+b+c', 1000, NULL, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a+b+c'', NULL, NULL, NULL) = % (Expected: 0)', owais_calc_coalesce('a+b+c', NULL, NULL, NULL);
    
    -- Weighted average calculation
    RAISE NOTICE '';
    RAISE NOTICE 'Weighted Average ((a*b + c*d)/(b+d)):';
    RAISE NOTICE 'owais_calc_coalesce(''(a*b + c*d)/(b+d)'', 80, 3, 90, 2) = % (Expected: 84)', owais_calc_coalesce('(a*b + c*d)/(b+d)', 80, 3, 90, 2);
    RAISE NOTICE 'owais_calc_coalesce(''(a*b + c*d)/(b+d)'', 80, 3, NULL, 2) = % (Expected: 80)', owais_calc_coalesce('(a*b + c*d)/(b+d)', 80, 3, NULL, 2);
    RAISE NOTICE 'owais_calc_coalesce(''(a*b + c*d)/(b+d)'', 80, NULL, 90, 2) = % (Expected: 90)', owais_calc_coalesce('(a*b + c*d)/(b+d)', 80, NULL, 90, 2);
    RAISE NOTICE 'owais_calc_coalesce(''(a*b + c*d)/(b+d)'', 80, NULL, 90, NULL) = % (Expected: NULL - div by 0)', owais_calc_coalesce('(a*b + c*d)/(b+d)', 80, NULL, 90, NULL);
    
    -- Efficiency ratio with buffer
    RAISE NOTICE '';
    RAISE NOTICE 'Efficiency Ratio (output/(input+buffer)):';
    RAISE NOTICE 'owais_calc_coalesce(''a/(b+c)'', 1000, 800, 50) = % (Expected: 1.176...)', owais_calc_coalesce('a/(b+c)', 1000, 800, 50);
    RAISE NOTICE 'owais_calc_coalesce(''a/(b+c)'', 1000, 800, NULL) = % (Expected: 1.25)', owais_calc_coalesce('a/(b+c)', 1000, 800, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a/(b+c)'', 1000, NULL, 50) = % (Expected: 20)', owais_calc_coalesce('a/(b+c)', 1000, NULL, 50);
    RAISE NOTICE 'owais_calc_coalesce(''a/(b+c)'', NULL, 800, 50) = % (Expected: 0)', owais_calc_coalesce('a/(b+c)', NULL, 800, 50);
    
    -- =====================================================
    -- SCENARIO 4: EDGE CASES & DIVISION BY ZERO
    -- =====================================================
    RAISE NOTICE '';
    RAISE NOTICE '⚡ SCENARIO 4: EDGE CASES & DIVISION BY ZERO';
    
    -- Various division by zero scenarios
    RAISE NOTICE '';
    RAISE NOTICE 'Division by Zero Cases:';
    RAISE NOTICE 'owais_calc_coalesce(''a/b'', 100, 0) = % (Expected: NULL)', owais_calc_coalesce('a/b', 100, 0);
    RAISE NOTICE 'owais_calc_coalesce(''a/(b-c)'', 100, 5, 5) = % (Expected: NULL)', owais_calc_coalesce('a/(b-c)', 100, 5, 5);
    RAISE NOTICE 'owais_calc_coalesce(''a/(b-c)'', 100, 5, NULL) = % (Expected: 20)', owais_calc_coalesce('a/(b-c)', 100, 5, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a/(b+c-d)'', 100, 10, 5, 15) = % (Expected: NULL)', owais_calc_coalesce('a/(b+c-d)', 100, 10, 5, 15);
    
    -- Nested division
    RAISE NOTICE '';
    RAISE NOTICE 'Nested Division Cases:';
    RAISE NOTICE 'owais_calc_coalesce(''a/(b/(c+d))'', 20, 8, 1, 1) = % (Expected: 5)', owais_calc_coalesce('a/(b/(c+d))', 20, 8, 1, 1);
    RAISE NOTICE 'owais_calc_coalesce(''a/(b/(c+d))'', 20, 8, NULL, 1) = % (Expected: 20)', owais_calc_coalesce('a/(b/(c+d))', 20, 8, NULL, 1);
    RAISE NOTICE 'owais_calc_coalesce(''a/(b/(c+d))'', 20, 8, NULL, NULL) = % (Expected: NULL - div by 0)', owais_calc_coalesce('a/(b/(c+d))', 20, 8, NULL, NULL);
    
    -- =====================================================
    -- SCENARIO 5: REAL-WORLD ANALYTICS FORMULAS
    -- =====================================================
    RAISE NOTICE '';
    RAISE NOTICE '📈 SCENARIO 5: REAL-WORLD ANALYTICS FORMULAS';
    
    -- Customer metrics
    RAISE NOTICE '';
    RAISE NOTICE 'Customer Metrics:';
    RAISE NOTICE 'Customer Lifetime Value (revenue*months/churn_rate):';
    RAISE NOTICE 'owais_calc_coalesce(''a*b/c'', 100, 12, 0.1) = % (Expected: 12000)', owais_calc_coalesce('a*b/c', 100, 12, 0.1);
    RAISE NOTICE 'owais_calc_coalesce(''a*b/c'', 100, NULL, 0.1) = % (Expected: 0)', owais_calc_coalesce('a*b/c', 100, NULL, 0.1);
    RAISE NOTICE 'owais_calc_coalesce(''a*b/c'', 100, 12, NULL) = % (Expected: NULL - div by 0)', owais_calc_coalesce('a*b/c', 100, 12, NULL);
    
    -- Conversion rates
    RAISE NOTICE '';
    RAISE NOTICE 'Conversion Rate (conversions/visits*100):';
    RAISE NOTICE 'owais_calc_coalesce(''a/b*100'', 50, 1000) = % (Expected: 5)', owais_calc_coalesce('a/b*100', 50, 1000);
    RAISE NOTICE 'owais_calc_coalesce(''a/b*100'', NULL, 1000) = % (Expected: 0)', owais_calc_coalesce('a/b*100', NULL, 1000);
    RAISE NOTICE 'owais_calc_coalesce(''a/b*100'', 50, NULL) = % (Expected: NULL - div by 0)', owais_calc_coalesce('a/b*100', 50, NULL);
    
    -- Growth rate calculation
    RAISE NOTICE '';
    RAISE NOTICE 'Growth Rate ((current-previous)/previous*100):';
    RAISE NOTICE 'owais_calc_coalesce(''(a-b)/b*100'', 1200, 1000) = % (Expected: 20)', owais_calc_coalesce('(a-b)/b*100', 1200, 1000);
    RAISE NOTICE 'owais_calc_coalesce(''(a-b)/b*100'', 1200, NULL) = % (Expected: NULL - div by 0)', owais_calc_coalesce('(a-b)/b*100', 1200, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''(a-b)/b*100'', NULL, 1000) = % (Expected: -100)', owais_calc_coalesce('(a-b)/b*100', NULL, 1000);
    
    -- =====================================================
    -- SCENARIO 6: MIXED POSITIVE/NEGATIVE/ZERO VALUES
    -- =====================================================
    RAISE NOTICE '';
    RAISE NOTICE '➕➖ SCENARIO 6: MIXED POSITIVE/NEGATIVE/ZERO VALUES';
    
    RAISE NOTICE '';
    RAISE NOTICE 'Mixed Sign Calculations:';
    RAISE NOTICE 'owais_calc_coalesce(''a+b'', -100, 50) = % (Expected: -50)', owais_calc_coalesce('a+b', -100, 50);
    RAISE NOTICE 'owais_calc_coalesce(''a+b'', -100, NULL) = % (Expected: -100)', owais_calc_coalesce('a+b', -100, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a*b'', -10, 5) = % (Expected: -50)', owais_calc_coalesce('a*b', -10, 5);
    RAISE NOTICE 'owais_calc_coalesce(''a*b'', -10, NULL) = % (Expected: 0)', owais_calc_coalesce('a*b', -10, NULL);
    RAISE NOTICE 'owais_calc_coalesce(''a/b'', -100, -5) = % (Expected: 20)', owais_calc_coalesce('a/b', -100, -5);
    RAISE NOTICE 'owais_calc_coalesce(''a/b'', -100, NULL) = % (Expected: NULL - div by 0)', owais_calc_coalesce('a/b', -100, NULL);
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ === SUMMARY OF owais_calc_coalesce BEHAVIOR ===';
    RAISE NOTICE '• NULL input variables → treated as 0';
    RAISE NOTICE '• Division by zero → returns NULL';
    RAISE NOTICE '• Calculation errors → return NULL';
    RAISE NOTICE '• All other calculations proceed normally';
    RAISE NOTICE '• Perfect for handling missing/optional data';
END $$;

-- =====================================================
-- QUICK REFERENCE TABLE
-- =====================================================

/*
QUICK REFERENCE: owais_calc_coalesce Expected Outputs

BASIC OPERATIONS:
owais_calc_coalesce('a+b', 10, 5)    → 15
owais_calc_coalesce('a+b', 10, NULL) → 10 (NULL becomes 0)
owais_calc_coalesce('a-b', 10, NULL) → 10 (NULL becomes 0)
owais_calc_coalesce('a*b', 10, NULL) → 0  (10 * 0 = 0)
owais_calc_coalesce('a/b', 10, NULL) → NULL (10/0 = division by zero)

BUSINESS FORMULAS:
owais_calc_coalesce('(a-b)/a*100', 1000, 600)  → 40 (profit margin)
owais_calc_coalesce('(a-b)/a*100', 1000, NULL) → 100 (no costs)
owais_calc_coalesce('a/(b+c)', 100, 80, NULL)   → 1.25 (no overhead)
owais_calc_coalesce('a+b+c', 100, NULL, NULL)   → 100 (missing components)

DIVISION BY ZERO:
owais_calc_coalesce('a/b', 100, 0)     → NULL
owais_calc_coalesce('a/(b-c)', 10, 5, 5) → NULL
owais_calc_coalesce('a/b', 100, NULL)  → NULL (NULL becomes 0)

EDGE CASES:
owais_calc_coalesce('a+b', NULL, NULL) → 0
owais_calc_coalesce('a*b', NULL, NULL) → 0  
owais_calc_coalesce('a/b', NULL, NULL) → NULL (0/0)
*/

CREATE OR REPLACE FUNCTION safe_calc(
    formula TEXT,
    a NUMERIC DEFAULT NULL,
    b NUMERIC DEFAULT NULL,
    c NUMERIC DEFAULT NULL,
    d NUMERIC DEFAULT NULL,
    e NUMERIC DEFAULT NULL,
    f NUMERIC DEFAULT NULL,
    g NUMERIC DEFAULT NULL,
    h NUMERIC DEFAULT NULL,
    i NUMERIC DEFAULT NULL,
    j NUMERIC DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE
    sql_expr TEXT;
    result NUMERIC;
    variables NUMERIC[];
    var_names TEXT[];
    idx INTEGER;
BEGIN
    sql_expr := formula;
    
    -- Set up default variable names and values
    var_names := ARRAY['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];
    variables := ARRAY[a, b, c, d, e, f, g, h, i, j];
    
    -- Variable substitution: COALESCE NULL variables to 0
    FOR idx IN 1..10
    LOOP
        IF variables[idx] IS NOT NULL THEN
            -- Ensure NUMERIC precision for exact calculations
            sql_expr := replace(sql_expr, var_names[idx], '(' || variables[idx]::NUMERIC::TEXT || '::NUMERIC)');
        ELSE
            -- NULL variables become 0.0 for decimal calculations
            sql_expr := replace(sql_expr, var_names[idx], '0.0::NUMERIC');
        END IF;
    END LOOP;
    
    -- Execute the calculation with decimal precision
    EXECUTE 'SELECT (' || sql_expr || ')::NUMERIC(20,10)' INTO result;
    
    -- Keep calculation-generated NULLs (like Infinity, NaN)
    IF result = 'Infinity'::NUMERIC OR result = '-Infinity'::NUMERIC OR result != result THEN
        RETURN NULL;
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN division_by_zero THEN
        -- Keep division by zero as NULL (don't convert to 0)
        RETURN NULL;
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;



Select 'a', 'b', 
(
select owais_calc_coalesce('a/(b+c)', 1000, 800, 50)
)


