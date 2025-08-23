const currency = require("../models/admin/masters/currency");
const Country = require('../models/admin/masters/countryMaster');


module.exports = {

    currencyMaster: async (req, res) => {
        let { _user } = {
            ...req.body,
        };

        if (req.method == "GET") {
            const countries = await Country.findAllActive();
            const currencies = await currency.getAllCurrency();
            console.log('countries>>> ', countries.rows);
            console.log("currency:::::>>", currencies);
            res.render("admin/master/currency-type", {
                currencies: currencies ? currencies.rows : [],
                countries: countries ? countries.rows : []
            });
        }
    },

    getAll: async (req, res) => {
        try {
            let { _user } = {
                ...req.body,
            };

            const currencies = await currency.getAllCurrency();
            console.log("currency:::::>>", currencies);
            res.status(200).json({
                status: 'success',
                message: 'Currencies fetch successfully.',
                currencies: currencies.rows
            })
        } catch (e) {
            console.log(e);
            res.status(500).json({
                status: 'failed',
                message: 'Error while fetching currencies!',
                currencies: []
            })
        }
    },

    insert: async (req, res) => {
        try {
            let { _user, currencyList } = {
                ...req.body
            };
            console.log(currencyList);
            const result = await currency.insert(currencyList);

            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].insert_currencies
            });
        } catch (e) {
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    updateCurrency: async (req, res) => {
        let { _user, currencyData } = {
            ...req.body,
        };

        console.log('users', req.body);

        if (req.method == "POST") {
            const data = await currency.updateCurrency(currencyData);
            console.log('data>>> ', data.rows);
            res.status(200).json({
                message: 'Success',
                status: 200
            });
        }
    },

    deleteCurrency: async (req, res) => {
        let { _user, currencyData } = {
            ...req.body,
        };

        console.log('users', req.body);

        if (req.method == "POST") {
            const data = await currency.deleteCurrency(currencyData);
            console.log('data>>> ', data.rows);
            res.status(200).json({
                message: 'Success',
                status: 200
            });
        }
    }

}