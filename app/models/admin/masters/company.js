const { pool } = require("../../../config/dbConfig");

module.exports = {
    getAllCompanies: () => {
        const statement = {
            text: `
                SELECT 
                    c.id,
                    c.name,
                    c.company_code,
                    c.email,
                    c.phone,
                    c.registration_number,
                    c.company_type,
                    c.company_type AS company_type_name,
                    c.state_lid,
                    s.name AS state_name,
                    c.city_lid,
                    ci.name AS city_name,
                    c.created_at,
                    c.updated_at,
                    c.created_by,
                    c.updated_by,
                    c.active
                FROM company c
                LEFT JOIN state s ON s.id = c.state_lid
                LEFT JOIN city ci ON ci.id = c.city_lid
                WHERE c.active = TRUE
                ORDER BY c.name;
            `,
            values: []
        };
        return pool.query(statement);
    },

    insert: (data) => {
        const statement = {
            text: `SELECT insert_companies($1, $2);`,
            values: [JSON.stringify(data), 1]
        };
        return pool.query(statement);
    },

    updateCompany: (data) => {
        const statement = {
            text: `UPDATE company 
                   SET name = $2, 
                       company_code = $3, 
                       company_type = $4,
                       email = $5,
                       phone = $6,
                       state_lid = $7,
                       city_lid = $8,
                       registration_number = $9,
                       updated_at = CURRENT_TIMESTAMP, 
                       updated_by = $10
                   WHERE id = $1 AND active = TRUE
                   RETURNING *;`,
            values: [
                data.companyLid,
                data.companyName || data.name,
                data.companyCode || data.company_code,
                data.companyType || data.company_type || 'VENDOR',
                data.email || null,
                data.phone || null,
                data.stateLid || null,
                data.cityLid || null,
                data.registrationNumber || data.registration_number || null,
                data.updatedBy || 1
            ]
        };
        return pool.query(statement);
    },

    // Validate if a company can be deleted
    validateCompanyDeletion: async (companyId) => {
        // Get company details
        const companyResult = await pool.query(
            `SELECT id, name, company_code 
             FROM company 
             WHERE id = $1 AND active = TRUE`,
            [companyId]
        );

        if (companyResult.rows.length === 0) {
            return {
                canDelete: false,
                reason: 'Company not found'
            };
        }

        const companyData = companyResult.rows[0];

        // Prevent deletion of SELF company
        if (companyData.company_code === 'SELF') {
            return {
                canDelete: false,
                reason: 'Cannot delete SELF company'
            };
        }

        // Check if any inventory is currently mapped to this company (active mappings)
        const mappedInventoryResult = await pool.query(
            `SELECT COUNT(*) as mapped_count
             FROM inventory_company_mapping icm
             JOIN inventory_unit iu ON iu.id = icm.inventory_unit_lid
             WHERE icm.company_lid = $1 
             AND icm.active = TRUE 
             AND iu.active = TRUE`,
            [companyId]
        );

        const mappedCount = parseInt(mappedInventoryResult.rows[0].mapped_count);

        if (mappedCount > 0) {
            return {
                canDelete: false,
                reason: `Cannot delete ${companyData.name}. There are ${mappedCount} inventory items currently mapped to this company. Please transfer or delete these items first.`
            };
        }

        // Check if any products have been sold by this company
        const salesResult = await pool.query(
            `SELECT COUNT(*) as sales_count, 
                    COALESCE(SUM(quantity), 0) as total_quantity
             FROM product_sale
             WHERE company_lid = $1`,
            [companyId]
        );

        const salesCount = parseInt(salesResult.rows[0].sales_count);
        const totalQuantity = parseInt(salesResult.rows[0].total_quantity);

        if (salesCount > 0 || totalQuantity !== 0) {
            return {
                canDelete: false,
                reason: `Cannot delete ${companyData.name}. This company has sales history (${salesCount} sale records with ${totalQuantity} units). Companies with sales history cannot be deleted for audit purposes.`
            };
        }

        // Check if there are any inactive/historical mappings (for audit trail)
        const historicalMappingsResult = await pool.query(
            `SELECT COUNT(*) as historical_count
             FROM inventory_company_mapping
             WHERE company_lid = $1`,
            [companyId]
        );

        const historicalCount = parseInt(historicalMappingsResult.rows[0].historical_count);

        if (historicalCount > 0) {
            return {
                canDelete: false,
                reason: `Cannot delete ${companyData.name}. This company has historical inventory mapping records. Companies with history cannot be deleted for audit purposes.`
            };
        }

        // All checks passed
        return {
            canDelete: true,
            reason: null,
            company: companyData
        };
    },

    deleteCompany: (data, userId = 1) => {
        const statement = {
            text: `UPDATE company SET active = false, updated_at = CURRENT_TIMESTAMP, updated_by = $2 WHERE id = $1;`,
            values: [data.companyLid, userId]
        };
        return pool.query(statement);
    },

    bulkInsert: (data, userId) => {
        // For now, just insert the first company from the array
        // This can be enhanced later if bulk insert is needed
        const firstCompany = Array.isArray(data) ? data[0] : data;
        const statement = {
            text: `INSERT INTO company (name, company_code, company_type, active, created_at, created_by)
                   VALUES ($1, $2, $3, true, CURRENT_TIMESTAMP, $4)
                   RETURNING *;`,
            values: [firstCompany.name, firstCompany.company_code, firstCompany.company_type || 'VENDOR', userId            ]
        };
        return pool.query(statement);
    },

    findById: (companyId) => {
        const statement = {
            text: `SELECT c.*
                   FROM company c
                   WHERE c.id = $1 AND c.active = TRUE;`,
            values: [companyId]
        };
        return pool.query(statement);
    },

    findAllActive: () => {
        const statement = {
            text: `SELECT id, name, company_code FROM company WHERE active = TRUE ORDER BY name;`,
            values: []
        };
        return pool.query(statement);
    },

    findAllActiveWithType: () => {
        const statement = {
            text: `
                SELECT c.id, c.name, c.company_code, c.company_type
                FROM company c
                WHERE c.active = TRUE
                ORDER BY c.name;
            `,
            values: []
        };
        return pool.query(statement);
    }

}; 