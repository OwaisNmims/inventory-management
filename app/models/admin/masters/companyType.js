const { pool } = require("../../../config/dbConfig");

module.exports = {
    getAllCompanyTypes: () => {
        const statement = {
            text: `SELECT id, name, description, created_at, updated_at, created_by, updated_by, active 
                   FROM company_type
                   WHERE active = TRUE
                   ORDER BY name;`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    insert: (data) => {
        const statement = {
            text: `INSERT INTO company_type (name, description, active, created_at, created_by)
                   VALUES ($1, $2, true, CURRENT_TIMESTAMP, $3)
                   RETURNING *;`,
            values: [data.name, data.description || '', 1]
        };
        return pool.query(statement);
    },

    updateCompanyType: (data) => {
        const statement = {
            text: `UPDATE company_type 
                   SET name = $2, description = $3, updated_at = CURRENT_TIMESTAMP, updated_by = $4
                   WHERE id = $1 AND active = TRUE
                   RETURNING *;`,
            values: [
                data.companyTypeLid,
                data.name,
                data.description,
                data.updatedBy || 1
            ]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    deleteCompanyType: (data) => {
        const statement = {
            text: `UPDATE company_type SET active = false, updated_at = CURRENT_TIMESTAMP, updated_by = $2 WHERE id = $1;`,
            values: [data.companyTypeLid, 1]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    bulkInsert: (data, userId) => {
        // For now, just insert the first company type from the array
        const firstType = Array.isArray(data) ? data[0] : data;
        const statement = {
            text: `INSERT INTO company_type (name, description, active, created_at, created_by)
                   VALUES ($1, $2, true, CURRENT_TIMESTAMP, $3)
                   RETURNING *;`,
            values: [firstType.name, firstType.description || '', userId]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    findById: (companyTypeId) => {
        const statement = {
            text: `SELECT * FROM company_type WHERE id = $1 AND active = TRUE;`,
            values: [companyTypeId]
        };
        return pool.query(statement);
    },

    findAllActive: () => {
        const statement = {
            text: `SELECT id, name, description FROM company_type WHERE active = TRUE ORDER BY name;`,
            values: []
        };
        return pool.query(statement);
    }

}; 