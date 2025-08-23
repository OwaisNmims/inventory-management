const { pool } = require("../../config/dbConfig");


module.exports = {

    getAllByTourId: (tour_lid) => {
        const statement = {
            text: `SELECT tt.id as id, t.id as tax_lid, t.name, tt.tax_percentage 
            FROM tour_taxes tt 
            join tax t on t.id = tt.tax_lid 
            WHERE tt.tour_lid = $1 and t.active = true and tt.active = true;`,
            values: [tour_lid]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    add: (data, userId) => {
        const statement = {
            text: `INSERT INTO tour_taxes(tour_lid, tax_lid, tax_percentage, created_by) VALUES($1, $2, $3, $4) RETURNING id;`,
            values: [data.tour_lid, data.tax_lid, data.tax_percentage,  userId]
        };
        return pool.query(statement);
    },

    update: (data) => {
        const statement = {
            text: `UPDATE tour_expenses SET expense_lid = $1, pax_lid = $2, pax_count = $3, currency_lid = $4, unit_price = $5, nightly_recurring = $6, daily_recurring = $7, total_price = $8, updated_by = $9 WHERE id = $10;`,
            values: [data.expenseLid, data.paxLid, data.paxCount, data.currencyLid, data.unitPrice, data.nightlyRecurring, data.dailyRecurring, data.totalPrice, 1, data.TOUR_EXPENSE_LID]
        };
        return pool.query(statement);
    },

    delete: (updated_by, id) => {
        const statement = {
            text: `UPDATE tour_taxes SET active = false, updated_by = $1 WHERE id = $2;`,
            values: [updated_by, Number(id)]
        };
        console.log('statement::::::::', statement)
        return pool.query(statement);
    },

    totalTourPrice: (tourPaxLid) => {
        const statement = {
            text: `select sum(total_price) as total_price from tour_expenses where tour_lid = $1 and active = true;`,
            values: [tourPaxLid]
        };
        return pool.query(statement);
    },
}

