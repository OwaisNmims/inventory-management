const { pool } = require("../config/dbConfig");

module.exports = {
    // Render sales page
    index: async (req, res) => {
        try {
            // Regular companies with MAPPED inventory
            const companiesResult = await pool.query(`
                SELECT DISTINCT c.id, c.name, c.company_code, c.company_type,
                       c.state_lid, c.city_lid,
                       COUNT(CASE WHEN iu.status_lid = (SELECT id FROM inventory_status WHERE name = 'MAPPED') THEN icm.id END) as mapped_units
                FROM company c
                LEFT JOIN inventory_company_mapping icm ON icm.company_lid = c.id AND icm.active = TRUE
                LEFT JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid AND iu.active = TRUE
                WHERE c.active = TRUE AND c.company_type != 'SELF'
                GROUP BY c.id, c.name, c.company_code, c.company_type, c.state_lid, c.city_lid
                HAVING COUNT(CASE WHEN iu.status_lid = (SELECT id FROM inventory_status WHERE name = 'MAPPED') THEN icm.id END) > 0
                ORDER BY c.company_type, c.name
            `);

            // SELF — include if it has any AVAILABLE units
            const selfResult = await pool.query(`
                SELECT c.id, c.name, c.company_code, c.company_type, c.state_lid, c.city_lid,
                       (SELECT COUNT(*) FROM inventory_unit iu
                        JOIN inventory_status ist ON ist.id = iu.status_lid
                        WHERE ist.name = 'AVAILABLE' AND iu.active = TRUE) AS mapped_units
                FROM company c
                WHERE c.active = TRUE AND c.company_type = 'SELF'
                  AND (SELECT COUNT(*) FROM inventory_unit iu
                       JOIN inventory_status ist ON ist.id = iu.status_lid
                       WHERE ist.name = 'AVAILABLE' AND iu.active = TRUE) > 0
            `);

            const statesResult = await pool.query(`
                SELECT id, name FROM state WHERE active = TRUE ORDER BY name
            `);

            const citiesResult = await pool.query(`
                SELECT id, name, state_lid FROM city WHERE active = TRUE ORDER BY name
            `);

            // SELF first so it appears at the top
            const companies = [...selfResult.rows, ...companiesResult.rows];

            res.render('admin/sales/index', {
                companies,
                states: statesResult.rows,
                cities: citiesResult.rows,
                title: 'Sales Management'
            });

        } catch (error) {
            console.error('Sales page error:', error);
            res.status(500).render('error', {
                message: 'Error loading sales page',
                error: error
            });
        }
    },

    // Get available inventory for a company (paginated + searchable)
    getAvailableInventory: async (req, res) => {
        try {
            const { companyId } = req.params;
            const page   = parseInt(req.query.page)  || 1;
            const limit  = parseInt(req.query.limit) || 25;
            const search = (req.query.search || '').trim();
            const offset = (page - 1) * limit;

            // Check if this is SELF
            const companyCheck = await pool.query(
                'SELECT company_type FROM company WHERE id = $1 AND active = TRUE',
                [companyId]
            );
            const isSelf = companyCheck.rows.length > 0 && companyCheck.rows[0].company_type === 'SELF';

            if (isSelf) {
                const params = [];
                let searchClause = '';
                if (search) {
                    params.push('%' + search.toLowerCase() + '%');
                    searchClause = `AND (LOWER(p.name) LIKE $${params.length} OR LOWER(p.product_code) LIKE $${params.length})`;
                }

                const countResult = await pool.query(`
                    SELECT COUNT(*) AS total
                    FROM (
                        SELECT p.id
                        FROM inventory_unit iu
                        JOIN product p ON p.id = iu.product_lid
                        WHERE iu.status_lid = (SELECT id FROM inventory_status WHERE name = 'AVAILABLE')
                          AND iu.active = TRUE AND p.active = TRUE
                          ${searchClause}
                        GROUP BY p.id
                    ) t
                `, params);

                const totalRecords = parseInt(countResult.rows[0].total);
                const totalPages   = Math.ceil(totalRecords / limit) || 1;

                params.push(limit, offset);
                const inventoryResult = await pool.query(`
                    SELECT
                        p.id             AS product_id,
                        p.name           AS product_name,
                        p.product_code,
                        p.category,
                        p.price,
                        NULL::text       AS label,
                        COUNT(iu.id)     AS available_units,
                        ARRAY_AGG(iu.id) AS unit_ids
                    FROM inventory_unit iu
                    JOIN product p ON p.id = iu.product_lid
                    WHERE iu.status_lid = (SELECT id FROM inventory_status WHERE name = 'AVAILABLE')
                      AND iu.active = TRUE AND p.active = TRUE
                      ${searchClause}
                    GROUP BY p.id, p.name, p.product_code, p.category, p.price
                    ORDER BY p.name, p.product_code
                    LIMIT $${params.length - 1} OFFSET $${params.length}
                `, params);

                return res.status(200).json({
                    message:    'success',
                    status:     200,
                    isSelf:     true,
                    data:       inventoryResult.rows,
                    pagination: {
                        currentPage:  page,
                        totalPages:   totalPages,
                        totalRecords: totalRecords,
                        limit:        limit,
                        hasNextPage:  page < totalPages,
                        hasPrevPage:  page > 1
                    }
                });
            }

            // ── Regular company (MAPPED units via inventory_company_mapping) ──
            const params = [companyId];
            let searchClause = '';
            if (search) {
                params.push('%' + search.toLowerCase() + '%');
                searchClause = `AND (LOWER(p.name) LIKE $${params.length} OR LOWER(p.product_code) LIKE $${params.length})`;
            }

            const countResult = await pool.query(`
                SELECT COUNT(*) AS total
                FROM (
                    SELECT p.id, ml.name AS label
                    FROM inventory_unit iu
                    JOIN product p ON p.id = iu.product_lid
                    JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id
                    JOIN mapping_label ml ON ml.id = icm.label_lid
                    WHERE iu.status_lid = (SELECT id FROM inventory_status WHERE name = 'MAPPED')
                    AND icm.company_lid = $1
                    AND icm.active = TRUE AND iu.active = TRUE AND p.active = TRUE
                    ${searchClause}
                    GROUP BY p.id, ml.name
                ) t
            `, params);

            const totalRecords = parseInt(countResult.rows[0].total);
            const totalPages   = Math.ceil(totalRecords / limit) || 1;

            params.push(limit, offset);
            const inventoryResult = await pool.query(`
                SELECT
                    p.id as product_id,
                    p.name as product_name,
                    p.product_code,
                    p.category,
                    p.price,
                    ml.name as label,
                    COUNT(iu.id) as available_units,
                    ARRAY_AGG(icm.id) as mapping_ids
                FROM inventory_unit iu
                JOIN product p ON p.id = iu.product_lid
                JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id
                JOIN mapping_label ml ON ml.id = icm.label_lid
                WHERE iu.status_lid = (SELECT id FROM inventory_status WHERE name = 'MAPPED')
                AND icm.company_lid = $1
                AND icm.active = TRUE AND iu.active = TRUE AND p.active = TRUE
                ${searchClause}
                GROUP BY p.id, p.name, p.product_code, p.category, p.price, ml.name
                ORDER BY p.name, p.product_code
                LIMIT $${params.length - 1} OFFSET $${params.length}
            `, params);

            res.status(200).json({
                message: 'success',
                status: 200,
                isSelf: false,
                data: inventoryResult.rows,
                pagination: {
                    currentPage:  page,
                    totalPages:   totalPages,
                    totalRecords: totalRecords,
                    limit:        limit,
                    hasNextPage:  page < totalPages,
                    hasPrevPage:  page > 1
                }
            });

        } catch (error) {
            console.error('Get available inventory error:', error);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Error fetching inventory' }
            });
        }
    },

    // POST /sales/sell  — create a sale receipt for SELF using unit IDs
    sell: async (req, res) => {
        try {
            const { unitIds, notes } = req.body;

            if (!unitIds || !Array.isArray(unitIds) || unitIds.length === 0) {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Please select units to sell' }
                });
            }

            const selfResult = await pool.query(
                `SELECT id FROM company WHERE company_type = 'SELF' AND active = TRUE LIMIT 1`
            );
            if (selfResult.rows.length === 0) {
                return res.status(400).json({ message: 'error', status: 400, data: { message: 'SELF company not found' } });
            }
            const selfCompanyId = selfResult.rows[0].id;

            const detailsResult = await pool.query(`
                SELECT iu.id AS unit_id, p.id AS product_id, p.price
                FROM inventory_unit iu
                JOIN product p ON p.id = iu.product_lid
                WHERE iu.id = ANY($1::int[])
                  AND iu.active = TRUE
                  AND iu.status_lid = (SELECT id FROM inventory_status WHERE name = 'AVAILABLE')
            `, [unitIds]);

            if (detailsResult.rows.length === 0) {
                return res.status(400).json({ message: 'error', status: 400, data: { message: 'No valid available units found' } });
            }

            const client = await pool.connect();
            let receiptNumber, receiptId, totalAmount = 0, totalUnits = 0;
            try {
                await client.query('BEGIN');

                const receiptNumResult = await client.query(`SELECT generate_sale_receipt_number() AS receipt_number`);
                receiptNumber = receiptNumResult.rows[0].receipt_number;

                const receiptResult = await client.query(`
                    INSERT INTO sale_receipt (receipt_number, company_lid, notes, created_by)
                    VALUES ($1, $2, $3, $4)
                    RETURNING id
                `, [receiptNumber, selfCompanyId, notes || null, 1]);
                receiptId = receiptResult.rows[0].id;

                for (const row of detailsResult.rows) {
                    const salePrice = parseFloat(row.price) || 0;

                    await client.query(`
                        INSERT INTO sale_receipt_item
                            (receipt_lid, inventory_unit_lid, product_lid, mapping_lid, sale_price, label)
                        VALUES ($1, $2, $3, NULL, $4, NULL)
                    `, [receiptId, row.unit_id, row.product_id, salePrice]);

                    await client.query(`
                        UPDATE inventory_unit
                        SET status_lid = (SELECT id FROM inventory_status WHERE name = 'SOLD'),
                            updated_at = CURRENT_TIMESTAMP,
                            updated_by = $1
                        WHERE id = $2
                    `, [1, row.unit_id]);

                    totalAmount += salePrice;
                    totalUnits++;
                }

                await client.query(`
                    UPDATE sale_receipt
                    SET total_units = $1, total_amount = $2, updated_at = CURRENT_TIMESTAMP
                    WHERE id = $3
                `, [totalUnits, totalAmount, receiptId]);

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
                    message:        `Successfully sold ${totalUnits} inventory unit(s)`,
                    receipt_number: receiptNumber,
                    receipt_id:     receiptId,
                    total_units:    totalUnits,
                    total_amount:   totalAmount
                }
            });
        } catch (e) {
            console.error('Sell direct error:', e);
            res.status(500).json({ message: 'error', status: 500, data: { message: 'Something went wrong!' } });
        }
    }
};
