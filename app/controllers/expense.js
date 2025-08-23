
const Expense = require('../models/admin/masters/expenseMaster');

module.exports = {

    expensesMaster: async (req, res) => {
        try {
            let { _user } = {
                ...req.body,
            };

            const expenseList = await Expense.findAllActive();
            res.render("admin/master/expenses", {
                expenseList: expenseList.rows
            });
        } catch (e) {
            console.log(e)
        }
    },

    getAll: async (req, res) => {
        try {
            let { _user } = {
                ...req.body,
            };

            const expenseList = await Expense.findAllActive();
            res.status(200).json({
                status: 'success',
                message: 'Expenses fetched successfully.',
                expenseList: expenseList.rows
            });
        } catch (e) {
            console.log(e)
            res.status(200).json({
                status: 'failed',
                message: 'Error while fetching expenses!',
                expenseList: []
            });
        }
    },

    add: async (req, res) => {
        try {
            let { _user, expenseList } = {
                ...req.body,
            };

            const result = await Expense.add(expenseList)

            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].insert_expense
            });

        } catch (e) {
            console.log('e>>>>>> ', e)
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    addSingle: async (req, res) => {
        try {
            let { _user, expenseName } = {
                ...req.body,
            };

            const result = await Expense.addSingle(expenseName)

            res.status(200).json({
                status: 'success',
                message: 'New expense created successfully.',
                expenseDetail: result.rows[0]
            });

        } catch (e) {
            console.log('e>>>>>> ', e)
            res.status(500).json({
                status: 'failed',
                message: 'Error creating a new expense!',
                expenseDetail: null
            });
        }
    },

    update: async (req, res) => {
        try {
            let { _user, expenseData } = {
                ...req.body,
            };

            console.log('expenseData>> ', expenseData);

            const result = await Expense.update(expenseData);
            console.log('data>>> ', result.rows);

            res.status(200).json({
                message: 'Successfully updated.',
                status: 'success',
            });

        } catch (e) {
            console.log(e);
            res.status(500).json({
                message: 'Something went wrong.',
                status: 'error',
            });
        }
    },

    delete: async (req, res) => {

        try {
            let { _user, expenseData } = {
                ...req.body,
            };

            const data = await Expense.delete(expenseData);

            res.status(200).json({
                message: 'Deleted successfully!',
                status: 'success'
            });


        } catch (e) {
            console.log(e);
            res.status(500).json({
                message: 'Something went wrong.',
                status: 'error',
            });
        }

    }



}