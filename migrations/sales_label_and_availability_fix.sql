-- Ensure SOLD label exists and adjust sales + availability to use SOLD label instead of deactivating mappings

-- 1) Seed SOLD label if missing
DO $$
DECLARE
  lbl_id INT;
BEGIN
  SELECT id INTO lbl_id FROM label WHERE name = 'SOLD' AND active = TRUE LIMIT 1;
  IF lbl_id IS NULL THEN
    INSERT INTO label(name, description, active) VALUES ('SOLD', 'Sold mapping', TRUE);
  END IF;
END $$;

-- 2) Update record_product_sales to mark mappings as SOLD (keep active), and record sale
DROP FUNCTION IF EXISTS record_product_sales(JSONB, INT, TEXT, INT);
CREATE OR REPLACE FUNCTION record_product_sales(
  p_items JSONB,
  p_company_lid INT,
  p_notes TEXT,
  p_created_by INT
) RETURNS JSONB AS $$
DECLARE
  item RECORD;
  to_sell INT;
  sold INT := 0;
  errors TEXT[] := ARRAY[]::TEXT[];
  mappings RECORD;
  sold_label_id INT;
BEGIN
  SELECT id INTO sold_label_id FROM label WHERE name = 'SOLD' AND active = TRUE LIMIT 1;
  IF sold_label_id IS NULL THEN
    RETURN jsonb_build_object('status','error','message','SOLD label missing');
  END IF;

  IF p_items IS NULL OR jsonb_typeof(p_items) != 'array' OR jsonb_array_length(p_items) = 0 THEN
    RETURN jsonb_build_object('status','error','message','No items to sell');
  END IF;

  FOR item IN (
    SELECT (value->>'id')::INT AS product_id, GREATEST(1, COALESCE((value->>'qty')::INT, 1)) AS qty
    FROM jsonb_array_elements(p_items)
  ) LOOP
    to_sell := item.qty;

    FOR mappings IN (
      SELECT id
      FROM product_company_mapping
      WHERE active = TRUE AND company_lid = p_company_lid AND product_lid = item.product_id
            AND id NOT IN (
              SELECT pcm.id FROM product_company_mapping pcm
              JOIN label l ON l.id = pcm.label_lid AND l.name = 'SOLD'
              WHERE pcm.active = TRUE AND pcm.company_lid = p_company_lid AND pcm.product_lid = item.product_id
            )
      ORDER BY created_at ASC
    ) LOOP
      EXIT WHEN to_sell <= 0;
      -- Mark this mapping as SOLD but keep it active/visible
      UPDATE product_company_mapping
      SET label_lid = sold_label_id, updated_at = CURRENT_TIMESTAMP, updated_by = p_created_by
      WHERE id = mappings.id;
      to_sell := to_sell - 1;
      sold := sold + 1;
    END LOOP;

    -- Record sale record for actual sold count
    INSERT INTO product_sale(product_lid, company_lid, quantity, notes, created_by)
    VALUES (item.product_id, p_company_lid, (item.qty - GREATEST(to_sell,0)), p_notes, p_created_by);

    IF to_sell > 0 THEN
      errors := array_append(errors, 'Insufficient mappings to sell ' || to_sell || ' unit(s) of product ID ' || item.product_id);
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'status', CASE WHEN array_length(errors,1) IS NULL THEN 'success' ELSE 'partial' END,
    'message', 'Recorded sales for ' || sold || ' unit(s)',
    'data', jsonb_build_object('sold_units', sold, 'errors', errors)
  );
END;
$$ LANGUAGE plpgsql;

-- 3) Availability: count mapped units excluding SOLD label; subtract sold quantity
DROP FUNCTION IF EXISTS get_product_availability(INT);
CREATE OR REPLACE FUNCTION get_product_availability(
  p_product_id INT
) RETURNS JSONB AS $$
DECLARE
  total_units INT := 0;
  mapped_units INT := 0;
  sold_units INT := 0;
  available_units INT := 0;
  mapped_list JSONB := '[]'::JSONB;
BEGIN
  SELECT unit INTO total_units FROM product WHERE id = p_product_id AND active = TRUE;
  IF total_units IS NULL THEN
    RETURN jsonb_build_object('status','error','message','Product not found or inactive');
  END IF;

  SELECT COUNT(*) INTO mapped_units
  FROM product_company_mapping pcm
  JOIN label l ON l.id = pcm.label_lid
  WHERE pcm.product_lid = p_product_id AND pcm.active = TRUE AND COALESCE(l.name,'') <> 'SOLD';

  SELECT COALESCE(SUM(quantity),0) INTO sold_units
  FROM product_sale
  WHERE product_lid = p_product_id AND active = TRUE;

  available_units := GREATEST(0, total_units - mapped_units - sold_units);

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

  RETURN jsonb_build_object(
    'status','success',
    'data', jsonb_build_object(
      'total_units', total_units,
      'mapped_units', mapped_units,
      'sold_units', sold_units,
      'available_units', available_units,
      'can_map_more', available_units > 0,
      'mapped_companies', mapped_list
    )
  );
END;
$$ LANGUAGE plpgsql;

