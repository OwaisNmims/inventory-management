const countryMaster = require("../models/admin/masters/countryMaster")


module.exports = {
    addNewCountry: function (req, res) {
        let {
            country
        } = {
            ...req.body,
            ...req.query,
            ...req.params
        }

        if (req.method == 'POST') {
            countryMaster.addNewCountries(country).then((data) => {
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
                res.json({
                    status: 200,
                    msg: 'Successfully Updated'
                })
            }).catch((err) => {
                console.log('error found :::::::::::::', err)
                res.json({
                    status: 500,
                    msg: err
                })
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
            countryMaster.disableCountry(countryId).then((data) => {
                console.log('data::::::::::::::::::>>>>>', data.rows)
                res.json({
                    status: 200,
                    msg: 'Successfully Deleted'
                })
            }).catch((err) => {
                console.log('error found :::::::::::::', err)
                res.json({
                    status: 500,
                    msg: err
                })
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