const CountryMasters = require('../models/admin/masters/countryMaster');
const StateMasters = require('../models/admin/masters/stateMaster');
const city = require('../models/admin/masters/city');
const currency = require('../models/admin/masters/currency');
module.exports = {
  masterDashboard: function (req, res) {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {

      res.render("admin/master/dashboard", { _user })

    }
  },
  dashboard: function (req, res) {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {
      res.render("admin/dashboard", { _user })
    }
  },
  invoice: function (req, res) {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {
      res.render("admin/invoice", { _user })
    }
  },
  countryMaster: function (req, res) {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {
      CountryMasters.findAllActive().then((data) => {

        console.log('data:::::::::::::::::::', data.rows)
        res.render("admin/master/country", {
          countryData: data.rows,
          _user
        })
      }
      ).catch((err) => {
        console.log('this is the error', err)
      })
    }
  },
  carrierMaster: function (req, res) {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {
      res.render("admin/master/carrier", { _user })
    }
  },
  cityMaster: async (req, res) => {
    let { _user } = {
      ...req.body,
    };

    console.log('users', _user);

    if (req.method == "GET") {
      const cities = await city.getAllCities();
      console.log('cities>>> ', cities.rows);
      res.render("admin/master/city", { 
        cities: cities ? cities.rows : [],
        _user
      });
    }

    if (req.method == "POST") {
      const cities = await city.updateCity(req.body);
      res.status(200).json({
        message: 'Success',
        status: 200
      });
    }
  },

  stateMaster: function (req, res) {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {

      Promise.allSettled([StateMasters.findAllActive(), CountryMasters.findAllActive()]).then((data) => {
        console.log('this is country data::::::', data[1].value.rows)
            console.log('this is state data::::::', data[0].value.rows)
        res.render("admin/master/state", {
          stateData: data[0].value.rows,
          countryData: data[1].value.rows,
          _user
        });
      }).catch((err) => {
        console.log('error:::::::::::::::::', err)
        res.render("admin/master/state", {
          status: 500,
          err: err,
          _user
        })
      })
    }
  },
  currencyMaster: async (req, res) => {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {
      const currencies = await currency.getAllCurrency();
      console.log('countries ::::>>', currencies.rows); 
      res.render("admin/master/currency-type", {
        currencies: currencies ? currencies.rows: [],
        _user
      });
    }
  },
  fareClassMaster: function (req, res) {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {
      res.render("admin/master/fare-class", { _user })
    }
  },
  hotelMaster: function (req, res) {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {
      res.render("admin/master/hotels", { _user })
    }
  },
  roomTypeMaster: function (req, res) {
    let { _user } = {
      ...req.body,
    };
    if (req.method == "GET") {
      res.render("admin/master/room-type", { _user })
    }
  },

  

}