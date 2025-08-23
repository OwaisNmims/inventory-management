
const expenseMaster = require("../models/admin/masters/countryMaster")


module.exports = {
    addNewExpenses: function (req, res) {
        let {
            expenses
        } = {
            ...req.body,
            ...req.query,
            ...req.params
        }

        if (req.method == 'POST') {
            expenseMaster.addNewExpenses(expenses).then((data) => {
                console.log('data::::::::::::::::::>>>>>', data.rows)
                res.json(data.rows)
            }).catch((err) => {
                console.log('error found :::::::::::::', err)
            })
        }
    },

    editCountry: function (req, res) {
        let {
            countryName,
            countryId
        } = {
            ...req.body,
            ...req.query,
            ...req.params
        }

        if (req.method == 'POST') {
            countryMaster.editCountry(countryName, countryId).then((data) => {
                console.log('data::::::::::::::::::>>>>>', data.rows)
                res.json(data.rows)
            }).catch((err) => {
                console.log('error found :::::::::::::', err)
            })
        }
    },

    disableCountry: function (req, res) {
        let {
            countryId
        } = {
            ...req.body,
            ...req.query,
            ...req.params
        }

        if (req.method == 'POST') {
            countryMaster.diableCountry(countryId).then((data) => {
                console.log('data::::::::::::::::::>>>>>', data.rows)
                res.json(data.rows)
            }).catch((err) => {
                console.log('error found :::::::::::::', err)
            })
        }
    },
    searchCountry: function (req, res) {
        let {
            q
        } = {
            ...req.body,
            ...req.query,
            ...req.params
        }

        if (req.method == 'GET') {
            countryMaster.searchCountry(q).then((data) => {
                console.log('data::::::::::::::::::>>>>>', data.rows)

                res.json({
                    incomplete_results: false,
                    items: [{name: 'india'},{ name: 'pakistan'}],
                    total_count: 2
                })
            }).catch((err) => {
                console.log('error found :::::::::::::', err)
            })
        }
    },
}