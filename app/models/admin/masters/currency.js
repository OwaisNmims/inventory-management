const { pool } = require("../../../config/dbConfig");

module.exports = {
   getAllCurrency: () => {
    const statement = {
        text: `SELECT id, name, symbol, symbol_native, code, updated_at, created_by, updated_by, active 
        FROM currency_type 
        WHERE active = true;`,
        values: []
    };
    console.log('statement::::::::::>>', statement);
    return pool.query(statement);
   },

   insert: (data) => {
    const statement = {
        text: `SELECT insert_currencies($1, $2);`,
        values: [JSON.stringify(data), 1]
    };
    return pool.query(statement)
   },

   updateCurrency: (data) => {
    const statement = {
        text: `UPDATE currency_type SET name = $1 WHERE id = $2 AND active = true;`,
        values: [data.currencyName, data.currencyLid]
    };
    console.log('statement::::::::::::::::::::', statement);
    return pool.query(statement);
    },

    deleteCurrency: (data) => {
    const statement = {
        text: `UPDATE currency_type SET active = false WHERE id = $1;`,
        values: [data.currencyLid]
    };
    console.log('statement::::::::::::::::::::', statement);
    return pool.query(statement);
    },
}