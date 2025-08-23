const { pool } = require("../../../config/dbConfig");


module.exports = {
    getAll: () => {
        const statement = {
            text: `SELECT id, name FROM passenger_type WHERE active = true;`,
            values: []
        };
        return pool.query(statement);
    },

    add: (data) => {
        const statement = {
            text: `SELECT insert_pax_type($1, $2);`,
            values: [JSON.stringify(data), 1]
        };
        return pool.query(statement);
    },

    update: (data) => {
        const statement = {
            text: `UPDATE passenger_type set name = $1, updated_by = $2, updated_at = now() where id = $3; `,
            values: [data.itemName, 1, data.itemLid]
        }
        return pool.query(statement)
    },

    delete: (data) => {
        const statement = {
            text: `UPDATE passenger_type SET active = false, updated_by = $1 WHERE id = $2; `,
            values: [1, data.itemLid]
        }
        return pool.query(statement)
    },

    

}

