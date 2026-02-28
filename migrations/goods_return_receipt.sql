-- =============================================================
-- Goods Return Receipt System
-- Records every "Transfer to SELF" operation with a unique
-- GR-YYYYMMDD-NNNN receipt so there is a full audit trail of
-- which items came back from which company, when, and at what value.
-- =============================================================

-- -------------------------------------------------------------
-- goods_return_receipt: one record per Transfer-to-SELF operation
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.goods_return_receipt (
    id               SERIAL PRIMARY KEY,
    receipt_number   VARCHAR(30)   NOT NULL UNIQUE,   -- GR-YYYYMMDD-NNNN
    from_company_lid INTEGER       NOT NULL REFERENCES company(id),
    return_date      TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_units      INTEGER       NOT NULL DEFAULT 0,
    total_amount     NUMERIC(14,2) NOT NULL DEFAULT 0,
    notes            TEXT,
    created_by       INTEGER,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ,
    active           BOOLEAN       NOT NULL DEFAULT TRUE
);

-- -------------------------------------------------------------
-- goods_return_receipt_item: one row per returned inventory unit
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.goods_return_receipt_item (
    id                  SERIAL PRIMARY KEY,
    receipt_lid         INTEGER       NOT NULL REFERENCES goods_return_receipt(id),
    inventory_unit_lid  INTEGER       NOT NULL REFERENCES inventory_unit(id),
    product_lid         INTEGER       NOT NULL REFERENCES product(id),
    mapping_lid         INTEGER       REFERENCES inventory_company_mapping(id),
    product_price       NUMERIC(12,2) NOT NULL DEFAULT 0,
    label               VARCHAR(20),
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    active              BOOLEAN       NOT NULL DEFAULT TRUE
);

-- -------------------------------------------------------------
-- GR number generator: GR-YYYYMMDD-NNNN
-- Must be created AFTER the table it references
-- -------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_goods_return_number()
RETURNS VARCHAR AS $$
DECLARE
    today TEXT := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
    cnt   INTEGER;
BEGIN
    SELECT COUNT(*) + 1 INTO cnt
    FROM goods_return_receipt
    WHERE receipt_number LIKE 'GR-' || today || '-%';
    RETURN 'GR-' || today || '-' || LPAD(cnt::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------
-- Indexes
-- -------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_grr_company      ON public.goods_return_receipt(from_company_lid);
CREATE INDEX IF NOT EXISTS idx_grr_return_date  ON public.goods_return_receipt(return_date);
CREATE INDEX IF NOT EXISTS idx_grr_number       ON public.goods_return_receipt(receipt_number);

CREATE INDEX IF NOT EXISTS idx_grri_receipt     ON public.goods_return_receipt_item(receipt_lid);
CREATE INDEX IF NOT EXISTS idx_grri_unit        ON public.goods_return_receipt_item(inventory_unit_lid);
CREATE INDEX IF NOT EXISTS idx_grri_product     ON public.goods_return_receipt_item(product_lid);
