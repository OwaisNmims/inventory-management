
const TourTax = require('../models/admin/tourTax');

module.exports = {

    add: async (req, res) => {
        try {

            let { _user, tourTax } = {
                ...req.body,
            };

            console.log('user::::::::::', _user)
            console.log('user::::::::::', tourTax)
            let result = await TourTax.add(tourTax, _user.id);
            console.log('result:::::::::::::::::::::::::', result)
            res.status(200).json({
                status: 'success',
                message: 'Tour Tax added successfully.',
                tourTaxLid: result.rows[0].id
            });
        } catch (e) {
            console.log('error occured>>>>>> ', e);
            res.status(500).json({
                status: 'failed',
                message: 'Something went wrong!',
                tourTaxLid: null
            });
        }
    },
    update: async (req, res) => {
        try {

            let { _user, tourExpense } = {
                ...req.body,
            };

            console.log('tourExpense>>> ', tourExpense)

            let result = await TourExpense.update(tourExpense);

            res.status(200).json({
                status: 'success',
                message: 'Tour expense updated successfully.',
            });
        } catch (e) {
            console.log('error occured>>>>>> ', e);
            res.status(200).json({
                status: 'failed',
                message: 'Something went wrong!',
            });
        }
    },


    delete: async (req, res) => {
        try {

            let { _user, id } = {
                ...req.body,
            };

            console.log('USER:::::::::::', _user)

            // console.log('tourExpenseLid>>> ', id)
            let result = await TourTax.delete(_user.id, id);

            res.status(200).json({
                status: 'success',
                message: 'Tour taxes deleted successfully.',
            });
        } catch (e) {
            console.log('error occured>>>>>> ', e);
            res.status(200).json({
                status: 'failed',
                message: 'Something went wrong!',
            });
        }
    }
}