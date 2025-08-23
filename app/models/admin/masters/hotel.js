const { pool } = require("../../../config/dbConfig");


module.exports = {
    getAll: () => {
        const statement = {
            text: `SELECT
            h.name,
            ARRAY_AGG(rt.name) AS room_types,
            c.name AS city_name,
            s.name AS state_name,
            co.name AS country_name
        FROM hotels h 
        INNER JOIN country co ON co.id = h.country_lid
        INNER JOIN state s ON s.id = h.state_lid
        INNER JOIN city c ON c.id = h.city_lid
        INNER JOIN hotel_room_types hrt ON hrt.hotel_lid = h.id
        INNER JOIN room_types rt ON rt.id = hrt.room_type_lid
        WHERE h.active = true AND c.active = true AND s.active = true AND co.active = true
        GROUP BY h.name, c.name, s.name, co.name;
        `,
            values: []
        };
        return pool.query(statement);
    },

    add: (data) => {
        const statement = {
            text: `SELECT insert_hotel($1, $2);`,
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

