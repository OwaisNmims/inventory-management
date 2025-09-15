const order = require('../models/admin/masters/order');
const { pool } = require('../config/dbConfig');

module.exports = {
    // Render order tracking page
    orderTrackingMaster: async (req, res) => {
        try {
            if (req.method === "GET") {
                // Get all orders
                const orders = await order.getAllOrders();
                
                // Get orders summary
                const summary = await order.getOrdersSummary();
                
                // Get all companies for filter dropdown
                const companiesResult = await pool.query(`
                    SELECT DISTINCT c.id, c.name, c.company_code, c.company_type 
                    FROM company c
                    JOIN inventory_company_mapping icm ON icm.company_lid = c.id
                    WHERE c.active = TRUE AND icm.active = TRUE
                    ORDER BY c.name
                `);
                
                // Get company mapping statistics
                const companyStatsResult = await pool.query(`
                    SELECT 
                        c.name as company_name,
                        c.company_type,
                        COUNT(DISTINCT co.id) as orders_count,
                        COUNT(DISTINCT coi.id) as items_count,
                        SUM(coi.total_price) as total_value
                    FROM company c
                    JOIN inventory_company_mapping icm ON icm.company_lid = c.id AND icm.active = TRUE
                    JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
                    JOIN customer_order_item coi ON coi.inventory_unit_lid = iu.id AND coi.active = TRUE
                    JOIN customer_order co ON co.id = coi.order_lid AND co.active = TRUE
                    WHERE c.active = TRUE
                    GROUP BY c.id, c.name, c.company_type
                    ORDER BY total_value DESC
                `);
                
                res.render("admin/master/orderTracking", {
                    orders: orders.rows,
                    summary: summary.rows[0] || {},
                    companies: companiesResult.rows,
                    companyStats: companyStatsResult.rows
                });
            }
        } catch (e) {
            console.error('Order tracking master error:', e);
            res.status(500).render("error", { message: "Something went wrong!" });
        }
    },

    // Get order details (API)
    getOrderDetails: async (req, res) => {
        try {
            const { orderId } = req.params;
            const orderDetails = await order.getOrderDetails(orderId);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: orderDetails.rows
            });
        } catch (e) {
            console.error('Get order details error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Get orders by company (API)
    getOrdersByCompany: async (req, res) => {
        try {
            const { companyId } = req.params;
            const companyOrders = await order.getOrdersByCompany(companyId);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: companyOrders.rows
            });
        } catch (e) {
            console.error('Get orders by company error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    }
};
