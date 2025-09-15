const { pool } = require("../../../config/dbConfig");

module.exports = {
    // Get all orders with company and inventory details
    getAllOrders: () => {
        const statement = {
            text: `SELECT 
                   co.id as order_id,
                   co.order_number,
                   co.created_at as order_date,
                   co.notes as order_notes,
                   c.name as customer_company_name,
                   c.company_code as customer_company_code,
                   c.company_type as customer_company_type,
                   COUNT(coi.id) as total_items,
                   COUNT(coi.id) as total_quantity,
                   SUM(COALESCE(p.price, 0)) as total_amount,
                   co.created_at,
                   'COMPLETED' as order_status
                   FROM customer_order co
                   LEFT JOIN company c ON c.id = co.company_lid
                   LEFT JOIN customer_order_item coi ON coi.order_lid = co.id AND coi.active = TRUE
                   LEFT JOIN product p ON p.id = coi.product_lid
                   WHERE co.active = TRUE
                   GROUP BY co.id, c.id
                   ORDER BY co.created_at DESC;`,
            values: []
        };
        return pool.query(statement);
    },

    // Get order details with inventory mappings
    getOrderDetails: (orderId) => {
        const statement = {
            text: `SELECT 
                   co.id as order_id,
                   co.order_number,
                   co.created_at as order_date,
                   co.notes as order_notes,
                   c.name as customer_company_name,
                   c.company_code as customer_company_code,
                   c.company_type as customer_company_type,
                   coi.id as order_item_id,
                   1 as quantity,
                   p.price as unit_price,
                   p.price as total_price,
                   p.name as product_name,
                   p.product_code,
                   p.category,
                   iu.id as inventory_id,
                   ist.name as inventory_status,
                   icm.id as mapping_id,
                   mc.name as mapped_company_name,
                   mc.company_code as mapped_company_code,
                   mc.company_type as mapped_company_type,
                   ml.name as mapping_label,
                   icm.created_at as mapped_at,
                   'COMPLETED' as order_status,
                   SUM(p.price) OVER (PARTITION BY co.id) as total_amount
                   FROM customer_order co
                   LEFT JOIN company c ON c.id = co.company_lid
                   LEFT JOIN customer_order_item coi ON coi.order_lid = co.id AND coi.active = TRUE
                   LEFT JOIN inventory_unit iu ON iu.id = coi.inventory_unit_lid
                   LEFT JOIN product p ON p.id = iu.product_lid
                   LEFT JOIN inventory_status ist ON ist.id = iu.status_lid
                   LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                   LEFT JOIN company mc ON mc.id = icm.company_lid
                   LEFT JOIN mapping_label ml ON ml.id = icm.label_lid
                   WHERE co.id = $1 AND co.active = TRUE
                   ORDER BY coi.id;`,
            values: [orderId]
        };
        return pool.query(statement);
    },

    // Get orders by company (which companies have mapped products in orders)
    getOrdersByCompany: (companyId) => {
        const statement = {
            text: `SELECT DISTINCT
                   co.id as order_id,
                   co.order_number,
                   co.order_date,
                   co.total_amount,
                   co.status as order_status,
                   c.name as customer_company_name,
                   COUNT(DISTINCT coi.id) as mapped_items_count,
                   SUM(coi.total_price) as mapped_items_value
                   FROM customer_order co
                   JOIN customer_order_item coi ON coi.order_lid = co.id AND coi.active = TRUE
                   JOIN inventory_unit iu ON iu.id = coi.inventory_unit_lid
                   JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                   LEFT JOIN company c ON c.id = co.customer_company_lid
                   WHERE icm.company_lid = $1 AND co.active = TRUE
                   GROUP BY co.id, c.id
                   ORDER BY co.created_at DESC;`,
            values: [companyId]
        };
        return pool.query(statement);
    },

    // Get summary of orders and mappings
    getOrdersSummary: () => {
        const statement = {
            text: `SELECT 
                   COUNT(DISTINCT co.id) as total_orders,
                   COUNT(DISTINCT coi.id) as total_order_items,
                   COUNT(DISTINCT icm.company_lid) as companies_with_mappings,
                   SUM(co.total_amount) as total_order_value,
                   COUNT(DISTINCT CASE WHEN co.status = 'COMPLETED' THEN co.id END) as completed_orders,
                   COUNT(DISTINCT CASE WHEN co.status = 'PENDING' THEN co.id END) as pending_orders
                   FROM customer_order co
                   LEFT JOIN customer_order_item coi ON coi.order_lid = co.id AND coi.active = TRUE
                   LEFT JOIN inventory_unit iu ON iu.id = coi.inventory_unit_lid
                   LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                   WHERE co.active = TRUE;`,
            values: []
        };
        return pool.query(statement);
    }
};
