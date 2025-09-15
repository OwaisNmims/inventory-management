const { pool } = require("../../../config/dbConfig");

module.exports = {
    // Get all products with inventory counts
    getAllProducts: () => {
        const statement = {
            text: `SELECT p.id, p.name, p.product_code, p.description, p.category, p.price, p.specifications,
                   p.created_at, p.updated_at, p.created_by, p.updated_by, p.active,
                   COUNT(iu.id) as unit,
                   COUNT(CASE WHEN ist.name = 'AVAILABLE' THEN 1 END) as available_units,
                   COUNT(CASE WHEN ist.name = 'MAPPED' THEN 1 END) as mapped_units,
                   COUNT(CASE WHEN ist.name = 'SOLD' THEN 1 END) as sold_units
                   FROM product p
                   JOIN inventory_unit iu ON iu.product_lid = p.id 
                   JOIN inventory_status ist ON ist.id = iu.status_lid
                   WHERE p.active = TRUE AND iu.active = TRUE
                   GROUP BY p.id, p.name, p.product_code, p.description, p.category, p.price, p.specifications,
                            p.created_at, p.updated_at, p.created_by, p.updated_by, p.active
                   ORDER BY p.name;`,
            values: []
        };
        return pool.query(statement);
    },

    // Insert products using the function that auto-creates inventory
    insert: (data) => {
        const statement = {
            text: `SELECT insert_products($1, $2);`,
            values: [JSON.stringify(data), 1]
        };
        return pool.query(statement);
    },

    // Update product (no inventory changes)
    updateProduct: (data) => {
        const statement = {
            text: `UPDATE product SET 
                   name = $2, product_code = $3, description = $4, category = $5, 
                   price = $6, specifications = $7, updated_at = CURRENT_TIMESTAMP, updated_by = $8
                   WHERE id = $1 AND active = TRUE
                   RETURNING *;`,
            values: [
                data.productLid,
                data.name,
                data.productCode,
                data.description,
                data.category,
                data.price,
                data.specifications,
                data.updatedBy || 1
            ]
        };
        return pool.query(statement);
    },

    // Soft delete product
    // write a function to delete product and all its inventory units and mapping to company
    // this should only happen if the product is not mapped to any company which is not self company
    // if the product is mapped to any company which is not self company, then it should not be deleted
    // if the product is mapped to self company, then it should be deleted
    // also if the inventory all units should be available.
    // give me sql function for this and handle it in the controller.
    
    deleteProduct: (data) => {
        const statement = {
            text: `SELECT delete_product($1, $2);`,
            values: [data.productLid, data.updatedBy || 1]
        };
        return pool.query(statement);
    },

    // Find product by ID
    findById: (productId) => {
        const statement = {
            text: `SELECT p.*, 
                   COUNT(iu.id) as unit,
                   COUNT(CASE WHEN ist.name = 'AVAILABLE' THEN 1 END) as available_units,
                   COUNT(CASE WHEN ist.name = 'MAPPED' THEN 1 END) as mapped_units,
                   COUNT(CASE WHEN ist.name = 'SOLD' THEN 1 END) as sold_units
                   FROM product p
                   LEFT JOIN inventory_unit iu ON iu.product_lid = p.id AND iu.active = TRUE
                   LEFT JOIN inventory_status ist ON ist.id = iu.status_lid
                   WHERE p.id = $1 AND p.active = TRUE
                   GROUP BY p.id;`,
            values: [productId]
        };
        return pool.query(statement);
    },

    // Get all active products (simple list)
    findAllActive: () => {
        const statement = {
            text: `SELECT id, name, product_code, price FROM product WHERE active = TRUE ORDER BY name;`,
            values: []
        };
        return pool.query(statement);
    }
};