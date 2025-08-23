const modeOfTransport = require('../models/admin/masters/modeOfTransport');

module.exports = {
    getModeOfTransports: async function (req, res) {
        let { _user } = {
          ...req.body,
        };
        if (req.method == "GET") {

            try{
                let modeOfTransportData = await modeOfTransport.getAllModes();
                res.render("admin/master/mode-of-transport", {
                    status:200,
                    modeOfTransport: modeOfTransportData.rows
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

        let transportModeData = req.body.transportModeData;

        if (req.method == "POST") {

            try{
                let insertResult = await modeOfTransport.insert(transportModeData);
                res.status(200).json({
                    status: 200,
                    message: 'success',
                    data: insertResult.rows[0].insert_mode_of_transport
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

    updateMode: async function (req, res) {
        let { _user } = {
          ...req.body,
        };

        if (req.method == "POST") {

            try{
                let updateResult = await modeOfTransport.update(req.body.modeData);
                res.status(200).json({
                    status: 200,
                    message: 'success',
                    data: updateResult.rows[0].update_mode_of_transport
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

    deleteMode: async function (req, res) {
        let { _user } = {
          ...req.body,
        };

        if (req.method == "POST") {

            try{
                let deleteResult = await modeOfTransport.delete(req.body.modeData);
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