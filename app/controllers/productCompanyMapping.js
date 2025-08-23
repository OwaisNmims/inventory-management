const productCompanyMapping = require('../models/admin/masters/productCompanyMapping');
const Product = require('../models/admin/masters/product');
const Company = require('../models/admin/masters/company');
const Label = require('../models/admin/masters/label');

module.exports = {

    productCompanyMappingMaster: async (req, res) => {
        let { _user } = {
            ...req.body,
        };

        if (req.method == "GET") {
            const mappings = await productCompanyMapping.getAllMappings();
            const products = await Product.findAllAvailableForMapping();
            const companies = await Company.findAllActiveWithType();
            const labels = await Label.findAllActive();
            const allProducts = await Product.getAllProducts();
            
            console.log('mappings>>> ', mappings.rows);
            res.render("admin/master/productCompanyMapping", {
                mappings: mappings ? mappings.rows : [],
                products: products ? products.rows : [],
                companies: companies ? companies.rows : [],
                labels: labels ? labels.rows : [],
                allProducts: allProducts ? allProducts.rows : []
            });
        }
    },

    createMapping: async (req, res) => {
        try {
            let { _user, productLid, companyLid, notes } = {
                ...req.body,
            };

            const result = await productCompanyMapping.createMapping(productLid, companyLid, notes, _user?.id || 1);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].map_product_to_company
            });

        } catch (e) {
            console.error('Product mapping create error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    updateMappingLabel: async (req, res) => {
        try {
            let { _user, mappingId, labelLid } = {
                ...req.body,
            };

            const result = await productCompanyMapping.updateMappingLabel(mappingId, labelLid, _user?.id || 1);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].update_product_mapping_label
            });

        } catch (e) {
            console.error('Product mapping update error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    deleteMapping: async (req, res) => {
        try {
            let { _user, mappingId } = {
                ...req.body,
            };

            const result = await productCompanyMapping.deleteMapping({ mappingId });
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result
            });

        } catch (e) {
            console.error('Product mapping delete error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    getMappingsByCompany: async (req, res) => {
        try {
            const { companyLid } = req.query;
            const result = await productCompanyMapping.getMappingsByCompany(companyLid);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });

        } catch (e) {
            console.error('Get mappings by company error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    bulkMapProducts: async (req, res) => {
        try {
            let { _user, productIds, companyLid, notes } = {
                ...req.body,
            };

            if (!productIds || !Array.isArray(productIds) || productIds.length === 0) {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Product IDs array is required' }
                });
            }

            const result = await productCompanyMapping.bulkMapProducts(productIds, companyLid, notes, _user?.id || 1);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].bulk_map_products_to_company
            });

        } catch (e) {
            console.error('Bulk mapping error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    recordSales: async (req, res) => {
        try {
            let { _user, items, companyLid, notes } = { ...req.body };
            if (!items || !Array.isArray(items) || items.length === 0) {
                return res.status(400).json({ message: 'error', status: 400, data: { message: 'Items array is required' } });
            }
            const result = await productCompanyMapping.recordProductSales(items, companyLid, notes, _user?.id || 1);
            res.status(200).json({ message: 'success', status: 200, data: result.rows[0].record_product_sales });
        } catch (e) {
            console.error('Record sales error:', e);
            res.status(500).json({ message: 'error', status: 500, data: { message: 'Something went wrong!' } });
        }
    },

    getProductAvailability: async (req, res) => {
        try {
            const { productId } = req.params;
            
            const result = await productCompanyMapping.getProductAvailability(productId);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].get_product_availability
            });

        } catch (e) {
            console.error('Get product availability error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    getMappingReceipts: async (req, res) => {
        try {
            const result = await productCompanyMapping.getMappingReceipts();
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });

        } catch (e) {
            console.error('Get mapping receipts error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    receiptsPage: async (req, res) => {
        try {
            if (req.method == "GET") {
                res.render("admin/receipts", {
                    pageTitle: "Mapping Receipts"
                });
            }
        } catch (e) {
            console.error('Receipts page error:', e);
            res.status(500).render('error', { 
                message: 'Error loading receipts page' 
            });
        }
    },

    validateDataIntegrity: async (req, res) => {
        try {
            const result = await productCompanyMapping.validateDataIntegrity();
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });

        } catch (e) {
            console.error('Data integrity validation error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    transferProduct: async (req, res) => {
        try {
            let { _user, mappingId, newCompanyLid, notes } = {
                ...req.body,
            };

            const result = await productCompanyMapping.transferProduct(mappingId, newCompanyLid, notes, _user?.id || 1);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].transfer_product_to_company
            });

        } catch (e) {
            console.error('Product transfer error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    }

}; 