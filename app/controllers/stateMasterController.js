const StateMaster = require("../models/admin/masters/stateMaster")


module.exports = {
    addNewState: function (req, res) {
        let {
            input_json
        } = {
            ...req.body,
            ...req.query,
            ...req.params
        }

        if (req.method == 'POST') {
            StateMaster.addNewState(input_json).then((data) => {
                res.json(data.rows)
            }).catch((err) => {
                console.log('error found :::::::::::::', err)
            })
        }
    },
    editState: function (req, res) {
        let {
            stateName, countryLid, stateLid
        } = {
            ...req.body,
            ...req.query,
            ...req.params
        }

        if (req.method == 'POST') {
            console.log('stateName::::::::', stateName)
            console.log('countryLid::::::::', countryLid)
            console.log('stateLid::::::::', stateLid)
            StateMaster.editState(stateName, countryLid, stateLid).then((data) => {
                console.log('data::::::::::::::::::>>>>>', data.rows)
                res.json({
                    status: 200,
                    msg: "SuccessFully Updated"
                })
            }).catch((err) => {
                console.log('error found :::::::::::::', err);
                res.json({
                    status: 500,
                    msg: err.message
                })
            })
        }
    },
    disableState: function (req, res) {
        let {
            stateLid
        } = {
            ...req.body,
            ...req.query,
            ...req.params
        }

        if (req.method == 'POST') {
            StateMaster.diableState(stateLid).then((data) => {
                console.log('data::::::::::::::::::>>>>>', data.rows)
                res.json({
                    status: 200,
                    msg: "Deleted Successfully!"
                })
            }).catch((err) => {
                console.log('error found :::::::::::::', err);
                res.json({
                    status: 500,
                    msg: err
                })
            })
        }
    },

    findByCountry: async (req, res) => {
        try {
            let countryLid = req.query.countryLid;
            const states = await StateMaster.findByCountry(countryLid);
            console.log('states>>>>>>>>>> ', states.rows);
            res.status(200).json({
                status: 200,
                message: 'success',
                states: states.rows
            });
        } catch (e) {
            res.status(200).json({
                status: 500,
                message: 'Error occured!',
                states: []
            });
        }
    },
}