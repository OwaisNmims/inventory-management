const { pool } = require("../../../config/dbConfig");


module.exports = {

    insert: (data) => {
        const statement = {
            text: `SELECT insert_currency_rates($1);`,
            values: [JSON.stringify(data)]
        };
        return pool.query(statement);
    },
}

