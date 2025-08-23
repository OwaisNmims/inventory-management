const Users = require("../models/admin/masters/users")

module.exports = {

	getAllUsers: async (req, res) => {
		let {_user} = {
      ...req.body,
    };
		const users = await Users.findAll();
        console.log('users:::::::::::', users)
		res.render('admin/master/user', {
			users : users ? users.rows : []
		})
	},

	insert: async (req, res) => {
		let {_user, input_json} = {...req.body};
		const addTax = await taxModel.insert(input_json);

		return res.status(200).json({
			message: 'success',
			status: 200,
			data:  addTax.rows[0].add_new_tax
		});
	},
	updateTax: async (req, res) => {
		let {_user, taxData} = {...req.body};

		const updateTax = await taxModel.update(taxData);

		return res.status(200).json({
			status: true,
			message: "Successfully Updated!",
			data: updateTax.rows[0].update_tax
		})
	},
	deleteTax: async (req, res) => {
		let {_user, taxData} = {...req.body};

		await taxModel.delete(taxData);

		res.status(200).json({
			status: true,
			message: "Delete Successfully!"
		})
	}     
}