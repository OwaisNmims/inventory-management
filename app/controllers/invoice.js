const taxModel = require("../models/admin/masters/tax")

module.exports = {

    getAllTaxesForInvoice: async (req, res) => {
        let {_user} = {
      ...req.body,
    };
        const taxes = await taxModel.getAllTaxes();
        res.render('admin/invoice', {
            tax : taxes ? taxes.rows : []
        })
    }
}