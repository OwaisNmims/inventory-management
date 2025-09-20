const product = require('../models/admin/masters/product');

module.exports = {
    // Render product master page
    productMaster: async (req, res) => {
        try {
            if (req.method === "GET") {
                const products = await product.getAllProducts();
                res.render("admin/master/product", {
                    products: products ? products.rows : []
                });
            }
        } catch (e) {
            console.error('Product master error:', e);
            res.status(500).render("error", { message: "Something went wrong!" });
        }
    },

    // Get product by ID
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
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Insert new products (auto-creates inventory based on unit count)
    insert: async (req, res) => {
        try {
            let { _user, productList } = { ...req.body };

            const result = await product.insert(productList);
            const response = result.rows[0].insert_products;
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: response
            });
        } catch (e) {
            console.error('Product insert error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Update product
    updateProduct: async (req, res) => {
        try {
            let { _user, productData } = { ...req.body };

            const result = await product.updateProduct(productData);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: { message: 'Product updated successfully!' }
            });
        } catch (e) {
            console.error('Product update error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Delete product
    deleteProduct: async (req, res) => {
        try {
            let { _user, productLid } = { ...req.body };

            const result = await product.deleteProduct({ productLid, updatedBy: 1 });
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: { message: result.rows[0].delete_product }
            });
        } catch (e) {
            console.error('Product delete error:', e);
            
            // Handle specific business logic errors
            let errorMessage = 'Something went wrong!';
            if (e.message && e.message.includes('Product is mapped to a non-self company')) {
                errorMessage = 'Cannot delete product: It is mapped to external companies';
            } else if (e.message && e.message.includes('Inventory units are not available')) {
                errorMessage = 'Cannot delete product: Some inventory units are not available';
            }
            
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: errorMessage }
            });
        }
    },

    // Download Excel sample template
    downloadExcelSample: async (req, res) => {
        try {
            console.log('Excel download requested...');
            const XLSX = require('xlsx');
            
            // Create sample data
            const sampleData = [
                {
                    'Product Name': 'Sample Product 1',
                    'Product Code': 'SP001',
                    'Category': 'Electronics',
                    'Price': 999.99,
                    'Description': 'This is a sample product description',
                    'Specifications': 'Sample specifications for the product',
                    'Units': 5
                },
                {
                    'Product Name': 'Sample Product 2',
                    'Product Code': 'SP002',
                    'Category': 'Accessories',
                    'Price': 299.50,
                    'Description': 'Another sample product description',
                    'Specifications': 'More sample specifications',
                    'Units': 10
                }
            ];

            // Create workbook and worksheet
            const workbook = XLSX.utils.book_new();
            const worksheet = XLSX.utils.json_to_sheet(sampleData);

            // Set column widths
            const colWidths = [
                { width: 20 }, // Product Name
                { width: 15 }, // Product Code
                { width: 15 }, // Category
                { width: 12 }, // Price
                { width: 30 }, // Description
                { width: 30 }, // Specifications
                { width: 10 }  // Units
            ];
            worksheet['!cols'] = colWidths;

            // Add worksheet to workbook
            XLSX.utils.book_append_sheet(workbook, worksheet, 'Products');

            // Generate buffer
            console.log('Generating Excel buffer...');
            const buffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
            console.log('Buffer generated, size:', buffer.length);

            // Set headers for download
            res.setHeader('Content-Disposition', 'attachment; filename=product_sample_template.xlsx');
            res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            
            console.log('Sending Excel file...');
            res.send(buffer);

        } catch (e) {
            console.error('Download Excel sample error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Failed to generate Excel sample' }
            });
        }
    },

    // Bulk upload products from Excel
    bulkUploadProducts: async (req, res) => {
        console.log('Bulk upload request received...');
        try {
            const XLSX = require('xlsx');
            const { pool } = require('../config/dbConfig');

            // Check if file was uploaded using express-fileupload
            if (!req.files || !req.files['excel-file']) {
                console.log('No file uploaded');
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'No file uploaded' }
                });
            }

            const uploadedFile = req.files['excel-file'];
            console.log('File received:', uploadedFile.name, 'Size:', uploadedFile.size);

            // Validate file type
            const allowedTypes = [
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'application/vnd.ms-excel'
            ];
            
            if (!allowedTypes.includes(uploadedFile.mimetype)) {
                console.log('Invalid file type:', uploadedFile.mimetype);
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Invalid file type. Only Excel files (.xlsx, .xls) are allowed.' }
                });
            }

            // Validate file size (5MB)
            if (uploadedFile.size > 5 * 1024 * 1024) {
                console.log('File too large:', uploadedFile.size);
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'File size must be less than 5MB' }
                });
            }

            try {
                console.log('Parsing Excel file...');
                // Parse Excel file using express-fileupload buffer
                const workbook = XLSX.read(uploadedFile.data, { type: 'buffer' });
                    const sheetName = workbook.SheetNames[0];
                    const worksheet = workbook.Sheets[sheetName];
                    const jsonData = XLSX.utils.sheet_to_json(worksheet);

                    if (jsonData.length === 0) {
                        return res.status(400).json({
                            message: 'error',
                            status: 400,
                            data: { message: 'Excel file is empty or has no valid data' }
                        });
                    }

                    // Validation and processing
                    const validProducts = [];
                    const errors = [];
                    const duplicates = new Set();
                    let totalRows = jsonData.length;

                    // Check for existing products to avoid duplicates
                    const existingProducts = await pool.query(`
                        SELECT name, product_code FROM product WHERE active = TRUE
                    `);
                    const existingNames = new Set(existingProducts.rows.map(p => p.name.toLowerCase()));
                    const existingCodes = new Set(existingProducts.rows.map(p => p.product_code.toLowerCase()));

                    for (let i = 0; i < jsonData.length; i++) {
                        const row = jsonData[i];
                        const rowNum = i + 2; // Excel row number (accounting for header)
                        let hasError = false;

                        // Validate required fields
                        if (!row['Product Name'] || row['Product Name'].toString().trim() === '') {
                            errors.push({ row: rowNum, message: 'Product Name is required' });
                            hasError = true;
                        }

                        if (!row['Product Code'] || row['Product Code'].toString().trim() === '') {
                            errors.push({ row: rowNum, message: 'Product Code is required' });
                            hasError = true;
                        }

                        if (!row['Price'] || isNaN(parseFloat(row['Price'])) || parseFloat(row['Price']) <= 0) {
                            errors.push({ row: rowNum, message: 'Valid Price is required' });
                            hasError = true;
                        }

                        if (!row['Units'] || isNaN(parseInt(row['Units'])) || parseInt(row['Units']) <= 0) {
                            errors.push({ row: rowNum, message: 'Valid Units quantity is required' });
                            hasError = true;
                        }

                        if (hasError) continue;

                        // Check for duplicates within file
                        const productName = row['Product Name'].toString().trim();
                        const productCode = row['Product Code'].toString().trim();
                        const nameKey = productName.toLowerCase();
                        const codeKey = productCode.toLowerCase();

                        if (existingNames.has(nameKey) || existingCodes.has(codeKey)) {
                            errors.push({ row: rowNum, message: 'Product Name or Code already exists in database' });
                            duplicates.add(nameKey);
                            continue;
                        }

                        if (duplicates.has(nameKey)) {
                            errors.push({ row: rowNum, message: 'Duplicate Product Name in file' });
                            continue;
                        }

                        duplicates.add(nameKey);

                        // Add to valid products
                        validProducts.push({
                            name: productName,
                            product_code: productCode,
                            category: row['Category'] ? row['Category'].toString().trim() : null,
                            price: parseFloat(row['Price']),
                            description: row['Description'] ? row['Description'].toString().trim() : null,
                            specifications: row['Specifications'] ? row['Specifications'].toString().trim() : null,
                            units: parseInt(row['Units'])
                        });
                    }

                    // Insert valid products using the insert_products function
                    let insertedCount = 0;
                    if (validProducts.length > 0) {
                        console.log('Inserting', validProducts.length, 'valid products...');
                        
                        // Convert products to the format expected by insert_products function
                        const productsJsonb = validProducts.map(product => ({
                            name: product.name,
                            productCode: product.product_code,
                            description: product.description,
                            category: product.category,
                            price: product.price,
                            specifications: product.specifications,
                            unit: product.units
                        }));

                        try {
                            // Call the insert_products function with JSONB array
                            const result = await pool.query(`
                                SELECT insert_products($1, $2)
                            `, [
                                JSON.stringify(productsJsonb), // Convert to JSON string
                                1 // created_by
                            ]);

                            console.log('Insert result:', result.rows[0]);
                            
                            if (result.rows[0].insert_products.status === 'success') {
                                insertedCount = validProducts.length;
                                console.log('Successfully inserted', insertedCount, 'products');
                            } else {
                                console.error('Insert failed:', result.rows[0].insert_products.message);
                                throw new Error(result.rows[0].insert_products.message);
                            }

                        } catch (insertError) {
                            console.error('Insert error:', insertError);
                            throw insertError;
                        }
                    }

                    // Return results
                    res.status(200).json({
                        message: 'success',
                        status: 200,
                        data: {
                            summary: {
                                total: totalRows,
                                valid: insertedCount,
                                duplicates: duplicates.size - insertedCount,
                                errors: errors.length
                            },
                            errors: errors
                        }
                    });

            } catch (parseError) {
                console.error('Excel parsing error:', parseError);
                res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Failed to parse Excel file. Please check the file format.' }
                });
            }

        } catch (e) {
            console.error('Bulk upload error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong during bulk upload' }
            });
        }
    },

    // Get inventory units for a product
    getProductInventoryUnits: async (req, res) => {
        try {
            const { productId } = req.params;
            const { pool } = require('../config/dbConfig');

            const result = await pool.query(`
                SELECT 
                    iu.id,
                    CONCAT('P', iu.product_lid, '-', LPAD(iu.id::text, 6, '0')) as unit_serial,
                    ist.name as status,
                    icm.created_at as mapped_at,
                    iu.created_at,
                    c.name as company_name,
                    c.company_code,
                    c.company_type,
                    icm.id as mapping_id
                FROM inventory_unit iu
                JOIN inventory_status ist ON ist.id = iu.status_lid
                LEFT JOIN company c ON c.id = iu.current_company_lid
                LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                WHERE iu.product_lid = $1 AND iu.active = TRUE
                ORDER BY iu.created_at DESC
            `, [productId]);

            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows
            });
        } catch (e) {
            console.error('Get inventory units error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: { message: 'Something went wrong!' }
            });
        }
    },

    // Add inventory units to a product
    addInventoryUnits: async (req, res) => {
        try {
            const { productId } = req.params;
            const { unitsToAdd } = req.body;
            const { pool } = require('../config/dbConfig');

            if (!unitsToAdd || unitsToAdd <= 0 || unitsToAdd > 100) {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Invalid number of units. Must be between 1 and 100.' }
                });
            }

            // Check if product exists
            const productCheck = await pool.query(`
                SELECT id, name FROM product WHERE id = $1 AND active = TRUE
            `, [productId]);

            if (productCheck.rows.length === 0) {
                return res.status(404).json({
                    message: 'error',
                    status: 404,
                    data: { message: 'Product not found' }
                });
            }

            const productName = productCheck.rows[0].name;

            // Get the AVAILABLE status ID and SELF company info
            const statusResult = await pool.query(`
                SELECT id FROM inventory_status WHERE name = 'AVAILABLE'
            `);
            
            if (statusResult.rows.length === 0) {
                return res.status(500).json({
                    message: 'error',
                    status: 500,
                    data: { message: 'AVAILABLE status not found in system' }
                });
            }

            // Get SELF company and NEW label for auto-mapping
            const selfCompanyResult = await pool.query(`
                SELECT id FROM company WHERE company_type = 'SELF' OR company_code = 'SELF' LIMIT 1
            `);
            
            const newLabelResult = await pool.query(`
                SELECT id FROM mapping_label WHERE name = 'NEW' LIMIT 1
            `);

            if (selfCompanyResult.rows.length === 0) {
                return res.status(500).json({
                    message: 'error',
                    status: 500,
                    data: { message: 'SELF company not found in system' }
                });
            }

            if (newLabelResult.rows.length === 0) {
                return res.status(500).json({
                    message: 'error',
                    status: 500,
                    data: { message: 'NEW label not found in system' }
                });
            }

            const availableStatusId = statusResult.rows[0].id;
            const selfCompanyId = selfCompanyResult.rows[0].id;
            const newLabelId = newLabelResult.rows[0].id;

            // Begin transaction
            await pool.query('BEGIN');

            try {
                // Insert new inventory units one by one and map them immediately
                const insertedUnitIds = [];
                
                for (let i = 1; i <= unitsToAdd; i++) {
                    // Insert inventory unit
                    const unitResult = await pool.query(`
                        INSERT INTO inventory_unit (product_lid, status_lid, current_company_lid, created_by)
                        VALUES ($1, $2, $3, $4)
                        RETURNING id
                    `, [productId, availableStatusId, selfCompanyId, 1]);
                    
                    const unitId = unitResult.rows[0].id;
                    insertedUnitIds.push(unitId);
                    
                    // Immediately create the mapping for this unit
                    await pool.query(`
                        INSERT INTO inventory_company_mapping (inventory_unit_lid, company_lid, label_lid, notes, created_by)
                        VALUES ($1, $2, $3, $4, $5)
                    `, [unitId, selfCompanyId, newLabelId, 'Auto-map on inventory add', 1]);
                }

                await pool.query('COMMIT');

                res.status(200).json({
                    message: 'success',
                    status: 200,
                    data: { 
                        message: `Successfully added ${insertedUnitIds.length} inventory units to "${productName}" and mapped to SELF company` 
                    }
                });

            } catch (error) {
                await pool.query('ROLLBACK');
                console.error('Transaction error in addInventoryUnits:', error);
                throw error;
            }

        } catch (e) {
            console.error('Add inventory units error:', e);
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
            const { unitId } = req.params;
            const { pool } = require('../config/dbConfig');

            // Get inventory unit details with company information
            const unitResult = await pool.query(`
                SELECT 
                    iu.id,
                    ist.name as status,
                    CONCAT('P', iu.product_lid, '-', LPAD(iu.id::text, 6, '0')) as unit_serial,
                    p.name as product_name,
                    c.company_type,
                    c.name as company_name,
                    icm.id as mapping_id
                FROM inventory_unit iu
                JOIN product p ON p.id = iu.product_lid
                JOIN inventory_status ist ON ist.id = iu.status_lid
                LEFT JOIN company c ON c.id = iu.current_company_lid
                LEFT JOIN inventory_company_mapping icm ON icm.inventory_unit_lid = iu.id AND icm.active = TRUE
                WHERE iu.id = $1 AND iu.active = TRUE
            `, [unitId]);

            if (unitResult.rows.length === 0) {
                return res.status(404).json({
                    message: 'error',
                    status: 404,
                    data: { message: 'Inventory unit not found' }
                });
            }

            const unit = unitResult.rows[0];

            // Check if unit is available
            if (unit.status !== 'AVAILABLE') {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Cannot delete inventory unit that is not available' }
                });
            }

            // Check if it's mapped to external company (not SELF)
            if (unit.company_type && unit.company_type !== 'SELF') {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'Cannot delete inventory unit that is mapped to external company' }
                });
            }

            // Begin transaction
            await pool.query('BEGIN');

            try {
                // Deactivate any active mappings first
                if (unit.mapping_id) {
                    await pool.query(`
                        UPDATE inventory_company_mapping 
                        SET active = FALSE, 
                            updated_at = CURRENT_TIMESTAMP,
                            updated_by = $1
                        WHERE id = $2
                    `, [1, unit.mapping_id]);
                }

                // Deactivate the inventory unit
                await pool.query(`
                    UPDATE inventory_unit 
                    SET active = FALSE, 
                        updated_at = CURRENT_TIMESTAMP,
                        updated_by = $1
                    WHERE id = $2
                `, [1, unitId]);

                await pool.query('COMMIT');

                res.status(200).json({
                    message: 'success',
                    status: 200,
                    data: { 
                        message: `Inventory unit ${unit.unit_serial} for "${unit.product_name}" deleted successfully!` 
                    }
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