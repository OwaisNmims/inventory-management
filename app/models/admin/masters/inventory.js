const { pool } = require("../../../config/dbConfig");

module.exports = {
    // Get all inventory units with product, company, and status details
    getAllInventoryUnits: () => {
        const statement = {
            text: `SELECT 
                   iu.id as inventory_id,
                   p.id as product_id,
                   p.name as product_name,
                   p.product_code,
                   p.category,
                   p.price,
                   ist.name as status,
                   ist.description as status_description,
                   c.name as current_company_name,
                   c.company_code as current_company_code,
                   c.company_type,
                   icm.id as mapping_id,
                   icm.company_lid as mapped_company_id,
                   mc.name as mapped_company_name,
                   mc.company_code as mapped_company_code,
                   ml.name as mapping_label,
                   ml.description as mapping_label_description,
                   icm.notes as mapping_notes,
                   icm.created_at as mapped_at,
                   iu.created_at as inventory_created_at,
                   iu.updated_at as inventory_updated_at
                   FROM inventory_unit iu
                   JOIN product p ON p.id = iu.product_lid
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   LEFT JOIN company c ON c.id = iu.current_company_lid
                   LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                   LEFT JOIN company mc ON mc.id = icm.company_lid
                   LEFT JOIN mapping_label ml ON ml.id = icm.label_lid
                   WHERE iu.active = TRUE AND p.active = TRUE
                   ORDER BY p.name, iu.id;`,
            values: []
        };
        return pool.query(statement);
    },

    // Get inventory units by product ID
    getInventoryByProduct: (productId) => {
        const statement = {
            text: `SELECT 
                   iu.id as inventory_id,
                   p.name as product_name,
                   p.product_code,
                   ist.name as status,
                   c.name as current_company_name,
                   c.company_code as current_company_code,
                   icm.id as mapping_id,
                   mc.name as mapped_company_name,
                   ml.name as mapping_label,
                   icm.notes as mapping_notes,
                   icm.created_at as mapped_at
                   FROM inventory_unit iu
                   JOIN product p ON p.id = iu.product_lid
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   LEFT JOIN company c ON c.id = iu.current_company_lid
                   LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                   LEFT JOIN company mc ON mc.id = icm.company_lid
                   LEFT JOIN mapping_label ml ON ml.id = icm.label_lid
                   WHERE iu.active = TRUE AND p.active = TRUE AND p.id = $1
                   ORDER BY iu.id;`,
            values: [productId]
        };
        return pool.query(statement);
    },

    // Get inventory units by company ID
    getInventoryByCompany: (companyId) => {
        const statement = {
            text: `SELECT 
                   iu.id as inventory_id,
                   p.name as product_name,
                   p.product_code,
                   p.category,
                   p.price,
                   ist.name as status,
                   c.name as current_company_name,
                   icm.id as mapping_id,
                   ml.name as mapping_label,
                   icm.notes as mapping_notes,
                   icm.created_at as mapped_at
                   FROM inventory_unit iu
                   JOIN product p ON p.id = iu.product_lid
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   LEFT JOIN company c ON c.id = iu.current_company_lid
                   JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                   LEFT JOIN mapping_label ml ON ml.id = icm.label_lid
                   WHERE iu.active = TRUE AND p.active = TRUE AND icm.company_lid = $1
                   ORDER BY p.name, iu.id;`,
            values: [companyId]
        };
        return pool.query(statement);
    },

    // Get inventory summary by status
    getInventorySummary: () => {
        const statement = {
            text: `SELECT 
                   ist.name as status,
                   COUNT(iu.id) as count,
                   COUNT(DISTINCT p.id) as unique_products
                   FROM inventory_unit iu
                   JOIN product p ON p.id = iu.product_lid
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   WHERE iu.active = TRUE AND p.active = TRUE
                   GROUP BY ist.name, ist.id
                   ORDER BY ist.name;`,
            values: []
        };
        return pool.query(statement);
    },

    // Get available inventory units for mapping
    getAvailableInventory: () => {
        const statement = {
            text: `SELECT 
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
                   WHERE iu.active = TRUE AND p.active = TRUE AND ist.name = 'AVAILABLE'
                   ORDER BY p.name, iu.id;`,
            values: []
        };
        return pool.query(statement);
    },

    // Update inventory unit status
    updateInventoryStatus: (inventoryId, statusName, updatedBy = 1) => {
        const statement = {
            text: `UPDATE inventory_unit 
                   SET status_lid = (SELECT id FROM inventory_status WHERE name = $2 AND active = TRUE),
                       updated_at = CURRENT_TIMESTAMP,
                       updated_by = $3
                   WHERE id = $1 AND active = TRUE
                   RETURNING *;`,
            values: [inventoryId, statusName, updatedBy]
        };
        return pool.query(statement);
    }
};
