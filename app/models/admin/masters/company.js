const { pool } = require("../../../config/dbConfig");

module.exports = {
    getAllCompanies: () => {
        const statement = {
            text: `SELECT c.id, c.name, c.company_code, c.email, c.phone, c.address_line1, c.address_line2, 
                   c.postal_code, c.registration_number, c.tax_number, c.company_type_lid, 
                   ctype.name AS company_type_name, c.website,
                   c.country_lid, co.name AS country_name, c.state_lid, s.name AS state_name, 
                   c.city_lid, ct.name AS city_name,
                   c.created_at, c.updated_at, c.created_by, c.updated_by, c.active 
                   FROM company c
                   LEFT JOIN country co ON co.id = c.country_lid AND co.active = TRUE
                   LEFT JOIN state s ON s.id = c.state_lid AND s.active = TRUE
                   LEFT JOIN city ct ON ct.id = c.city_lid AND ct.active = TRUE
                   LEFT JOIN company_type ctype ON ctype.id = c.company_type_lid AND ctype.active = TRUE
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
            text: `SELECT update_company($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16);`,
            values: [
                data.companyLid,
                data.companyName,
                data.companyCode,
                data.email,
                data.phone,
                data.addressLine1,
                data.addressLine2,
                data.countryLid,
                data.stateLid,
                data.cityLid,
                data.postalCode,
                data.registrationNumber,
                data.taxNumber,
                data.companyTypeLid,
                data.website,
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
        const statement = {
            text: `SELECT add_new_companies($1, $2);`,
            values: [JSON.stringify(data), userId]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    findById: (companyId) => {
        const statement = {
            text: `SELECT c.*, co.name AS country_name, s.name AS state_name, ct.name AS city_name
                   FROM company c
                   LEFT JOIN country co ON co.id = c.country_lid
                   LEFT JOIN state s ON s.id = c.state_lid
                   LEFT JOIN city ct ON ct.id = c.city_lid
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
                SELECT c.id, c.name, c.company_code, c.company_type_lid, ct.name AS company_type_name
                FROM company c
                LEFT JOIN company_type ct ON ct.id = c.company_type_lid AND ct.active = TRUE
                WHERE c.active = TRUE
                ORDER BY c.name;
            `,
            values: []
        };
        return pool.query(statement);
    }

}; 