const modeOfTransport = require('../models/admin/masters/modeOfTransport');
const carrier = require('../models/admin/masters/carrier');

module.exports = {
    getCarriers: async function (req, res) {
        let { _user } = {
          ...req.body,
        };
        if (req.method == "GET") {

            try{
                let carrierData = await carrier.getAllCarriers();
                let modeOfTransportData = await modeOfTransport.getAllModes();
               
                res.render("admin/master/carrier", {
                    status:200,
                    carriers: carrierData.rows,
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

        let carrierData = req.body.carrierData;

        if (req.method == "POST") {

            try{
                let insertResult = await carrier.insert(carrierData);
                res.status(200).json({
                    status: 200,
                    message: 'success',
                    data: insertResult.rows[0].insert_carriers
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

    updateCarrier: async function (req, res) {

        let { _user } = {
          ...req.body,
        };

        if (req.method == "POST") {

            try{
                
                let updateResult = await carrier.update(req.body.carrierData);
                res.status(200).json({
                    status: 200,
                    message: 'success',
                    data: updateResult.rows[0].update_carrier
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

    deleteCarrier: async function (req, res) {
        let { _user } = {
          ...req.body,
        };

        if (req.method == "POST") {

            try{
                let deleteResult = await carrier.delete(req.body.carrierData);
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