
const TourPax = require('../models/admin/tourPassenger');

module.exports = {

    add: async (req, res) => {
        try {

            let { _user, tourPaxDetails } = {
                ...req.body,
            };

            console.log('tourPaxDetails>>> ', tourPaxDetails)

            let tourPaxExists = await TourPax.checkIfExist(tourPaxDetails.TOUR_LID, tourPaxDetails.paxTypeLid);

            if (tourPaxExists.rows[0].count > 0) {
                return res.status(200).json({
                    status: 'failed',
                    message: 'Duplicate entry! Tour pax type already exists.',
                    tourPaxLid: null
                });
            }

            let result = await TourPax.add(tourPaxDetails);

            console.log('result.rows>>> ', result.rows)

            res.status(200).json({
                status: 'success',
                message: 'Tour pax added successfully.',
                tourPaxLid: result.rows[0].id
            });
        } catch (e) {
            console.log('error occured>>>>>> ', e);
            res.status(200).json({
                status: 'failed',
                message: 'Something went wrong!',
                tourPaxLid: null
            });
        }
    },
    update: async (req, res) => {
        try {

            let { _user, tourPaxDetails } = {
                ...req.body,
            };

            console.log('tourPaxDetails>>> ', tourPaxDetails)
            //no_of_passengers, is_payable, payment_percentage, payment_amount, occupancy_preference, updated_by, id
            let result = await TourPax.update(tourPaxDetails);

            console.log('result.rows>>> ', result.rows)

            res.status(200).json({
                status: 'success',
                message: 'Tour pax updated successfully.',
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

            let { _user, tourPaxLid } = {
                ...req.body,
            };

            console.log('tourPaxLid>>> ', tourPaxLid)
            let result = await TourPax.delete(tourPaxLid);

            res.status(200).json({
                status: 'success',
                message: 'Tour pax deleted successfully.',
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