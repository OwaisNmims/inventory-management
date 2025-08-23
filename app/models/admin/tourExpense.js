const { pool } = require("../../config/dbConfig");


module.exports = {
    getAll: () => {
        const statement = {
            text: `SELECT id, tour_lid, expense_lid, pax_lid, pax_count, currency_lid, unit_price, nightly_recurring, daily_recurring, total_price, created_at, updated_at, created_by, updated_by FROM tour_expenses WHERE active = true;`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    getAllByTourId: (tour_lid) => {
        const statement = {
            // text: `SELECT te.id, te.tour_lid, te.expense_lid, e.name AS expense_type, te.pax_lid, pt.name AS pax_type, te.pax_count, te.currency_lid, ct.code AS currency, te.unit_price, te.nightly_recurring, te.daily_recurring, te.total_price, te.created_at, te.updated_at, te.created_by, te.updated_by FROM tour_expenses te
            // INNER JOIN expenses e ON e.id = te.expense_lid
            // INNER JOIN passenger_type pt ON pt.id = te.pax_lid
            // INNER JOIN currency_type ct ON ct.id = te.currency_lid
            // WHERE te.active = true AND te.tour_lid = $1 ORDER BY te.created_at::TIMESTAMP ASC;`,
            text:`SELECT te.id, te.tour_lid, te.expense_lid, e.name AS expense_type, te.pax_lid, pt.name AS pax_type, 
            te.pax_count, te.currency_lid, ct.code AS currency, te.unit_price, te.nightly_recurring, 
            te.daily_recurring, te.total_price, te.created_at, te.updated_at, te.created_by, te.updated_by, 
            round( CAST(float8 ((SELECT *
            FROM currency_calculator(ct.code, 'INR', te.total_price))) as numeric), 2) as total_price_inr
            FROM tour_expenses te
            INNER JOIN expenses e ON e.id = te.expense_lid
            INNER JOIN passenger_type pt ON pt.id = te.pax_lid
            INNER JOIN currency_type ct ON ct.id = te.currency_lid
            WHERE te.active = true AND te.tour_lid = $1 ORDER BY te.created_at::TIMESTAMP ASC;`,
            values: [tour_lid]
        };
        console.log('statement::::::::::::::::::::', statement);
        return pool.query(statement);
    },

    add: (data) => {
        const statement = {
            text: `INSERT INTO tour_expenses(tour_lid, expense_lid, pax_lid, pax_count, currency_lid, unit_price, nightly_recurring, daily_recurring, total_price, created_by) VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id;`,
            values: [data.TOUR_LID, data.expenseLid, data.paxLid, data.paxCount, data.currencyLid, data.unitPrice, data.nightlyRecurring, data.dailyRecurring, data.totalPrice, 1]
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

    delete: (tourPaxLid) => {
        const statement = {
            text: `UPDATE tour_expenses SET active = false, updated_by = $1
            WHERE id = $2;`,
            values: [1, tourPaxLid]
        };
        return pool.query(statement);
    },

    totalTourPrice: (tourPaxLid) => {
        const statement = {
            text: `select sum(total_price) as total_price from tour_expenses where tour_lid = $1 and active = true;`,
            values: [tourPaxLid]
        };
        return pool.query(statement);
    },


    totalTourPriceInr: (tourId) => {
        const statement = {
            text: `SELECT SUM(round(CAST(float8 ((SELECT *
                FROM currency_calculator(ct.code, 'INR', te.total_price))) as numeric), 2))
                as total_price_inr
                FROM tour_expenses te
                INNER JOIN expenses e ON e.id = te.expense_lid
                INNER JOIN passenger_type pt ON pt.id = te.pax_lid
                INNER JOIN currency_type ct ON ct.id = te.currency_lid
                WHERE te.active = true AND te.tour_lid = $1`,
            values: [tourId]
        };
        return pool.query(statement);
    },

    quoteForPax: (tourId, tourPriceInr, userId) => {
        const statement = {
            text: `select tour_quotations($1, $2, $3)`,
            values: [tourId, tourPriceInr, userId]
        };
        console.log('statement::::::::::::::::', statement)
        return pool.query(statement);
    },

    tourCurrencyRates: (tourId) => {
        const statement = {
            text: `SELECT DISTINCT ct.name, ct.symbol, ct.code , 
                    (SELECT round(CAST(float8 ((SELECT *
                    FROM currency_calculator(ct.code, 'INR', 1))) AS numeric), 2)) AS price,
                    round((SELECT price FROM currency_rates WHERE currency_code = 'INR' AND active = true)::numeric/
                    (SELECT price FROM currency_rates WHERE currency_code = ct.code AND active = true), 2)::float8 AS actual_price 
                    FROM tour_expenses te 
                    INNER JOIN currency_type ct ON ct.id = te.currency_lid
                    WHERE te.tour_lid = $1 AND te.active = true AND ct.code <> 'INR' AND ct.active = true;`,
            values: [tourId]
        };
        console.log('statement::::::::::::::::', statement)
        return pool.query(statement);
    }
}

