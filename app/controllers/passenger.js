
const passenger = require('../models/admin/masters/passenger');

module.exports = {

    passengerMaster: async (req, res) => {
        try {
            let { _user } = {
                ...req.body,
            };

            const passengerList = await passenger.getAll();
            res.render("admin/master/passenger", {
                passengerList: passengerList.rows
            });
        } catch (e) {
            console.log(e)
        }
    },

    add: async (req, res) => {
        try {
            let { _user, list } = {
                ...req.body,
            };

            const result = await passenger.add(list)

            res.status(200).json({
                message: 'Data inserted successfully!',
                status: 'success',
                data: result.rows[0].insert_pax_type
            });

        } catch (e) {
            console.log('e>>>>>> ', e)
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    update: async (req, res) => {
        try {
            let { _user, data } = {
                ...req.body,
            };

            console.log('data>> ', data);

            const result = await passenger.update(data);
            console.log('result>>> ', result.rows);

            res.status(200).json({
                message: 'Successfully updated.',
                status: 'success',
            });

        } catch (e) {
            console.log(e);
            res.status(500).json({
                message: 'Something went wrong.',
                status: 'error',
            });
        }
    },

    delete: async (req, res) => {

        try {
            let { _user, data } = {
                ...req.body,
            };

            const result = await passenger.delete(data);

            res.status(200).json({
                message: 'Deleted successfully!',
                status: 'success'
            });
        } catch (e) {
            console.log(e);
            res.status(500).json({
                message: 'Something went wrong.',
                status: 'error',
            });
        }

    }



}
