const { pool } = require('../config/dbConfig');

module.exports = {

    // Render the Goods Return page
    index: async (req, res) => {
        try {
            // Only companies (excluding SELF) that currently have MAPPED inventory
            const companiesResult = await pool.query(`
                SELECT DISTINCT c.id, c.name, c.company_code, c.company_type,
                       c.state_lid, c.city_lid,
                       COUNT(CASE WHEN iu.status_lid = (SELECT id FROM inventory_status WHERE name = 'MAPPED') THEN icm.id END) AS mapped_units
                FROM company c
                LEFT JOIN inventory_company_mapping icm ON icm.company_lid = c.id AND icm.active = TRUE
                LEFT JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid AND iu.active = TRUE
                WHERE c.active = TRUE AND c.company_type != 'SELF'
                GROUP BY c.id, c.name, c.company_code, c.company_type, c.state_lid, c.city_lid
                HAVING COUNT(CASE WHEN iu.status_lid = (SELECT id FROM inventory_status WHERE name = 'MAPPED') THEN icm.id END) > 0
                ORDER BY c.name
            `);

            const statesResult = await pool.query(`
                SELECT id, name FROM state WHERE active = TRUE ORDER BY name
            `);

            const citiesResult = await pool.query(`
                SELECT id, name, state_lid FROM city WHERE active = TRUE ORDER BY name
            `);

            res.render('admin/sales/goods-return', {
                companies: companiesResult.rows,
                states:    statesResult.rows,
                cities:    citiesResult.rows,
                title:     'Goods Return'
            });
        } catch (e) {
            console.error('Goods return index error:', e);
            res.status(500).render('error', { message: 'Error loading goods return page', error: e });
        }
    },

    // GET /goods-return/list  — paginated, filterable (AJAX)
    list: async (req, res) => {
        try {
            const page      = parseInt(req.query.page)    || 1;
            const limit     = parseInt(req.query.limit)   || 20;
            const offset    = (page - 1) * limit;
            const company   = req.query.company  || '';
            const stateLid  = req.query.stateLid || '';
            const cityLid   = req.query.cityLid  || '';
            const dateFrom  = req.query.dateFrom || '';
            const dateTo    = req.query.dateTo   || '';
            const receipt   = (req.query.receipt || '').trim();

            const allowedSort = {
                receipt_number: 'grr.receipt_number',
                company_name:   'c.name',
                return_date:    'grr.return_date',
                total_units:    'grr.total_units',
                total_amount:   'grr.total_amount'
            };
            const sortField = allowedSort[req.query.sortBy] || 'grr.return_date';
            const sortOrder = req.query.sortOrder === 'ASC' ? 'ASC' : 'DESC';

            const conditions = ['grr.active = TRUE'];
            const params     = [];

            if (receipt) {
                params.push('%' + receipt.toUpperCase() + '%');
                conditions.push(`UPPER(grr.receipt_number) LIKE $${params.length}`);
            }
            if (company) {
                params.push(company);
                conditions.push(`grr.from_company_lid = $${params.length}`);
            } else {
                if (stateLid) {
                    params.push(stateLid);
                    conditions.push(`c.state_lid = $${params.length}`);
                }
                if (cityLid) {
                    params.push(cityLid);
                    conditions.push(`c.city_lid = $${params.length}`);
                }
            }
            if (dateFrom) {
                params.push(dateFrom);
                conditions.push(`grr.return_date >= $${params.length}::date`);
            }
            if (dateTo) {
                params.push(dateTo);
                conditions.push(`grr.return_date < ($${params.length}::date + INTERVAL '1 day')`);
            }

            const where      = conditions.join(' AND ');
            const fromClause = `FROM goods_return_receipt grr JOIN company c ON c.id = grr.from_company_lid`;

            const countResult = await pool.query(
                `SELECT COUNT(*) AS total ${fromClause} WHERE ${where}`,
                params
            );
            const totalRecords = parseInt(countResult.rows[0].total);
            const totalPages   = Math.ceil(totalRecords / limit) || 1;

            params.push(limit, offset);
            const dataResult = await pool.query(`
                SELECT
                    grr.id,
                    grr.receipt_number,
                    grr.return_date,
                    grr.total_units,
                    grr.total_amount,
                    grr.notes,
                    c.name         AS company_name,
                    c.company_code AS company_code,
                    c.company_type AS company_type
                ${fromClause}
                WHERE ${where}
                ORDER BY ${sortField} ${sortOrder}, grr.id DESC
                LIMIT $${params.length - 1} OFFSET $${params.length}
            `, params);

            res.status(200).json({
                message: 'success',
                status:  200,
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
            console.error('Goods return list error:', e);
            res.status(500).json({ message: 'error', status: 500, data: { message: 'Something went wrong!' } });
        }
    },

    // GET /goods-return/:id  — receipt detail with items (AJAX)
    getById: async (req, res) => {
        try {
            const { id } = req.params;

            const receiptResult = await pool.query(`
                SELECT
                    grr.id,
                    grr.receipt_number,
                    grr.return_date,
                    grr.total_units,
                    grr.total_amount,
                    grr.notes,
                    c.name         AS company_name,
                    c.company_code AS company_code,
                    c.company_type AS company_type
                FROM goods_return_receipt grr
                JOIN company c ON c.id = grr.from_company_lid
                WHERE grr.id = $1 AND grr.active = TRUE
            `, [id]);

            if (receiptResult.rows.length === 0) {
                return res.status(404).json({ message: 'error', status: 404, data: { message: 'Receipt not found' } });
            }

            const itemsResult = await pool.query(`
                SELECT
                    grri.id,
                    grri.inventory_unit_lid,
                    grri.product_price,
                    grri.label,
                    p.name         AS product_name,
                    p.product_code AS product_code,
                    p.category     AS category
                FROM goods_return_receipt_item grri
                JOIN product p ON p.id = grri.product_lid
                WHERE grri.receipt_lid = $1
                ORDER BY grri.id ASC
            `, [id]);

            res.status(200).json({
                message: 'success',
                status:  200,
                data: {
                    receipt: receiptResult.rows[0],
                    items:   itemsResult.rows
                }
            });
        } catch (e) {
            console.error('Goods return getById error:', e);
            res.status(500).json({ message: 'error', status: 500, data: { message: 'Something went wrong!' } });
        }
    }
};
