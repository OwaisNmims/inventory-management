const inventory = require('../models/admin/masters/inventory');
const { pool } = require('../config/dbConfig');

module.exports = {
    // Render inventory mapping page
    inventoryMappingMaster: async (req, res) => {
        try {
            if (req.method === "GET") {
                // Get all companies for dropdown
                const companiesResult = await pool.query(`
                    SELECT id, name, company_code, company_type, state_lid, city_lid 
                    FROM company 
                    WHERE active = TRUE 
                    ORDER BY name
                `);
                
                // Get all states for filter dropdown
                const statesResult = await pool.query(`
                    SELECT id, name 
                    FROM state 
                    WHERE active = TRUE 
                    ORDER BY name
                `);
                
                // Get all cities for filter dropdown
                const citiesResult = await pool.query(`
                    SELECT id, name, state_lid 
                    FROM city 
                    WHERE active = TRUE 
                    ORDER BY name
                `);
                
                // Get initial available inventory (first page only for performance)
                const [countResult, availableInventoryResult] = await inventory.getAvailableInventoryPaginated(1, 20, '', 'product_name', 'ASC');
                
                // Get all mappings with price information (for now, we'll paginate this later)
                const mappingsResult = await pool.query(`
                    SELECT 
                        icm.id as mapping_id,
                        iu.id as inventory_id,
                        p.name as product_name,
                        p.product_code,
                        p.price,
                        p.category,
                        c.name as company_name,
                        c.company_code,
                        c.company_type,
                        CASE 
                            WHEN ist.name = 'SOLD' THEN 'SOLD'
                            ELSE ml.name 
                        END as label,
                        icm.notes,
                        icm.created_at as mapped_at,
                        ist.name as status
                    FROM inventory_company_mapping icm
                    JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
                    JOIN product p ON p.id = iu.product_lid
                    JOIN company c ON c.id = icm.company_lid
                    JOIN mapping_label ml ON ml.id = icm.label_lid
                    JOIN inventory_status ist ON ist.id = iu.status_lid
                    WHERE icm.active = TRUE AND iu.active = TRUE AND p.active = TRUE
                    ORDER BY icm.created_at DESC
                `);

                // Calculate totals by company including NEW/OLD labels
                const totalsResult = await pool.query(`
                    SELECT 
                        c.name as company_name,
                        c.company_type,
                        COUNT(iu.id) as total_units,
                        SUM(CASE WHEN ist.name = 'AVAILABLE' THEN 1 ELSE 0 END) as available_units,
                        SUM(CASE WHEN ist.name = 'MAPPED' THEN 1 ELSE 0 END) as mapped_units,
                        SUM(CASE WHEN ist.name = 'SOLD' THEN 1 ELSE 0 END) as sold_units,
                        SUM(CASE WHEN ml.name = 'NEW' AND ist.name != 'SOLD' THEN 1 ELSE 0 END) as new_stock,
                        SUM(CASE WHEN ml.name = 'OLD' AND ist.name != 'SOLD' THEN 1 ELSE 0 END) as old_stock,
                        SUM(COALESCE(p.price, 0)) as total_value,
                        SUM(CASE WHEN ist.name = 'SOLD' THEN COALESCE(p.price, 0) ELSE 0 END) as sold_value,
                        SUM(CASE WHEN ml.name = 'NEW' AND ist.name != 'SOLD' THEN COALESCE(p.price, 0) ELSE 0 END) as new_stock_value,
                        SUM(CASE WHEN ml.name = 'OLD' AND ist.name != 'SOLD' THEN COALESCE(p.price, 0) ELSE 0 END) as old_stock_value
                    FROM inventory_company_mapping icm
                    JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
                    JOIN product p ON p.id = iu.product_lid
                    JOIN company c ON c.id = icm.company_lid
                    JOIN mapping_label ml ON ml.id = icm.label_lid
                    JOIN inventory_status ist ON ist.id = iu.status_lid
                    WHERE icm.active = TRUE AND iu.active = TRUE AND p.active = TRUE
                    GROUP BY c.id, c.name, c.company_type
                    ORDER BY c.name
                `);
                
                res.render("admin/master/inventoryMapping", {
                    companies: companiesResult.rows,
                    states: statesResult.rows,
                    cities: citiesResult.rows,
                    availableInventory: availableInventoryResult.rows,
                    mappings: mappingsResult.rows,
                    totals: totalsResult.rows
                });
            }
        } catch (e) {
            console.error('Inventory mapping master error:', e);
            res.status(500).render("error", { message: "Something went wrong!" });
        }
    },

    // Create inventory mapping
    createMapping: async (req, res) => {
        try {
            const { productQuantities, companyId, notes } = req.body;
            
            if (!productQuantities || !Array.isArray(productQuantities) || productQuantities.length === 0) {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Please select products with quantities to map' }
                });
            }

            // Get label IDs
            const labelResult = await pool.query(`
                SELECT id FROM mapping_label WHERE name = 'NEW' AND active = TRUE LIMIT 1
            `);
            const labelId = labelResult.rows[0]?.id;

            if (!labelId) {
                return res.status(500).json({
                    message: 'error',
                    status: 500,
                    data: { message: 'Mapping label not found' }
                });
            }

            // Check if company exists and is not SELF
            const companyResult = await pool.query(`
                SELECT company_code FROM company WHERE id = $1 AND active = TRUE
            `, [companyId]);

            if (companyResult.rows.length === 0) {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Invalid company selected' }
                });
            }

            // Mark ALL existing mappings for this company as OLD (company-wide)
            await pool.query(`
                UPDATE inventory_company_mapping 
                SET label_lid = (SELECT id FROM mapping_label WHERE name = 'OLD' AND active = TRUE),
                    updated_at = CURRENT_TIMESTAMP,
                    updated_by = $1
                WHERE company_lid = $2 
                AND active = TRUE
            `, [1, companyId]);

            let totalMappedUnits = 0;

            // Process each product quantity
            for (const { productId, quantity } of productQuantities) {
                // Get available inventory units for this product (FIFO - oldest first)
                const availableUnitsResult = await pool.query(`
                    SELECT iu.id 
                    FROM inventory_unit iu
                    JOIN company c ON c.id = iu.current_company_lid
                    JOIN inventory_status ist ON ist.id = iu.status_lid
                    WHERE iu.product_lid = $1 
                    AND iu.active = TRUE 
                    AND c.company_code = 'SELF'
                    AND ist.name = 'AVAILABLE'
                    ORDER BY iu.created_at ASC
                    LIMIT $2
                `, [productId, quantity]);

                const availableUnits = availableUnitsResult.rows;

                if (availableUnits.length < quantity) {
                    return res.status(400).json({
                        message: 'error',
                        status: 400,
                        data: { message: `Not enough available units for product ID ${productId}. Requested: ${quantity}, Available: ${availableUnits.length}` }
                    });
                }

                // Map each selected unit
                for (const unit of availableUnits) {
                    // Update inventory unit status and company
                    await pool.query(`
                        UPDATE inventory_unit 
                        SET status_lid = (SELECT id FROM inventory_status WHERE name = 'MAPPED'),
                            current_company_lid = $1,
                            updated_at = CURRENT_TIMESTAMP,
                            updated_by = $2
                        WHERE id = $3
                    `, [companyId, 1, unit.id]);

                    // UPSERT mapping - update if exists, insert if not
                    await pool.query(`
                        INSERT INTO inventory_company_mapping (inventory_unit_lid, company_lid, label_lid, notes, created_by)
                        VALUES ($1, $2, $3, $4, $5)
                        ON CONFLICT (inventory_unit_lid) 
                        DO UPDATE SET 
                            company_lid = EXCLUDED.company_lid,
                            label_lid = EXCLUDED.label_lid,
                            notes = EXCLUDED.notes,
                            updated_at = CURRENT_TIMESTAMP,
                            updated_by = $5,
                            active = TRUE
                    `, [unit.id, companyId, labelId, notes || 'Quantity-based mapping', 1]);

                    totalMappedUnits++;
                }
            }

            res.status(200).json({
                message: 'success',
                status: 200,
                data: { message: `Successfully mapped ${totalMappedUnits} inventory units across ${productQuantities.length} products` }
            });

        } catch (e) {
            console.error('Create mapping error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Transfer inventory back to SELF
    transferToSelf: async (req, res) => {
        try {
            const { mappingIds } = req.body;
            
            if (!mappingIds || !Array.isArray(mappingIds) || mappingIds.length === 0) {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Please select mappings to transfer' }
                });
            }

            // Get SELF company ID
            const selfCompanyResult = await pool.query(`
                SELECT id FROM company WHERE company_code = 'SELF' AND active = TRUE LIMIT 1
            `);
            const selfCompanyId = selfCompanyResult.rows[0]?.id;

            if (!selfCompanyId) {
                return res.status(500).json({
                    message: 'error',
                    status: 500,
                    data: { message: 'SELF company not found' }
                });
            }

            // Transfer mappings back to SELF
            for (const mappingId of mappingIds) {
                // Get inventory unit ID from mapping
                const mappingResult = await pool.query(`
                    SELECT inventory_unit_lid FROM inventory_company_mapping 
                    WHERE id = $1 AND active = TRUE
                `, [mappingId]);

                if (mappingResult.rows.length > 0) {
                    const inventoryUnitId = mappingResult.rows[0].inventory_unit_lid;

                    // Update inventory unit
                    await pool.query(`
                        UPDATE inventory_unit 
                        SET status_lid = (SELECT id FROM inventory_status WHERE name = 'AVAILABLE'),
                            current_company_lid = $1,
                            updated_at = CURRENT_TIMESTAMP,
                            updated_by = $2
                        WHERE id = $3
                    `, [selfCompanyId, 1, inventoryUnitId]);

                    // UPSERT mapping to SELF (no need to deactivate first)
                    await pool.query(`
                        INSERT INTO inventory_company_mapping (inventory_unit_lid, company_lid, label_lid, notes, created_by)
                        VALUES ($1, $2, (SELECT id FROM mapping_label WHERE name = 'NEW'), 'Transferred back to SELF', $3)
                        ON CONFLICT (inventory_unit_lid) 
                        DO UPDATE SET 
                            company_lid = EXCLUDED.company_lid,
                            label_lid = EXCLUDED.label_lid,
                            notes = EXCLUDED.notes,
                            updated_at = CURRENT_TIMESTAMP,
                            updated_by = EXCLUDED.created_by,
                            active = TRUE
                    `, [inventoryUnitId, selfCompanyId, 1]);
                }
            }

            res.status(200).json({
                message: 'success',
                status: 200,
                data: { message: `Successfully transferred ${mappingIds.length} inventory units back to SELF` }
            });

        } catch (e) {
            console.error('Transfer to SELF error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Mark inventory as sold
    markAsSold: async (req, res) => {
        try {
            const { mappingIds } = req.body;
            
            if (!mappingIds || !Array.isArray(mappingIds) || mappingIds.length === 0) {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Please select mappings to mark as sold' }
                });
            }

            // Mark inventory units as SOLD
            for (const mappingId of mappingIds) {
                // Get inventory unit ID from mapping
                const mappingResult = await pool.query(`
                    SELECT inventory_unit_lid FROM inventory_company_mapping 
                    WHERE id = $1 AND active = TRUE
                `, [mappingId]);

                if (mappingResult.rows.length > 0) {
                    const inventoryUnitId = mappingResult.rows[0].inventory_unit_lid;

                    // Update inventory unit status to SOLD
                    await pool.query(`
                        UPDATE inventory_unit 
                        SET status_lid = (SELECT id FROM inventory_status WHERE name = 'SOLD'),
                            updated_at = CURRENT_TIMESTAMP,
                            updated_by = $1
                        WHERE id = $2
                    `, [1, inventoryUnitId]);
                }
            }

            res.status(200).json({
                message: 'success',
                status: 200,
                data: { message: `Successfully marked ${mappingIds.length} inventory units as SOLD` }
            });

        } catch (e) {
            console.error('Mark as sold error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Get paginated available inventory with search
    getAvailableInventoryPaginated: async (req, res) => {
        try {
            const { 
                page = 1, 
                limit = 20, 
                search = '', 
                sortBy = 'product_name', 
                sortOrder = 'ASC' 
            } = req.query;

            // Use model method for pagination
            const [countResult, dataResult] = await inventory.getAvailableInventoryPaginated(
                parseInt(page), 
                parseInt(limit), 
                search, 
                sortBy, 
                sortOrder
            );

            const totalRecords = parseInt(countResult.rows[0].total);
            const totalPages = Math.ceil(totalRecords / parseInt(limit));
            const hasNextPage = parseInt(page) < totalPages;
            const hasPrevPage = parseInt(page) > 1;

            res.status(200).json({
                message: 'success',
                status: 200,
                data: {
                    items: dataResult.rows,
                    pagination: {
                        currentPage: parseInt(page),
                        totalPages: totalPages,
                        totalRecords: totalRecords,
                        limit: parseInt(limit),
                        hasNextPage: hasNextPage,
                        hasPrevPage: hasPrevPage
                    },
                    search: {
                        term: search,
                        results: dataResult.rows.length
                    }
                }
            });

        } catch (e) {
            console.error('Get paginated available inventory error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Get products with available units for quantity-based mapping
    getProductsForMapping: async (req, res) => {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 20;
            const search = req.query.search || '';
            const sortBy = req.query.sortBy || 'p.name';
            const sortOrder = req.query.sortOrder || 'ASC';

            const [countResult, dataResult] = await inventory.getProductsWithAvailableUnits(
                page,
                limit,
                search,
                sortBy,
                sortOrder
            );

            const totalRecords = parseInt(countResult.rows[0].total);
            const totalPages = Math.ceil(totalRecords / limit);

            return res.status(200).json({
                status: 200,
                message: 'success',
                data: {
                    items: dataResult.rows,
                    pagination: {
                        currentPage: page,
                        pageSize: limit,
                        totalRecords: totalRecords,
                        totalPages: totalPages,
                        hasNextPage: page < totalPages,
                        hasPrevPage: page > 1
                    }
                }
            });
        } catch (error) {
            console.error('Error fetching products for mapping:', error);
            return res.status(500).json({
                status: 500,
                message: 'error',
                error: 'Failed to fetch products'
            });
        }
    },

    // Get grouped inventory mappings (by product and company)
    getInventoryMappingsGrouped: async (req, res) => {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 20;
            const search = req.query.search || '';
            const sortBy = req.query.sortBy || 'product_name';
            const sortOrder = req.query.sortOrder || 'ASC';

            // Build filters object
            const filters = {};
            if (req.query.company && req.query.company.trim()) {
                filters.company = req.query.company;
            }
            if (req.query.product && req.query.product.trim()) {
                filters.product = req.query.product;
            }
            if (req.query.state && req.query.state.trim()) {
                filters.state = req.query.state;
            }
            if (req.query.city && req.query.city.trim()) {
                filters.city = req.query.city;
            }

            const [countResult, dataResult] = await inventory.getInventoryMappingsGrouped(
                page, 
                limit, 
                search, 
                filters, 
                sortBy, 
                sortOrder
            );

            const totalRecords = parseInt(countResult.rows[0]?.total || 0);
            const totalPages = Math.ceil(totalRecords / limit);

            res.status(200).json({
                message: 'success',
                status: 200,
                data: {
                    items: dataResult.rows,
                    pagination: {
                        currentPage: page,
                        totalPages: totalPages,
                        totalRecords: totalRecords,
                        pageSize: limit,
                        hasNextPage: page < totalPages,
                        hasPrevPage: page > 1
                    },
                    filters: filters,
                    search: search
                }
            });
        } catch (e) {
            console.error('Inventory mappings grouped error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Get paginated inventory mappings with search and filters (detailed view)
    getInventoryMappingsPaginated: async (req, res) => {
        try {
            const { 
                page = 1, 
                limit = 20, 
                search = '', 
                company = '',
                label = '',
                product = '',
                exactProduct = '',
                state = '',
                city = '',
                sortBy = 'icm.created_at', 
                sortOrder = 'DESC' 
            } = req.query;

            // Build filters object
            const filters = {
                company: company,
                label: label,
                product: product,
                exactProduct: exactProduct,
                state: state,
                city: city
            };

            // Use model method for pagination
            const [countResult, dataResult] = await inventory.getInventoryMappingsPaginated(
                parseInt(page), 
                parseInt(limit), 
                search,
                filters,
                sortBy, 
                sortOrder
            );

            const totalRecords = parseInt(countResult.rows[0].total);
            const totalPages = Math.ceil(totalRecords / parseInt(limit));
            const hasNextPage = parseInt(page) < totalPages;
            const hasPrevPage = parseInt(page) > 1;

            res.status(200).json({
                message: 'success',
                status: 200,
                data: {
                    items: dataResult.rows,
                    pagination: {
                        currentPage: parseInt(page),
                        totalPages: totalPages,
                        totalRecords: totalRecords,
                        limit: parseInt(limit),
                        hasNextPage: hasNextPage,
                        hasPrevPage: hasPrevPage
                    },
                    search: {
                        term: search,
                        results: dataResult.rows.length
                    },
                    filters: filters
                }
            });

        } catch (e) {
            console.error('Get paginated inventory mappings error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    }
};
