const { pool } = require("../../../config/dbConfig");

module.exports = {
    getAllProducts: () => {
        const statement = {
            text: `SELECT id, name, product_code, description, category, price, unit, specifications,
                   created_at, updated_at, created_by, updated_by, active 
                   FROM product
                   WHERE active = TRUE
                   ORDER BY name;`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    insert: (data) => {
        const statement = {
            text: `SELECT insert_products($1, $2);`,
            values: [JSON.stringify(data), 1]
        };
        return pool.query(statement);
    },

    updateProduct: (data) => {
        const statement = {
            text: `SELECT update_product($1, $2, $3, $4, $5, $6, $7, $8, $9);`,
            values: [
                data.productLid,
                data.name,
                data.productCode,
                data.description,
                data.category,
                data.price,
                data.unit,
                data.specifications,
                data.updatedBy || 1
            ]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    deleteProduct: (data) => {
        const statement = {
            text: `UPDATE product SET active = false, updated_at = CURRENT_TIMESTAMP, updated_by = $2 WHERE id = $1;`,
            values: [data.productLid, 1]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    findById: (productId) => {
        const statement = {
            text: `SELECT * FROM product WHERE id = $1 AND active = TRUE;`,
            values: [productId]
        };
        return pool.query(statement);
    },

    findAllActive: () => {
        const statement = {
            text: `SELECT id, name, product_code, price FROM product WHERE active = TRUE ORDER BY name;`,
            values: []
        };
        return pool.query(statement);
    },

    findAllAvailableForMapping: () => {
        const statement = {
            text: `
                WITH mapped AS (
                  SELECT product_lid, COUNT(*) AS cnt
                  FROM product_company_mapping
                  WHERE active = TRUE
                  GROUP BY product_lid
                ), sold AS (
                  SELECT product_lid, COALESCE(SUM(quantity),0) AS qty
                  FROM product_sale
                  WHERE active = TRUE
                  GROUP BY product_lid
                )
                SELECT 
                    p.id, p.name, p.product_code, p.price, p.unit,
                    (p.unit - COALESCE(m.cnt, 0) - COALESCE(s.qty,0)) AS available_units
                FROM product p
                LEFT JOIN mapped m ON m.product_lid = p.id
                LEFT JOIN sold s ON s.product_lid = p.id
                WHERE p.active = TRUE
                  AND (p.unit - COALESCE(m.cnt, 0) - COALESCE(s.qty,0)) > 0
                ORDER BY p.name;
            `,
            values: []
        };
        return pool.query(statement);
    }

}; 