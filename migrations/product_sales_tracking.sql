-- Sales tracking for product-company mappings

-- 1) Table to store sales records
CREATE TABLE IF NOT EXISTS product_sale (
  id SERIAL PRIMARY KEY,
  product_lid INT NOT NULL REFERENCES product(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  company_lid INT NOT NULL REFERENCES company(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  quantity INT NOT NULL CHECK (quantity > 0),
  sale_date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  receipt_lid INT NULL REFERENCES mapping_receipt(id) ON UPDATE CASCADE ON DELETE SET NULL,
  created_by INT,
  created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_product_sale_product ON product_sale(product_lid);
CREATE INDEX IF NOT EXISTS idx_product_sale_company ON product_sale(company_lid);
CREATE INDEX IF NOT EXISTS idx_product_sale_active ON product_sale(active);

-- 2) Function to record sales and deactivate corresponding mappings
DROP FUNCTION IF EXISTS record_product_sales(JSONB, INT, TEXT, INT);
CREATE OR REPLACE FUNCTION record_product_sales(
  p_items JSONB,               -- [{"id": <product_id>, "qty": <qty>}, ...]
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
BEGIN
  IF p_items IS NULL OR jsonb_typeof(p_items) != 'array' OR jsonb_array_length(p_items) = 0 THEN
    RETURN jsonb_build_object('status','error','message','No items to sell');
  END IF;

  FOR item IN (
    SELECT (value->>'id')::INT AS product_id, GREATEST(1, COALESCE((value->>'qty')::INT, 1)) AS qty
    FROM jsonb_array_elements(p_items)
  ) LOOP
    to_sell := item.qty;

    -- Iterate company mappings for this product, deactivate as many as qty
    FOR mappings IN (
      SELECT id
      FROM product_company_mapping
      WHERE active = TRUE AND company_lid = p_company_lid AND product_lid = item.product_id
      ORDER BY created_at ASC
    ) LOOP
      EXIT WHEN to_sell <= 0;
      UPDATE product_company_mapping
      SET active = FALSE, updated_at = CURRENT_TIMESTAMP, updated_by = p_created_by
      WHERE id = mappings.id;
      to_sell := to_sell - 1;
      sold := sold + 1;
    END LOOP;

    -- Insert sale record with actual sold quantity (requested - remaining)
    INSERT INTO product_sale(product_lid, company_lid, quantity, notes, created_by)
    VALUES (item.product_id, p_company_lid, (item.qty - GREATEST(to_sell,0)), p_notes, p_created_by);

    -- If still remaining, note error
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

-- 3) Update availability to subtract sold quantity
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
  FROM product_company_mapping
  WHERE product_lid = p_product_id AND active = TRUE;

  SELECT COALESCE(SUM(quantity),0) INTO sold_units
  FROM product_sale
  WHERE product_lid = p_product_id AND active = TRUE;

  available_units := GREATEST(0, total_units - mapped_units - sold_units);

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'company_name', c.name,
    'receipt_number', mr.receipt_number,
    'receipt_id', mr.id,
    'mapping_date', pcm.mapping_date
  ) ORDER BY pcm.mapping_date DESC), '[]'::JSONB)
  INTO mapped_list
  FROM product_company_mapping pcm
  JOIN company c ON c.id = pcm.company_lid
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

