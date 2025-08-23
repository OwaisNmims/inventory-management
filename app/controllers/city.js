
const city = require('../models/admin/masters/city');
const Country = require('../models/admin/masters/countryMaster');

module.exports = {

    cityMaster: async (req, res) => {
        let { _user } = {
            ...req.body,
        };

        if (req.method == "GET") {
            const countries = await Country.findAllActive();
            const cities = await city.getAllCities();
            console.log('cities>>> ', cities.rows);
            res.render("admin/master/city", {
                cities: cities ? cities.rows : [],
                countries: countries ? countries.rows : []
            });
        }
    },

    insert: async (req, res) => {

        try {
            let { _user, cityList } = {
                ...req.body,
            };

            const result = await city.insert(cityList);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].insert_cities
            });

        } catch (e) {
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }

    },

    updateCity: async (req, res) => {
        let { _user, cityData } = {
            ...req.body,
        };

        console.log('users', req.body);

        if (req.method == "POST") {
            const data = await city.updateCity(cityData);
            console.log('data>>> ', data.rows);
            res.status(200).json({
                message: 'Success',
                status: 200,
                data: data.rows[0].update_city
            });
        }
    },

    deleteCity: async (req, res) => {
        let { _user, cityData } = {
            ...req.body,
        };

        console.log('users', req.body);

        if (req.method == "POST") {
            const data = await city.deleteCity(cityData);
            console.log('data>>> ', data.rows);
            res.status(200).json({
                message: 'Success',
                status: 200
                // data: data.rows[0].update_city
            });
        }
    }



}