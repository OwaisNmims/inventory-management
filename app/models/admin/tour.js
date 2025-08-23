const {
    pool
} = require("../../config/dbConfig");

module.exports = class Tour {

    static findAllActive() {
        let statement;
        statement = {
            text: `SELECT id, name, duration_nights, duration_days, TO_CHAR(created_at, 'DD-MM-YYYY HH24:MI:SS') AS created_at, TO_CHAR(updated_at, 'DD-MM-YYYY HH24:MI:SS') AS updated_at FROM tour WHERE active = true ORDER BY created_at::TIMESTAMP DESC;`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement)
        return pool.query(statement)
    }

    static addNewTour(tour_name, tour_nights) {
        const statement = {
            text: `INSERT INTO tour(name, duration_days, duration_nights, created_by) VALUES ($1, $2, $3, $4) RETURNING id, name, duration_days, duration_nights;`,
            values: [tour_name, Number(tour_nights) + 1, tour_nights, 1]
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }

    static update(tour_name, tour_nights, tour_lid) {
        const statement = {
            text: `UPDATE tour SET name = $1, duration_days = $2, duration_nights = $3,  updated_by = $4, updated_at = CURRENT_TIMESTAMP WHERE id = $5 RETURNING id, name, duration_days, duration_nights;`,
            values: [tour_name, Number(tour_nights) + 1, tour_nights, 1, tour_lid]
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }

    static getTour(tourId) {
        let statement = {
            text: `SELECT id, name, duration_nights, duration_days, created_at, updated_at FROM tour WHERE id = $1 AND active = true`,
            values: [tourId]
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }
    static getPassengers() {

        let statement;
        statement = {
            text: `select id, name from passenger_type where active = true`,
            values: []
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }


    static delete(id) {
        const statement = {
            text: `UPDATE tour SET active = false,  updated_at = CURRENT_TIMESTAMP WHERE id = $1`,
            values: [id]
        }
        return pool.query(statement)
    }
};