const Tour = require('../models/admin/tour');
const tourExpense = require('../models/admin/tourExpense');
const tourPassenger = require('../models/admin/tourPassenger');
const taxModel = require("../models/admin/masters/tax")
const {currencyConverter, tourExpenseConverted, calculateTotalPriceInrSum} = require('../utils/index')

module.exports = {

  createTourPage: function (req, res) {
    if (req.method == "GET") {

      res.render("admin/create-tour")

    }
  },
  create: function (req, res) {
    let { tourName, tourNights } = {
      ...req.body,
      ...req.query,
      ...req.params
    };

    Tour.addNewTour(tourName, tourNights).then(data => {
      res.status(200).json({
        status: 'success',
        message: 'Tour created successfully.',
        tourDetails: data.rows[0]
      })
    }).catch(err => {
      console.log('this is my error from crteate tour :::::::', err);
      res.status(500).json({
        status: 'failed',
        message: 'Something went wrong!',
        tourLid: null
      })
    })

  },
  update: function (req, res) {
    let {tourLid, tourName, tourNights } = {
      ...req.body,
      ...req.query,
      ...req.params
    };

    Tour.update(tourName, tourNights, tourLid).then(data => {

      res.status(200).json({
        status: 'success',
        message: 'Tour updated successfully.',
        tourDetails: data.rows[0]
      })
    }).catch(err => {
      console.log('this is my error from crteate tour :::::::', err);
      res.status(500).json({
        status: 'failed',
        message: 'Something went wrong!',
        tourDetails: null
      })
    })
  },

  delete: function(req, res){
    let {id } = {
      ...req.body,
      ...req.query,
      ...req.params
    };
    Tour.delete(id).then(data => {
      res.status(200).json({
        status: 'success',
        message: 'Tour deleted successfully.',
        tourDetails: data.rows[0]
      })
    }).catch(err => {
      console.log('this is my error from crteate tour :::::::', err);
      res.status(500).json({
        status: 'failed',
        message: 'Something went wrong!',
        tourDetails: null
      })
    })
  },

  tourDashboard: function (req, res) {
    if (req.method == "GET") {
      Tour.findAllActive().then(result => {
        console.log('result::::::::::::::::::', result)
        res.render("admin/tour", {
          tourData: result.rows
        })
      }).catch(err => {
        console.log('er::::::::::::::', err)
      })


    }
  },
  editDetails: function (req, res) {
    let { tourId } = {
      ...req.body,
      ...req.query,
      ...req.params
    }

    if (req.method == "GET") {

      Promise.allSettled([Tour.getTour(tourId), Tour.getPassengers()]).then(result => {
        console.log('result::::::::::::::::::', result[1].value.rows)
        res.render("admin/index", {
          tourDetails: result[0].value.rows[0],
          passenger: result[1].value.rows
        })
      }).catch(err => {
        console.log('er::::::::::::::', err)
      })


    }
  },
  
  tourInvoice: function (req, res) {
    let { tourId, _user } = {
      ...req.body,
      ...req.query,
      ...req.params
    }

    let userId = _user.id;

    if (req.method == "GET") {
     
      Promise.allSettled([tourExpense.getAllByTourId(tourId), tourPassenger.getAllByTourId(tourId), 
        taxModel.getAllTaxes(), tourExpense.totalTourPrice(tourId), tourExpense.totalTourPriceInr(tourId), tourExpense.tourCurrencyRates(tourId)])
      .then(async result => {

        let totalCostInr = result[4].value.rows[0].total_price_inr; 
        let tourQuote = await  tourExpense.quoteForPax(tourId, totalCostInr, userId)
        console.log('result::::::::::::::::::: tour quote', tourQuote.rows[0].tour_quotations)
        console.log('result:1111111:::::::::::::::::', result[0].value.rows)
        console.log('result:::222222222:::::::::::::::',result[1].value.rows)
        console.log('result::::::::::::::::::',result[3].value.rows)
        console.log('result:::::::::::::::::: tourCurrencyRates',result[5].value.rows)

        res.render("admin/invoice", {
          tourExpense: result[0].value.rows,//result[0].value.rows,
          tourPasenger: result[1].value.rows,
          tax : result[2].value.rows,
          total_price : result[3].value.rows[0].total_price,
          sum_amt: result[4].value.rows[0].total_price_inr,
          tour_quote: tourQuote.rows[0].tour_quotations,
          tourCurrencyRates: result[5].value.rows
        })
      }).catch(err => {
        console.log('er::::::::::::::', err)
      })
    }
  },


}