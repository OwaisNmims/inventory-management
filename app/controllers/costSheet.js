
const Tour = require('../models/admin/tour');
const Passenger = require('../models/admin/masters/passenger');
const TourPax = require('../models/admin/tourPassenger');
const Currency = require('../models/admin/masters/currency');
const TourExpense = require('../models/admin/tourExpense');
const Expense = require('../models/admin/masters/expenseMaster');
const taxModel = require("../models/admin/masters/tax");
const tourTax = require('../models/admin/tourTax');
const tourMargin = require('../models/admin/masters/tourMargin');
module.exports = {

    renderCostSheets: async (req, res) => {
        try {

            let { _user } = {
                ...req.body,
            };

            let costSheets = await Tour.findAllActive();

            console.log(costSheets.rows)

            res.render("admin/costSheet", {
                costSheets: costSheets.rows
            })
        } catch (e) {
            res.send('Opps! Something went wrong.');
            console.log('error occured>>>>>> ', e);
        }

    },

    renderCostSheetGenerator: async (req, res) => {
        try {
            let { _user } = {
                ...req.body
            };

            let costSheetLid = req.query.id;

            if (!costSheetLid) {
                const result = await Promise.all([Passenger.getAll(), Currency.getAllCurrency(), taxModel.getAllTaxes()]);

                return res.render("admin/costSheetGenerator", { 
                    tourDetails: null,
                    tourPaxDetails: [],
                    currencyList: result[1].rows,
                    tourExpenseList: [],
                    expenseList: [],
                    paxTypes: result[0].rows,
                    tax: result[2].rows,
                    tourTaxes: [],
                    margin : []
                });
            }

            const result = await Promise.all([Tour.getTour(costSheetLid), Passenger.getAll(), TourPax.getAllByTourId(costSheetLid), Currency.getAllCurrency(), TourExpense.getAllByTourId(costSheetLid), Expense.findAllActive(), taxModel.getAllTaxes(), tourTax.getAllByTourId(costSheetLid), tourMargin.findByTourId(costSheetLid)]);

            console.log('result[6].rows >>> ', result[7].rows)


            res.render("admin/costSheetGenerator", {
                tourDetails: result[0].rows[0],
                paxTypes: result[1].rows,
                tourPaxDetails: result[2].rows,
                currencyList: result[3].rows,
                tourExpenseList: result[4].rows,
                expenseList: result[4].rows,
                tax: result[6].rows,
                tourTaxes: result[7].rows,
                margin: result[8].rows.length ?  result[8].rows[0].margin : 0
            });
        } catch (e) {
            console.log(e);
            res.send('Ops! Something went wrong.');
        }

    },

    addMargin: async (req, res) => {
        try {
            let { _user, margin, tour_lid } = {
                ...req.body,
                ...req.params,
                ...req.query
            };
            const result = await tourMargin.insert(margin, tour_lid, _user.id);
            console.log('result::::::::',result.rows[0])
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].insert_update_margin
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
    }
}