-- Inventory Unit Overhaul: introduce per-unit tracking and wire existing functions

-- 0) Ensure required labels
DO $$
DECLARE
  id_new INT; id_old INT; id_sold INT;
BEGIN
  SELECT id INTO id_new FROM label WHERE name='NEW' AND active=TRUE LIMIT 1;
  IF id_new IS NULL THEN INSERT INTO label(name, description, active) VALUES('NEW','New mapping',TRUE); END IF;
  SELECT id INTO id_old FROM label WHERE name='OLD' AND active=TRUE LIMIT 1;
  IF id_old IS NULL THEN INSERT INTO label(name, description, active) VALUES('OLD','Old mapping',TRUE); END IF;
  SELECT id INTO id_sold FROM label WHERE name='SOLD' AND active=TRUE LIMIT 1;
  IF id_sold IS NULL THEN INSERT INTO label(name, description, active) VALUES('SOLD','Sold mapping',TRUE); END IF;
END $$;

-- 1) Create inventory_unit table
CREATE TABLE IF NOT EXISTS inventory_unit (
  id SERIAL PRIMARY KEY,
  product_lid INT NOT NULL REFERENCES product(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  unit_serial TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('AVAILABLE','MAPPED','SOLD','RETURNED')) DEFAULT 'AVAILABLE',
  current_company_lid INT NULL REFERENCES company(id) ON UPDATE CASCADE ON DELETE SET NULL,
  receipt_lid INT NULL REFERENCES mapping_receipt(id) ON UPDATE CASCADE ON DELETE SET NULL,
  mapped_at TIMESTAMP NULL,
  sold_at TIMESTAMP NULL,
  created_by INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_inventory_unit_serial ON inventory_unit(product_lid, unit_serial);
CREATE INDEX IF NOT EXISTS idx_inventory_unit_status ON inventory_unit(status);
CREATE INDEX IF NOT EXISTS idx_inventory_unit_product ON inventory_unit(product_lid);

-- 2) Backfill inventory units per product (idempotent)
CREATE OR REPLACE FUNCTION backfill_inventory_units() RETURNS VOID AS $$
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
$$ LANGUAGE plpgsql;

SELECT backfill_inventory_units();

-- 3) Wire product_company_mapping to inventory units
ALTER TABLE product_company_mapping
  ADD COLUMN IF NOT EXISTS inventory_unit_lid INT NULL REFERENCES inventory_unit(id) ON UPDATE CASCADE ON DELETE SET NULL;

-- Unique active mapping per inventory unit
DO $$ BEGIN
  CREATE UNIQUE INDEX ux_pcm_active_inv_unit ON product_company_mapping(inventory_unit_lid) WHERE active=TRUE;
EXCEPTION WHEN duplicate_table THEN NULL; END $$;

-- 4) Assign inventory units to existing active mappings
DO $$
DECLARE
  m RECORD;
  u RECORD;
BEGIN
  FOR m IN 
    SELECT id, product_lid, company_lid FROM product_company_mapping 
    WHERE active=TRUE AND inventory_unit_lid IS NULL ORDER BY created_at ASC
  LOOP
    SELECT id INTO u FROM inventory_unit 
    WHERE product_lid=m.product_lid AND status='AVAILABLE' ORDER BY id ASC LIMIT 1;
    IF u.id IS NOT NULL THEN
      UPDATE product_company_mapping SET inventory_unit_lid=u.id WHERE id=m.id;
      UPDATE inventory_unit SET status='MAPPED', current_company_lid=m.company_lid, mapped_at=NOW() WHERE id=u.id;
    END IF;
  END LOOP;
END $$;

-- 5) Update map_product_to_company to allocate an available unit
DROP FUNCTION IF EXISTS map_product_to_company(INT, INT, TEXT, INT);
CREATE OR REPLACE FUNCTION map_product_to_company(
  p_product_lid INT,
  p_company_lid INT,
  p_notes TEXT,
  p_created_by INT
) RETURNS JSONB AS $$
DECLARE
  new_label_id INT;
  old_label_id INT;
  product_name TEXT;
  company_name TEXT;
  inv_id INT;
  result JSONB;
BEGIN
  SELECT id INTO new_label_id FROM label WHERE name='NEW' AND active=TRUE LIMIT 1;
  SELECT id INTO old_label_id FROM label WHERE name='OLD' AND active=TRUE LIMIT 1;
  IF new_label_id IS NULL OR old_label_id IS NULL THEN
    RETURN jsonb_build_object('status','error','message','Required labels (NEW/OLD) not found');
  END IF;

  SELECT name INTO product_name FROM product WHERE id=p_product_lid AND active=TRUE;
  IF product_name IS NULL THEN RETURN jsonb_build_object('status','error','message','Product not found'); END IF;
  SELECT name INTO company_name FROM company WHERE id=p_company_lid AND active=TRUE;
  IF company_name IS NULL THEN RETURN jsonb_build_object('status','error','message','Company not found'); END IF;

  -- Find available inventory unit
  SELECT id INTO inv_id FROM inventory_unit 
  WHERE product_lid=p_product_lid AND status='AVAILABLE' 
  ORDER BY id ASC LIMIT 1;
  IF inv_id IS NULL THEN
    RETURN jsonb_build_object('status','error','message','No available units for this product');
  END IF;

  -- Set existing NEW mappings to OLD for this company
  UPDATE product_company_mapping
  SET label_lid=old_label_id, updated_at=NOW(), updated_by=p_created_by
  WHERE company_lid=p_company_lid AND label_lid=new_label_id AND active=TRUE;

  -- Create mapping
  INSERT INTO product_company_mapping(product_lid, company_lid, label_lid, notes, created_by, inventory_unit_lid)
  VALUES(p_product_lid, p_company_lid, new_label_id, p_notes, p_created_by, inv_id);

  -- Update inventory unit
  UPDATE inventory_unit SET status='MAPPED', current_company_lid=p_company_lid, mapped_at=NOW() WHERE id=inv_id;

  RETURN jsonb_build_object('status','success', 'message', 'Mapped one unit of '||product_name||' to '||company_name);
END;
$$ LANGUAGE plpgsql;

-- 6) Bulk mapping to allocate units one-by-one and create receipt
DROP FUNCTION IF EXISTS bulk_map_products_to_company(JSONB, INT, TEXT, INT);
CREATE OR REPLACE FUNCTION bulk_map_products_to_company(
  product_list JSONB,
  p_company_lid INT,
  p_notes TEXT,
  p_created_by INT
) RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql;

-- 7) Record sales using inventory units & mark mapping SOLD
DROP FUNCTION IF EXISTS record_product_sales(JSONB, INT, TEXT, INT);
CREATE OR REPLACE FUNCTION record_product_sales(
  p_items JSONB,
  p_company_lid INT,
  p_notes TEXT,
  p_created_by INT
) RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql;

-- 8) Availability computed from inventory units
DROP FUNCTION IF EXISTS get_product_availability(INT);
CREATE OR REPLACE FUNCTION get_product_availability(p_product_id INT) RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql;

-- 9) Ensure transfer updates inventory_unit company
DROP FUNCTION IF EXISTS transfer_product_to_company(INT, INT, TEXT, INT);
CREATE OR REPLACE FUNCTION transfer_product_to_company(
  p_mapping_id INT,
  p_new_company_lid INT,
  p_notes TEXT,
  p_updated_by INT
) RETURNS JSONB AS $$
DECLARE
  inv_id INT; old_company INT; result JSONB;
BEGIN
  SELECT inventory_unit_lid, company_lid INTO inv_id, old_company FROM product_company_mapping WHERE id=p_mapping_id AND active=TRUE;
  IF inv_id IS NULL THEN RETURN jsonb_build_object('status','error','message','Mapping not found'); END IF;
  UPDATE product_company_mapping SET company_lid=p_new_company_lid, notes=COALESCE(p_notes, notes), updated_at=NOW(), updated_by=p_updated_by WHERE id=p_mapping_id;
  UPDATE inventory_unit SET current_company_lid=p_new_company_lid WHERE id=inv_id;
  RETURN jsonb_build_object('status','success','message','Transferred mapping to new company');
END;
$$ LANGUAGE plpgsql;

