const { pool } = require("../../../config/dbConfig");


module.exports = {
    getAllCities: () => {
        const statement = {
            text: `SELECT c.id, c.name, c.postal_code, c.country_lid, co.name AS country_name, c.state_lid, s.name AS state_name, c.created_at, c.updated_at, c.created_by, c.updated_by, c.active 
            FROM city c
            INNER JOIN state s ON s.id = c.state_lid
            INNER JOIN country co ON co.id = c.country_lid
            WHERE c.active = TRUE AND s.active = TRUE AND co.active = TRUE;`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
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

    deleteCity: (data) => {
        const statement = {
            text: `UPDATE city SET active = false WHERE id = $1;`,
            values: [data.cityLid]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    

}

