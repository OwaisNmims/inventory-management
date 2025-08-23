
const TourExpense = require('../models/admin/tourExpense');

module.exports = {

    add: async (req, res) => {
        try {

            let { _user, tourExpense } = {
                ...req.body,
            };
            console.log('tourrrrrrr expense', tourExpense)
            let result = await TourExpense.add(tourExpense);
            res.status(200).json({
                status: 'success',
                message: 'Tour expense added successfully.',
                tourExpenseLid: result.rows[0].id
            });
        } catch (e) {
            console.log('error occured>>>>>> ', e);
            res.status(200).json({
                status: 'failed',
                message: 'Something went wrong!',
                tourExpenseLid: null
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

            let { _user, tourExpenseLid } = {
                ...req.body,
            };

            console.log('tourExpenseLid>>> ', tourExpenseLid)
            let result = await TourExpense.delete(tourExpenseLid);

            res.status(200).json({
                status: 'success',
                message: 'Tour expense deleted successfully.',
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