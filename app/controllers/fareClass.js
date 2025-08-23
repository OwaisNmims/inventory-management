const modeOfTransport = require('../models/admin/masters/modeOfTransport');
const fareClass = require('../models/admin/masters/fareClass');

module.exports = {
    getFareClass: async function (req, res) {
        let { _user } = {
          ...req.body,
        };
        if (req.method == "GET") {

            try{
                let fareClassData = await fareClass.getAllFareClass();
                let modeOfTransportData = await modeOfTransport.getAllModes();

               
                res.render("admin/master/fare-class", {
                    status:200,
                    fareClasses: fareClassData.rows,
                    modes: modeOfTransportData.rows
                })
            }
            catch(error){
                
                res.render("admin/error", {
                    error: error
                })
            }

           
        }
    },

    insert: async function (req, res) {
        let { _user } = {
          ...req.body,
        };

        let fareClassData = req.body.fareClassData;

        if (req.method == "POST") {

            try{
                let insertResult = await fareClass.insert(fareClassData);
                res.status(200).json({
                    status: 200,
                    message: 'success',
                    data: insertResult.rows[0].insert_fare_class
                })
            }
            catch(error){

                res.status(500).json({
                    status: 500,
                    message: 'Failed',
                })
            }

           
        }
    },

    updateFareClass: async function (req, res) {

        let { _user } = {
          ...req.body,
        };

        if (req.method == "POST") {

            try{
                
                let updateResult = await fareClass.update(req.body.fareClassData);
                res.status(200).json({
                    status: 200,
                    message: 'success',
                    data: updateResult.rows[0].update_fare_class
                })
            }
            catch(error){

                res.status(500).json({
                    status: 500,
                    message: 'Failed',
                })
            }

           
        }
    },

    deleteFareClas: async function (req, res) {
        let { _user } = {
          ...req.body,
        };

        if (req.method == "POST") {

            try{
                let deleteResult = await fareClass.delete(req.body.fareClassData);
                res.status(200).json({
                    status: 200,
                    message: 'success'
                })
            }
            catch(error){

                res.status(500).json({
                    status: 500,
                    message: 'Failed'
                })
            }

           
        }
    },




}