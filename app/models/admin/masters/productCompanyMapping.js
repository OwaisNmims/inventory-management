const { pool } = require("../../../config/dbConfig");

module.exports = {
    getAllMappings: () => {
        const statement = {
            text: `SELECT * FROM get_product_company_mappings();`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    createMapping: (productLid, companyLid, notes, createdBy) => {
        const statement = {
            text: `SELECT map_product_to_company($1, $2, $3, $4);`,
            values: [productLid, companyLid, notes, createdBy]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    updateMappingLabel: (mappingId, labelLid, updatedBy) => {
        const statement = {
            text: `SELECT update_product_mapping_label($1, $2, $3);`,
            values: [mappingId, labelLid, updatedBy]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    deleteMapping: (data) => {
        const statement = {
            text: `UPDATE product_company_mapping SET active = false, updated_at = CURRENT_TIMESTAMP, updated_by = $2 WHERE id = $1;`,
            values: [data.mappingId, 1]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    getMappingsByCompany: (companyLid) => {
        const statement = {
            text: `SELECT pcm.id as mapping_id, p.id as product_id, p.name as product_name, 
                   p.product_code, l.id as label_id, l.name as label_name, pcm.mapping_date, pcm.notes
                   FROM product_company_mapping pcm
                   JOIN product p ON p.id = pcm.product_lid AND p.active = true
                   JOIN label l ON l.id = pcm.label_lid AND l.active = true
                   WHERE pcm.company_lid = $1 AND pcm.active = true
                   ORDER BY pcm.mapping_date DESC;`,
            values: [companyLid]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    getMappingsByProduct: (productLid) => {
        const statement = {
            text: `SELECT pcm.id as mapping_id, c.id as company_id, c.name as company_name, 
                   c.company_code, l.id as label_id, l.name as label_name, pcm.mapping_date, pcm.notes
                   FROM product_company_mapping pcm
                   JOIN company c ON c.id = pcm.company_lid AND c.active = true
                   JOIN label l ON l.id = pcm.label_lid AND l.active = true
                   WHERE pcm.product_lid = $1 AND pcm.active = true
                   ORDER BY pcm.mapping_date DESC;`,
            values: [productLid]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    findById: (mappingId) => {
        const statement = {
            text: `SELECT pcm.*, p.name as product_name, p.product_code, c.name as company_name, 
                   c.company_code, l.name as label_name
                   FROM product_company_mapping pcm
                   JOIN product p ON p.id = pcm.product_lid
                   JOIN company c ON c.id = pcm.company_lid
                   JOIN label l ON l.id = pcm.label_lid
                   WHERE pcm.id = $1 AND pcm.active = TRUE;`,
            values: [mappingId]
        };
        return pool.query(statement);
    },

    bulkMapProducts: (productIds, companyLid, notes, createdBy) => {
        const statement = {
            text: `SELECT bulk_map_products_to_company($1, $2, $3, $4);`,
            values: [JSON.stringify(productIds), companyLid, notes, createdBy]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    getProductAvailability: (productId) => {
        const statement = {
            text: `SELECT get_product_availability($1);`,
            values: [productId]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    recordProductSales: (items, companyLid, notes, createdBy) => {
        const statement = {
            text: `SELECT record_product_sales($1, $2, $3, $4);`,
            values: [JSON.stringify(items), companyLid, notes, createdBy]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    getMappingReceipts: () => {
        const statement = {
            text: `SELECT * FROM get_mapping_receipts();`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    validateDataIntegrity: () => {
        const statement = {
            text: `SELECT * FROM validate_mapping_integrity();`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    transferProduct: (mappingId, newCompanyLid, notes, updatedBy) => {
        const statement = {
            text: `SELECT transfer_product_to_company($1, $2, $3, $4);`,
            values: [mappingId, newCompanyLid, notes, updatedBy]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    }

};