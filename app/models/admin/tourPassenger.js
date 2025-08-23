const { pool } = require("../../config/dbConfig");


module.exports = {
    getAll: () => {
        const statement = {
            text: `SELECT id, tour_lid, pax_type_lid, no_of_passengers, is_payable, payment_percentage, payment_amount, occupancy_preference FROM tour_passengers WHERE active = true;`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    getAllByTourId: (tour_lid) => {
        const statement = {
            text: `SELECT tp.id, tp.tour_lid, tp.pax_type_lid, pt.name AS pax_type, tp.no_of_passengers, tp.is_payable, tp.payment_percentage, tp.payment_amount, tp.occupancy_preference FROM tour_passengers tp
            INNER JOIN passenger_type pt ON pt.id = tp.pax_type_lid
            WHERE tp.tour_lid = $1 AND tp.active = true;`,
            values: [tour_lid]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    add: (data) => {
        const statement = {
            text: `INSERT INTO tour_passengers(tour_lid, pax_type_lid, no_of_passengers, is_payable, payment_percentage, payment_amount, occupancy_preference, created_by) VALUES($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id;`,
            values: [data.TOUR_LID, data.paxTypeLid, data.paxCount, data.isPayable, data.payablePercentage, data.payableAmount, data.occupancyPreference, 1]
        };
        return pool.query(statement);
    },

    update: (tourPaxDetails) => {
        const statement = {
            text: `UPDATE tour_passengers SET no_of_passengers = $1, is_payable = $2, payment_percentage = $3, payment_amount = $4, occupancy_preference = $5, updated_by = $6
            WHERE id = $7;`,
            values: [tourPaxDetails.paxCount, tourPaxDetails.isPayable, tourPaxDetails.payablePercentage, tourPaxDetails.payableAmount, tourPaxDetails.occupancyPreference, 1, tourPaxDetails.TOUR_PAX_LID]
        };
        return pool.query(statement);
    },

    checkIfExist: (tour_lid, pax_type_lid) => {
        const statement = {
            text: `SELECT COUNT(*) FROM tour_passengers WHERE tour_lid = $1 AND pax_type_lid = $2 AND active = true;`,
            values: [tour_lid, pax_type_lid]
        };
        return pool.query(statement);
    },

    delete: (tourPaxLId) => {
        const statement = {
            text: `UPDATE tour_passengers SET active = false, updated_by = $1
            WHERE id = $2;`,
            values: [1, tourPaxLId]
        };
        return pool.query(statement);
    },
}

