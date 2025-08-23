const { pool } = require("../../../config/dbConfig");


module.exports = {
    
    findAll: () => {
        const statement = {
            text: `select id, firstname, lastname, email  from users where active = true;`,
            values: []
        };
        return pool.query(statement);
    },

    insert: (data) => {
        const statement = {
            text: `SELECT insert_cities($1, $2);`,
            values: [JSON.stringify(data), 1]
        };
        return pool.query(statement);
    },

    updateCity: (data) => {
        const statement = {
            text: `SELECT update_city($1, $2, $3);`,
            values: [data.cityLid, data.cityName, data.postalCode]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    deleteById: (id) => {
        const statement = {
            text: `UPDATE users SET active = false WHERE id = $1;`,
            values: [id]
        };
        return pool.query(statement);
    },

    

}

