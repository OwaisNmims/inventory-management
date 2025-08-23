const { pool } = require("../../../config/dbConfig");

module.exports = {
    getAllLabels: () => {
        const statement = {
            text: `SELECT id, name, description, created_at, updated_at, created_by, updated_by, active 
                   FROM label
                   WHERE active = TRUE
                   ORDER BY name;`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    findAllActive: () => {
        const statement = {
            text: `SELECT id, name, description FROM label WHERE active = TRUE ORDER BY name;`,
            values: []
        };
        return pool.query(statement);
    },

    findById: (labelId) => {
        const statement = {
            text: `SELECT * FROM label WHERE id = $1 AND active = TRUE;`,
            values: [labelId]
        };
        return pool.query(statement);
    }

}; 