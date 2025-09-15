const { pool } = require("../../../config/dbConfig");

module.exports = {
    getAllCompanies: () => {
        const statement = {
            text: `SELECT c.id, c.name, c.company_code, c.company_type,
                   c.company_type as company_type_name,
                   c.created_at, c.updated_at, c.created_by, c.updated_by, c.active 
                   FROM company c
                   WHERE c.active = TRUE
                   ORDER BY c.name;`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
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
                   SET name = $2, company_code = $3, company_type = $4, 
                       updated_at = CURRENT_TIMESTAMP, updated_by = $5
                   WHERE id = $1 AND active = TRUE
                   RETURNING *;`,
            values: [
                data.companyLid,
                data.companyName || data.name,
                data.companyCode || data.company_code,
                data.companyType || data.company_type || 'VENDOR',
                data.updatedBy || 1
            ]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    deleteCompany: (data) => {
        const statement = {
            text: `UPDATE company SET active = false, updated_at = CURRENT_TIMESTAMP, updated_by = $2 WHERE id = $1;`,
            values: [data.companyLid, 1]
        };
        console.log('statement::::::::::::::::::::', statement);
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
            values: [firstCompany.name, firstCompany.company_code, firstCompany.company_type || 'VENDOR', userId]
        };
        console.log('statement::::::::::::::::::::', statement);
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