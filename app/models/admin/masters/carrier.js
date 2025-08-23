
const { pool } = require("../../../config/dbConfig");

module.exports = {

    getAllCarriers: () => {
        const statement = {
            text: `SELECT c.id, c.name, m.name AS mode_of_transport, m.id AS mode_lid FROM carrier c
            INNER JOIN mode_of_transport m ON m.id = c.transport_mode_lid
            WHERE c.active = true AND m.active = true;`,
            values: []
        };
        return pool.query(statement);
    },

    insert: (data) => {
        const statement = {
            text: `SELECT insert_carriers($1, $2);`,
            values: [JSON.stringify(data), 1]
        };

        return pool.query(statement);
    },

    
    update: (data) => {
        const statement = {
            text: `SELECT update_carrier($1, $2);`,
            values: [data.carrierLid, data.newCarrierName]
        };

        return pool.query(statement);
    },

    delete: (data) => {
        const statement = {
            text: `UPDATE carrier SET active = false WHERE id = $1;`,
            values: [data.carrierLid]
        };
        return pool.query(statement);
    },
    
}