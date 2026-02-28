-- =============================================================
-- Sale Receipt System
-- Creates sale_receipt and sale_receipt_item tables to track
-- every sales transaction with a unique receipt number, and
-- supports per-item reversal (item reverts to MAPPED status).
-- =============================================================

-- Receipt number generator: SR-YYYYMMDD-NNNN
CREATE OR REPLACE FUNCTION generate_sale_receipt_number()
RETURNS VARCHAR AS $$
DECLARE
    today TEXT := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
    cnt   INTEGER;
BEGIN
    SELECT COUNT(*) + 1 INTO cnt
    FROM sale_receipt
    WHERE receipt_number LIKE 'SR-' || today || '-%';
    RETURN 'SR-' || today || '-' || LPAD(cnt::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- -------------------------------------------------------------
-- sale_receipt: one record per sale transaction
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sale_receipt (
    id              SERIAL PRIMARY KEY,
    receipt_number  VARCHAR(30)    NOT NULL UNIQUE,
    company_lid     INTEGER        NOT NULL REFERENCES company(id),
    sale_date       TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_units     INTEGER        NOT NULL DEFAULT 0,
    total_amount    NUMERIC(14,2)  NOT NULL DEFAULT 0,
    status          VARCHAR(20)    NOT NULL DEFAULT 'ACTIVE'
                        CHECK (status IN ('ACTIVE', 'PARTIAL_REVERSAL', 'REVERSED')),
    notes           TEXT,
    created_by      INTEGER,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ,
    active          BOOLEAN        NOT NULL DEFAULT TRUE
);

-- -------------------------------------------------------------
-- sale_receipt_item: one row per inventory_unit sold
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sale_receipt_item (
    id                  SERIAL PRIMARY KEY,
    receipt_lid         INTEGER        NOT NULL REFERENCES sale_receipt(id),
    inventory_unit_lid  INTEGER        NOT NULL REFERENCES inventory_unit(id),
    product_lid         INTEGER        NOT NULL REFERENCES product(id),
    mapping_lid         INTEGER        REFERENCES inventory_company_mapping(id),
    sale_price          NUMERIC(12,2)  NOT NULL,
    label               VARCHAR(20),
    status              VARCHAR(20)    NOT NULL DEFAULT 'SOLD'
                            CHECK (status IN ('SOLD', 'REVERSED')),
    reversal_reason     TEXT,
    reversed_at         TIMESTAMPTZ,
    reversed_by         INTEGER,
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    active              BOOLEAN        NOT NULL DEFAULT TRUE
);

-- -------------------------------------------------------------
-- Indexes
-- -------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_sale_receipt_company    ON public.sale_receipt(company_lid);
CREATE INDEX IF NOT EXISTS idx_sale_receipt_status     ON public.sale_receipt(status);
CREATE INDEX IF NOT EXISTS idx_sale_receipt_date       ON public.sale_receipt(sale_date);
CREATE INDEX IF NOT EXISTS idx_sale_receipt_number     ON public.sale_receipt(receipt_number);

CREATE INDEX IF NOT EXISTS idx_sri_receipt             ON public.sale_receipt_item(receipt_lid);
CREATE INDEX IF NOT EXISTS idx_sri_inventory_unit      ON public.sale_receipt_item(inventory_unit_lid);
CREATE INDEX IF NOT EXISTS idx_sri_status              ON public.sale_receipt_item(status);
CREATE INDEX IF NOT EXISTS idx_sri_product             ON public.sale_receipt_item(product_lid);
