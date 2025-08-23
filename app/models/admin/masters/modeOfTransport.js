const { pool } = require("../../../config/dbConfig");

module.exports = {

    getAllModes: () => {
        const statement = {
            text: `SELECT id, name
            FROM mode_of_transport 
            WHERE active = TRUE;`,
            values: []
        };

        return pool.query(statement);
    },

    insert: (data) => {
        const statement = {
            text: `SELECT insert_mode_of_transport($1, $2);`,
            values: [JSON.stringify(data), 1]
        };

        return pool.query(statement);
    },

    
    update: (data) => {
        const statement = {
            text: `SELECT update_mode_of_transport($1, $2);`,
            values: [data.transportModeLid, data.newModeName]
        };

        return pool.query(statement);
    },

    delete: (data) => {
        const statement = {
            text: `UPDATE mode_of_transport SET active = false WHERE id = $1;`,
            values: [data.transportModeLid]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },
    
}