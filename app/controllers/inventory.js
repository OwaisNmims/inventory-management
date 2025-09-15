const inventory = require('../models/admin/masters/inventory');

module.exports = {
    // Render inventory master page
    inventoryMaster: async (req, res) => {
        try {
            if (req.method === "GET") {
                const inventoryUnits = await inventory.getAllInventoryUnits();
                const summary = await inventory.getInventorySummary();
                
                // Get all companies for filter dropdown
                const { pool } = require('../config/dbConfig');
                const companiesResult = await pool.query(`
                    SELECT DISTINCT c.id, c.name, c.company_code, c.company_type 
                    FROM company c
                    JOIN inventory_company_mapping icm ON icm.company_lid = c.id
                    WHERE c.active = TRUE AND icm.active = TRUE
                    ORDER BY c.name
                `);
                
                // Get all products for filter dropdown
                const productsResult = await pool.query(`
                    SELECT DISTINCT p.id, p.name, p.product_code
                    FROM product p
                    JOIN inventory_unit iu ON iu.product_lid = p.id
                    WHERE p.active = TRUE AND iu.active = TRUE
                    ORDER BY p.name
                `);
                
                res.render("admin/master/inventory", {
                    inventoryUnits: inventoryUnits ? inventoryUnits.rows : [],
                    summary: summary ? summary.rows : [],
                    companies: companiesResult.rows,
                    products: productsResult.rows
                });
            }
        } catch (e) {
            console.error('Inventory master error:', e);
            res.status(500).render("error", { message: "Something went wrong!" });
        }
    },

    // Get all inventory units (API)
    getAllInventory: async (req, res) => {
        try {
            const result = await inventory.getAllInventoryUnits();
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });
        } catch (e) {
            console.error('Get all inventory error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Get inventory by product ID
    getInventoryByProduct: async (req, res) => {
        try {
            const { productId } = req.params;
            const result = await inventory.getInventoryByProduct(productId);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });
        } catch (e) {
            console.error('Get inventory by product error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Get inventory by company ID
    getInventoryByCompany: async (req, res) => {
        try {
            const { companyId } = req.params;
            const result = await inventory.getInventoryByCompany(companyId);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });
        } catch (e) {
            console.error('Get inventory by company error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Get inventory summary
    getInventorySummary: async (req, res) => {
        try {
            const result = await inventory.getInventorySummary();
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });
        } catch (e) {
            console.error('Get inventory summary error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Get available inventory
    getAvailableInventory: async (req, res) => {
        try {
            const result = await inventory.getAvailableInventory();
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });
        } catch (e) {
            console.error('Get available inventory error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Update inventory status
    updateInventoryStatus: async (req, res) => {
        try {
            const { inventoryId, status } = req.body;
            
            const result = await inventory.updateInventoryStatus(inventoryId, status, 1);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: { message: 'Inventory status updated successfully!' }
            });
        } catch (e) {
            console.error('Update inventory status error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Get available inventory for mapping (API endpoint)
    getAvailableInventory: async (req, res) => {
        try {
            const { pool } = require('../config/dbConfig');
            
            // Get inventory that can be mapped to other companies (currently with SELF)
            const result = await pool.query(`
                SELECT
                    iu.id as inventory_id,
                    p.id as product_id,
                    p.name as product_name,
                    p.product_code,
                    p.category,
                    p.price,
                    ist.name as status
                FROM inventory_unit iu
                JOIN product p ON p.id = iu.product_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                JOIN company c ON c.id = icm.company_lid
                WHERE iu.active = TRUE 
                    AND p.active = TRUE 
                    AND ist.name = 'AVAILABLE'
                    AND c.company_type = 'SELF'
                ORDER BY p.name, iu.id
            `);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });
        } catch (e) {
            console.error('Get available inventory error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Delete inventory unit
    deleteInventoryUnit: async (req, res) => {
        try {
            const { inventoryId } = req.params;
            const { pool } = require('../config/dbConfig');

            // First check if the inventory unit exists and is AVAILABLE
            const checkResult = await pool.query(`
                SELECT 
                    iu.id,
                    p.name as product_name,
                    ist.name as status,
                    icm.company_lid,
                    c.company_type
                FROM inventory_unit iu
                JOIN product p ON p.id = iu.product_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                LEFT JOIN company c ON c.id = icm.company_lid
                WHERE iu.id = $1 AND iu.active = TRUE
            `, [inventoryId]);

            if (checkResult.rows.length === 0) {
                return res.status(404).json({
                    message: 'error',
                    status: 404,
                    data: { message: 'Inventory unit not found!' }
                });
            }

            const inventoryUnit = checkResult.rows[0];

            // Check if inventory is AVAILABLE
            if (inventoryUnit.status !== 'AVAILABLE') {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: `Cannot delete inventory unit. Status is ${inventoryUnit.status}. Only AVAILABLE inventory can be deleted.` }
                });
            }

            // Check if it's mapped to external company
            if (inventoryUnit.company_type && inventoryUnit.company_type !== 'SELF') {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Cannot delete inventory unit that is mapped to external company!' }
                });
            }

            // Begin transaction
            await pool.query('BEGIN');

            try {
                // Deactivate the inventory_company_mapping first
                await pool.query(`
                    UPDATE inventory_company_mapping 
                    SET active = FALSE, 
                        updated_at = CURRENT_TIMESTAMP,
                        updated_by = $1
                    WHERE inventory_unit_lid = $2 AND active = TRUE
                `, [1, inventoryId]);

                // Deactivate the inventory unit
                await pool.query(`
                    UPDATE inventory_unit 
                    SET active = FALSE, 
                        updated_at = CURRENT_TIMESTAMP,
                        updated_by = $1
                    WHERE id = $2 AND active = TRUE
                `, [1, inventoryId]);

                await pool.query('COMMIT');

                res.status(200).json({
                    message: 'success',
                    status: 200,
                    data: { message: `Inventory unit #${inventoryId} for "${inventoryUnit.product_name}" deleted successfully!` }
                });

            } catch (error) {
                await pool.query('ROLLBACK');
                throw error;
            }

        } catch (e) {
            console.error('Delete inventory unit error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    }
};
