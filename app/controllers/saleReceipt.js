const { pool } = require('../config/dbConfig');

module.exports = {

    // Render the sale receipts listing page
    index: async (req, res) => {
        try {
            const companiesResult = await pool.query(`
                SELECT id, name, company_code, state_lid, city_lid
                FROM company
                WHERE active = TRUE
                ORDER BY name
            `);

            const statesResult = await pool.query(`
                SELECT id, name FROM state WHERE active = TRUE ORDER BY name
            `);

            const citiesResult = await pool.query(`
                SELECT id, name, state_lid FROM city WHERE active = TRUE ORDER BY name
            `);

            res.render('admin/sales/receipts', {
                companies: companiesResult.rows,
                states: statesResult.rows,
                cities: citiesResult.rows,
                title: 'Sale Receipts'
            });
        } catch (e) {
            console.error('Sale receipts index error:', e);
            res.status(500).render('error', { message: 'Error loading sale receipts page', error: e });
        }
    },

    // GET /sale-receipts/list  — paginated, filterable (AJAX)
    list: async (req, res) => {
        try {
            const page      = parseInt(req.query.page)    || 1;
            const limit     = parseInt(req.query.limit)   || 20;
            const offset    = (page - 1) * limit;
            const company   = req.query.company  || '';
            const stateLid  = req.query.stateLid || '';
            const cityLid   = req.query.cityLid  || '';
            const status    = req.query.status   || '';
            const dateFrom  = req.query.dateFrom || '';
            const dateTo    = req.query.dateTo   || '';
            const receipt   = (req.query.receipt || '').trim();

            const allowedSort = {
                receipt_number: 'sr.receipt_number',
                company_name:   'c.name',
                sale_date:      'sr.sale_date',
                total_units:    'sr.total_units',
                total_amount:   'sr.total_amount',
                status:         'sr.status'
            };
            const sortField = allowedSort[req.query.sortBy] || 'sr.sale_date';
            const sortOrder = req.query.sortOrder === 'ASC' ? 'ASC' : 'DESC';

            const conditions = ['sr.active = TRUE'];
            const params     = [];

            if (receipt) {
                params.push('%' + receipt.toUpperCase() + '%');
                conditions.push(`UPPER(sr.receipt_number) LIKE $${params.length}`);
            }
            if (company) {
                params.push(company);
                conditions.push(`sr.company_lid = $${params.length}`);
            } else {
                // Only apply state/city when no specific company is selected
                if (stateLid) {
                    params.push(stateLid);
                    conditions.push(`c.state_lid = $${params.length}`);
                }
                if (cityLid) {
                    params.push(cityLid);
                    conditions.push(`c.city_lid = $${params.length}`);
                }
            }
            if (status) {
                params.push(status);
                conditions.push(`sr.status = $${params.length}`);
            }
            if (dateFrom) {
                params.push(dateFrom);
                conditions.push(`sr.sale_date >= $${params.length}::date`);
            }
            if (dateTo) {
                params.push(dateTo);
                conditions.push(`sr.sale_date < ($${params.length}::date + INTERVAL '1 day')`);
            }

            const where = conditions.join(' AND ');
            // Always join company so state/city conditions on c.* work in both queries
            const fromClause = `FROM sale_receipt sr JOIN company c ON c.id = sr.company_lid`;

            const countResult = await pool.query(
                `SELECT COUNT(*) AS total ${fromClause} WHERE ${where}`,
                params
            );
            const totalRecords = parseInt(countResult.rows[0].total);
            const totalPages   = Math.ceil(totalRecords / limit);

            params.push(limit, offset);
            const dataResult = await pool.query(`
                SELECT
                    sr.id,
                    sr.receipt_number,
                    sr.sale_date,
                    sr.total_units,
                    sr.total_amount,
                    sr.status,
                    sr.notes,
                    c.name         AS company_name,
                    c.company_code AS company_code,
                    c.company_type AS company_type
                ${fromClause}
                WHERE ${where}
                ORDER BY ${sortField} ${sortOrder}, sr.id DESC
                LIMIT $${params.length - 1} OFFSET $${params.length}
            `, params);

            res.status(200).json({
                message: 'success',
                status: 200,
                data: {
                    items: dataResult.rows,
                    pagination: {
                        currentPage:  page,
                        totalPages:   totalPages,
                        totalRecords: totalRecords,
                        limit:        limit,
                        hasNextPage:  page < totalPages,
                        hasPrevPage:  page > 1
                    }
                }
            });
        } catch (e) {
            console.error('Sale receipts list error:', e);
            res.status(500).json({ message: 'error', status: 500, data: { message: 'Something went wrong!' } });
        }
    },

    // GET /sale-receipts/:id  — receipt detail with items (AJAX)
    getById: async (req, res) => {
        try {
            const { id } = req.params;

            const receiptResult = await pool.query(`
                SELECT
                    sr.id,
                    sr.receipt_number,
                    sr.sale_date,
                    sr.total_units,
                    sr.total_amount,
                    sr.status,
                    sr.notes,
                    c.name         AS company_name,
                    c.company_code AS company_code,
                    c.company_type AS company_type
                FROM sale_receipt sr
                JOIN company c ON c.id = sr.company_lid
                WHERE sr.id = $1 AND sr.active = TRUE
            `, [id]);

            if (receiptResult.rows.length === 0) {
                return res.status(404).json({ message: 'error', status: 404, data: { message: 'Receipt not found' } });
            }

            const itemsResult = await pool.query(`
                SELECT
                    sri.id,
                    sri.inventory_unit_lid,
                    sri.sale_price,
                    sri.label,
                    sri.status,
                    sri.reversal_reason,
                    sri.reversed_at,
                    p.name         AS product_name,
                    p.product_code AS product_code,
                    p.category     AS category
                FROM sale_receipt_item sri
                JOIN product p ON p.id = sri.product_lid
                WHERE sri.receipt_lid = $1
                ORDER BY sri.id ASC
            `, [id]);

            res.status(200).json({
                message: 'success',
                status: 200,
                data: {
                    receipt: receiptResult.rows[0],
                    items:   itemsResult.rows
                }
            });
        } catch (e) {
            console.error('Sale receipt getById error:', e);
            res.status(500).json({ message: 'error', status: 500, data: { message: 'Something went wrong!' } });
        }
    },

    // POST /sale-receipts/:receiptId/items/:itemId/reverse
    reverseItem: async (req, res) => {
        try {
            const { receiptId, itemId } = req.params;
            const { reversal_reason }   = req.body;

            // Verify item belongs to receipt and is still SOLD
            const itemResult = await pool.query(`
                SELECT sri.id, sri.inventory_unit_lid, sri.status, sri.receipt_lid
                FROM sale_receipt_item sri
                WHERE sri.id = $1
                  AND sri.receipt_lid = $2
                  AND sri.active = TRUE
            `, [itemId, receiptId]);

            if (itemResult.rows.length === 0) {
                return res.status(404).json({ message: 'error', status: 404, data: { message: 'Sale item not found' } });
            }

            const item = itemResult.rows[0];

            if (item.status === 'REVERSED') {
                return res.status(400).json({ message: 'error', status: 400, data: { message: 'This item has already been reversed' } });
            }

            // All writes inside a transaction so a mid-way failure rolls back cleanly
            const client = await pool.connect();
            let newStatus, soldCount, soldAmount;
            try {
                await client.query('BEGIN');

                // Mark item as REVERSED
                await client.query(`
                    UPDATE sale_receipt_item
                    SET status          = 'REVERSED',
                        reversal_reason = $1,
                        reversed_at     = CURRENT_TIMESTAMP,
                        reversed_by     = $2
                    WHERE id = $3
                `, [reversal_reason || null, 1, itemId]);

                // Determine revert status: SELF sales go back to AVAILABLE, vendor sales to MAPPED
                const receiptCompanyResult = await client.query(
                    `SELECT c.company_type FROM sale_receipt sr
                     JOIN company c ON c.id = sr.company_lid
                     WHERE sr.id = $1`,
                    [receiptId]
                );
                const revertStatus = receiptCompanyResult.rows[0]?.company_type === 'SELF'
                    ? 'AVAILABLE'
                    : 'MAPPED';

                await client.query(`
                    UPDATE inventory_unit
                    SET status_lid = (SELECT id FROM inventory_status WHERE name = $1),
                        updated_at = CURRENT_TIMESTAMP,
                        updated_by = $2
                    WHERE id = $3
                `, [revertStatus, 1, item.inventory_unit_lid]);

                // Recalculate receipt totals from remaining SOLD items
                const totalsResult = await client.query(`
                    SELECT
                        COUNT(*)         AS sold_count,
                        SUM(sale_price)  AS sold_amount
                    FROM sale_receipt_item
                    WHERE receipt_lid = $1 AND status = 'SOLD' AND active = TRUE
                `, [receiptId]);

                soldCount  = parseInt(totalsResult.rows[0].sold_count)    || 0;
                soldAmount = parseFloat(totalsResult.rows[0].sold_amount) || 0;

                // Derive new receipt status
                const allItemsResult = await client.query(`
                    SELECT COUNT(*) AS total FROM sale_receipt_item
                    WHERE receipt_lid = $1 AND active = TRUE
                `, [receiptId]);
                const totalItems = parseInt(allItemsResult.rows[0].total);

                if (soldCount === 0)             newStatus = 'REVERSED';
                else if (soldCount < totalItems) newStatus = 'PARTIAL_REVERSAL';
                else                             newStatus = 'ACTIVE';

                await client.query(`
                    UPDATE sale_receipt
                    SET total_units  = $1,
                        total_amount = $2,
                        status       = $3,
                        updated_at   = CURRENT_TIMESTAMP
                    WHERE id = $4
                `, [soldCount, soldAmount, newStatus, receiptId]);

                await client.query('COMMIT');
            } catch (txErr) {
                await client.query('ROLLBACK');
                throw txErr;
            } finally {
                client.release();
            }

            res.status(200).json({
                message: 'success',
                status: 200,
                data: {
                    message:        'Item reversed successfully',
                    receipt_status: newStatus,
                    total_units:    soldCount,
                    total_amount:   soldAmount
                }
            });
        } catch (e) {
            console.error('Reverse item error:', e);
            res.status(500).json({ message: 'error', status: 500, data: { message: 'Something went wrong!' } });
        }
    }
};
