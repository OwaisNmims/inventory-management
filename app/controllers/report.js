const { pool } = require('../config/dbConfig');

// ── Regular company report ─────────────────────────────────────────────────
// Starts from inventory_company_mapping so only products ever assigned to this
// company appear, grouped by product + NEW/OLD label.
async function fetchReportData(companyId) {
    const result = await pool.query(`
        WITH
        mapped AS (
            SELECT DISTINCT iu.product_lid, ml.name AS label
            FROM inventory_company_mapping icm
            JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
            JOIN mapping_label  ml ON ml.id = icm.label_lid
            WHERE icm.company_lid = $1 AND icm.active = TRUE
        ),
        sold_products AS (
            SELECT DISTINCT sri.product_lid, sri.label
            FROM sale_receipt_item sri
            JOIN sale_receipt sr ON sr.id = sri.receipt_lid
            WHERE sr.company_lid = $1 AND sri.active = TRUE
        ),
        returned_products AS (
            SELECT DISTINCT grri.product_lid, grri.label
            FROM goods_return_receipt_item grri
            JOIN goods_return_receipt grr ON grr.id = grri.receipt_lid
            WHERE grr.from_company_lid = $1
        ),
        all_products AS (
            SELECT product_lid, label FROM mapped
            UNION
            SELECT product_lid, label FROM sold_products
            UNION
            SELECT product_lid, label FROM returned_products
        ),
        mapped_agg AS (
            SELECT
                iu.product_lid,
                ml.name AS label,
                COUNT(DISTINCT icm.id)                                        AS qty_mapped_total,
                COUNT(DISTINCT CASE WHEN ist.name = 'MAPPED' THEN iu.id END) AS qty_available
            FROM inventory_company_mapping icm
            JOIN inventory_unit   iu  ON iu.id  = icm.inventory_unit_lid AND iu.active = TRUE
            JOIN mapping_label    ml  ON ml.id  = icm.label_lid
            JOIN inventory_status ist ON ist.id = iu.status_lid
            WHERE icm.company_lid = $1 AND icm.active = TRUE
            GROUP BY iu.product_lid, ml.name
        ),
        sold_agg AS (
            SELECT
                sri.product_lid, sri.label,
                COUNT(CASE WHEN sri.status = 'SOLD'     THEN 1 END)                            AS qty_sold,
                COUNT(CASE WHEN sri.status = 'REVERSED' THEN 1 END)                            AS qty_reversed,
                COALESCE(SUM(CASE WHEN sri.status = 'SOLD' THEN sri.sale_price ELSE 0 END), 0) AS sold_value
            FROM sale_receipt_item sri
            JOIN sale_receipt sr ON sr.id = sri.receipt_lid
            WHERE sr.company_lid = $1 AND sri.active = TRUE
            GROUP BY sri.product_lid, sri.label
        ),
        returned_agg AS (
            SELECT grri.product_lid, grri.label, COUNT(grri.id) AS qty_returned
            FROM goods_return_receipt_item grri
            JOIN goods_return_receipt grr ON grr.id = grri.receipt_lid
            WHERE grr.from_company_lid = $1
            GROUP BY grri.product_lid, grri.label
        )
        SELECT
            p.id            AS product_id,
            p.name          AS product_name,
            p.product_code,
            p.category,
            ap.label,
            p.price         AS unit_price,
            COALESCE(ma.qty_mapped_total, 0)::int                         AS qty_mapped_total,
            COALESCE(ma.qty_available,    0)::int                         AS qty_available,
            COALESCE(sa.qty_sold,         0)::int                         AS qty_sold,
            COALESCE(sa.qty_reversed,     0)::int                         AS qty_reversed,
            COALESCE(ra.qty_returned,     0)::int                         AS qty_returned,
            COALESCE(sa.sold_value,       0)                              AS sold_value,
            ROUND((COALESCE(ma.qty_available, 0) * p.price)::numeric, 2) AS available_value
        FROM all_products ap
        JOIN product p ON p.id = ap.product_lid AND p.active = TRUE
        LEFT JOIN mapped_agg    ma ON ma.product_lid = ap.product_lid AND ma.label = ap.label
        LEFT JOIN sold_agg      sa ON sa.product_lid = ap.product_lid AND sa.label = ap.label
        LEFT JOIN returned_agg  ra ON ra.product_lid = ap.product_lid AND ra.label = ap.label
        ORDER BY p.name, ap.label
    `, [companyId]);

    return result.rows;
}

// ── SELF report ────────────────────────────────────────────────────────────
// SELF's inventory lives in inventory_unit directly (not through
// inventory_company_mapping, which is overwritten each time a unit moves
// to/from a company).  We show the full lifecycle per product:
//   qty_mapped_total = total units ever created
//   qty_available    = currently sitting at SELF (AVAILABLE status)
//   qty_sold         = sold across ALL companies
//   qty_reversed     = sale reversals across all companies
//   qty_returned     = goods returned TO SELF from any company
async function fetchSelfReportData() {
    const result = await pool.query(`
        WITH
        unit_counts AS (
            SELECT
                iu.product_lid,
                COUNT(iu.id)                                               AS qty_total,
                COUNT(CASE WHEN ist.name = 'AVAILABLE' THEN 1 END)        AS qty_available,
                COUNT(CASE WHEN ist.name = 'MAPPED'    THEN 1 END)        AS qty_mapped_out,
                COUNT(CASE WHEN ist.name = 'SOLD'      THEN 1 END)        AS qty_sold_status
            FROM inventory_unit iu
            JOIN inventory_status ist ON ist.id = iu.status_lid
            WHERE iu.active = TRUE
            GROUP BY iu.product_lid
        ),
        sold_agg AS (
            SELECT
                sri.product_lid,
                COUNT(CASE WHEN sri.status = 'SOLD'     THEN 1 END)                            AS qty_sold,
                COUNT(CASE WHEN sri.status = 'REVERSED' THEN 1 END)                            AS qty_reversed,
                COALESCE(SUM(CASE WHEN sri.status = 'SOLD' THEN sri.sale_price ELSE 0 END), 0) AS sold_value
            FROM sale_receipt_item sri
            JOIN sale_receipt sr ON sr.id = sri.receipt_lid
            WHERE sri.active = TRUE
              AND sr.company_lid = (SELECT id FROM company WHERE company_type = 'SELF' AND active = TRUE)
            GROUP BY sri.product_lid
        ),
        returned_agg AS (
            SELECT grri.product_lid, COUNT(grri.id) AS qty_returned
            FROM goods_return_receipt_item grri
            GROUP BY grri.product_lid
        )
        SELECT
            p.id            AS product_id,
            p.name          AS product_name,
            p.product_code,
            p.category,
            '—'             AS label,
            p.price         AS unit_price,
            COALESCE(uc.qty_total,        0)::int                         AS qty_mapped_total,
            COALESCE(uc.qty_available,    0)::int                         AS qty_available,
            COALESCE(sa.qty_sold,         0)::int                         AS qty_sold,
            COALESCE(sa.qty_reversed,     0)::int                         AS qty_reversed,
            COALESCE(ra.qty_returned,     0)::int                         AS qty_returned,
            COALESCE(sa.sold_value,       0)                              AS sold_value,
            ROUND((COALESCE(uc.qty_available, 0) * p.price)::numeric, 2) AS available_value
        FROM unit_counts uc
        JOIN product p ON p.id = uc.product_lid AND p.active = TRUE
        LEFT JOIN sold_agg     sa ON sa.product_lid = uc.product_lid
        LEFT JOIN returned_agg ra ON ra.product_lid = uc.product_lid
        ORDER BY p.name
    `);

    return result.rows;
}

// ── Shared summary builder ─────────────────────────────────────────────────
function buildSummary(rows) {
    const productIds = new Set();
    let totalMapped = 0, totalAvailable = 0, totalSold = 0,
        totalReversed = 0, totalReturned = 0,
        totalSoldValue = 0, totalAvailableValue = 0;

    rows.forEach(r => {
        productIds.add(r.product_id);
        totalMapped         += r.qty_mapped_total;
        totalAvailable      += r.qty_available;
        totalSold           += r.qty_sold;
        totalReversed       += r.qty_reversed;
        totalReturned       += r.qty_returned;
        totalSoldValue      += parseFloat(r.sold_value)      || 0;
        totalAvailableValue += parseFloat(r.available_value) || 0;
    });

    return {
        totalProducts:       productIds.size,
        totalMapped,
        totalAvailable,
        totalSold,
        totalReversed,
        totalReturned,
        totalSoldValue:      parseFloat(totalSoldValue.toFixed(2)),
        totalAvailableValue: parseFloat(totalAvailableValue.toFixed(2))
    };
}

module.exports = {

    index: async (req, res) => {
        try {
            const [companiesResult, statesResult, citiesResult] = await Promise.all([
                pool.query(`SELECT id, name, company_code, state_lid, city_lid FROM company WHERE active = TRUE ORDER BY name`),
                pool.query(`SELECT id, name FROM state WHERE active = TRUE ORDER BY name`),
                pool.query(`SELECT id, name, state_lid FROM city WHERE active = TRUE ORDER BY name`)
            ]);
            res.render('admin/reports/index', {
                companies: companiesResult.rows,
                states:    statesResult.rows,
                cities:    citiesResult.rows,
                title:     'Reports'
            });
        } catch (e) {
            console.error('Reports index error:', e);
            res.status(500).render('error', { message: 'Error loading reports page', error: e });
        }
    },

    generate: async (req, res) => {
        try {
            const { company } = req.query;

            if (!company) {
                return res.status(400).json({ message: 'error', status: 400, data: { message: 'Company is required' } });
            }

            const companyResult = await pool.query(
                `SELECT id, name, company_code, company_type FROM company WHERE id = $1 AND active = TRUE`,
                [company]
            );
            if (companyResult.rows.length === 0) {
                return res.status(404).json({ message: 'error', status: 404, data: { message: 'Company not found' } });
            }

            const isSelf = companyResult.rows[0].company_type === 'SELF';
            const rows   = isSelf
                ? await fetchSelfReportData()
                : await fetchReportData(company);

            res.status(200).json({
                message: 'success',
                status:  200,
                data: {
                    company: companyResult.rows[0],
                    isSelf,
                    rows,
                    summary: buildSummary(rows)
                }
            });
        } catch (e) {
            console.error('Reports generate error:', e);
            res.status(500).json({ message: 'error', status: 500, data: { message: 'Something went wrong!' } });
        }
    },

    downloadCsv: async (req, res) => {
        try {
            const { company } = req.query;

            if (!company) return res.status(400).send('Company is required');

            const companyResult = await pool.query(
                `SELECT id, name, company_code, company_type FROM company WHERE id = $1 AND active = TRUE`,
                [company]
            );
            if (companyResult.rows.length === 0) return res.status(404).send('Company not found');

            const { name: companyName, company_code: companyCode } = companyResult.rows[0];
            const isSelf = companyResult.rows[0].company_type === 'SELF';
            const rows   = isSelf
                ? await fetchSelfReportData()
                : await fetchReportData(company);

            const mappedHeader = isSelf ? 'Total Units' : 'Total Mapped';
            const returnHeader = isSelf ? 'Returned to SELF' : 'Returned';

            const headers = [
                'Company', 'Company Code',
                'Product Name', 'Product Code', 'Category', 'Label',
                'Unit Price',
                mappedHeader, 'Available', 'Sold', 'Reversed', returnHeader,
                'Sold Value', 'Available Value'
            ];

            const escape = v => `"${String(v || '').replace(/"/g, '""')}"`;

            const csvLines = [headers.join(',')];
            rows.forEach(r => {
                csvLines.push([
                    escape(companyName),
                    escape(companyCode),
                    escape(r.product_name),
                    escape(r.product_code),
                    escape(r.category),
                    escape(r.label),
                    parseFloat(r.unit_price      || 0).toFixed(2),
                    r.qty_mapped_total,
                    r.qty_available,
                    r.qty_sold,
                    r.qty_reversed,
                    r.qty_returned,
                    parseFloat(r.sold_value      || 0).toFixed(2),
                    parseFloat(r.available_value || 0).toFixed(2)
                ].join(','));
            });

            const filename = `report-${companyCode}-${new Date().toISOString().slice(0, 10)}.csv`;
            res.setHeader('Content-Type', 'text/csv; charset=utf-8');
            res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
            res.send('\uFEFF' + csvLines.join('\r\n'));
        } catch (e) {
            console.error('Reports download CSV error:', e);
            res.status(500).send('Error generating CSV');
        }
    }
};
