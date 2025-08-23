const product = require('../models/admin/masters/product');

module.exports = {

    getProductById: async (req, res) => {
        try {
            const { productId } = req.params;
            
            const result = await product.findById(productId);
            
            if (result.rows.length > 0) {
                res.status(200).json({
                    message: 'success',
                    status: 200,
                    data: result.rows[0]
                });
            } else {
                res.status(404).json({
                    message: 'Product not found',
                    status: 404,
                    data: null
                });
            }

        } catch (e) {
            console.error('Product fetch error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    productMaster: async (req, res) => {
        let { _user } = {
            ...req.body,
        };

        if (req.method == "GET") {
            const products = await product.getAllProducts();
            console.log('products>>> ', products.rows);
            res.render("admin/master/product", {
                products: products ? products.rows : []
            });
        }
    },

    insert: async (req, res) => {
        try {
            let { _user, productList } = {
                ...req.body,
            };

            const result = await product.insert(productList);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].insert_products
            });

        } catch (e) {
            console.error('Product insert error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    updateProduct: async (req, res) => {
        try {
            let { _user, productData } = {
                ...req.body,
            };

            const result = await product.updateProduct(productData);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].update_product
            });

        } catch (e) {
            console.error('Product update error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    deleteProduct: async (req, res) => {
        try {
            let { _user, productLid } = {
                ...req.body,
            };

            const result = await product.deleteProduct({ productLid });
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result
            });

        } catch (e) {
            console.error('Product delete error:', e);
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