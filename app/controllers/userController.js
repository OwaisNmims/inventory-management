const Users = require("../models/admin/masters/users")

module.exports = {

	getAllUsers: async (req, res) => {
		try {
			const { _user } = req.body;
			const users = await Users.findAll();
			console.log('users:::::::::::', users)
			res.render('admin/master/user', {
				users : users ? users.rows : [],
				_user
			})
		} catch (error) {
			console.error('Get all users error:', error);
			res.status(500).render("error", { message: "Something went wrong!" });
		}
	},

	insert: async (req, res) => {
		try {
			let {_user, firstname, lastname, email, password} = {...req.body};
			const userId = _user?.id || 1;

			// Validate required fields
			if (!firstname || !lastname || !email || !password) {
				return res.status(400).json({
					message: 'error',
					status: 400,
					data: { message: 'All fields are required (firstname, lastname, email, password)' }
				});
			}

			// Check if email already exists
			const emailExists = await Users.emailExists(email);
			if (emailExists) {
				return res.status(400).json({
					message: 'error',
					status: 400,
					data: { message: 'Email already exists' }
				});
			}

			const userData = { firstname, lastname, email, password };
			const result = await Users.insert(userData, userId);

			return res.status(200).json({
				message: 'success',
				status: 200,
				data: { 
					message: 'User created successfully',
					user: result.rows[0]
				}
			});
		} catch (error) {
			console.error('Insert user error:', error);
			return res.status(500).json({
				message: 'error',
				status: 500,
				data: { message: 'Something went wrong!' }
			});
		}
	},

	updateUser: async (req, res) => {
		try {
			let {_user, userId: targetUserId, firstname, lastname, email} = {...req.body};
			const currentUserId = _user?.id || 1;

			// Validate required fields
			if (!targetUserId || !firstname || !lastname || !email) {
				return res.status(400).json({
					message: 'error',
					status: 400,
					data: { message: 'User ID, firstname, lastname, and email are required' }
				});
			}

			// Check if email already exists (excluding current user)
			const emailExists = await Users.emailExists(email, targetUserId);
			if (emailExists) {
				return res.status(400).json({
					message: 'error',
					status: 400,
					data: { message: 'Email already exists' }
				});
			}

			const userData = { userId: targetUserId, firstname, lastname, email };
			const result = await Users.update(userData, currentUserId);

			if (result.rows.length === 0) {
				return res.status(404).json({
					message: 'error',
					status: 404,
					data: { message: 'User not found' }
				});
			}

			return res.status(200).json({
				message: 'success',
				status: 200,
				data: { 
					message: 'User updated successfully',
					user: result.rows[0]
				}
			});
		} catch (error) {
			console.error('Update user error:', error);
			return res.status(500).json({
				message: 'error',
				status: 500,
				data: { message: 'Something went wrong!' }
			});
		}
	},

	updatePassword: async (req, res) => {
		try {
			let {_user, userId: targetUserId, newPassword} = {...req.body};
			const currentUserId = _user?.id || 1;

			// Validate required fields
			if (!targetUserId || !newPassword) {
				return res.status(400).json({
					message: 'error',
					status: 400,
					data: { message: 'User ID and new password are required' }
				});
			}

			// Validate password strength (at least 6 characters)
			if (newPassword.length < 6) {
				return res.status(400).json({
					message: 'error',
					status: 400,
					data: { message: 'Password must be at least 6 characters long' }
				});
			}

			const result = await Users.updatePassword(targetUserId, newPassword, currentUserId);

			if (result.rows.length === 0) {
				return res.status(404).json({
					message: 'error',
					status: 404,
					data: { message: 'User not found' }
				});
			}

			return res.status(200).json({
				message: 'success',
				status: 200,
				data: { message: 'Password updated successfully' }
			});
		} catch (error) {
			console.error('Update password error:', error);
			return res.status(500).json({
				message: 'error',
				status: 500,
				data: { message: 'Something went wrong!' }
			});
		}
	},

	deleteUser: async (req, res) => {
		try {
			let {_user, userId: targetUserId} = {...req.body};
			const currentUserId = _user?.id || 1;

			if (!targetUserId) {
				return res.status(400).json({
					message: 'error',
					status: 400,
					data: { message: 'User ID is required' }
				});
			}

			// Prevent user from deleting themselves
			if (parseInt(targetUserId) === parseInt(currentUserId)) {
				return res.status(400).json({
					message: 'error',
					status: 400,
					data: { message: 'You cannot delete your own account' }
				});
			}

			await Users.deleteById(targetUserId, currentUserId);

			return res.status(200).json({
				message: 'success',
				status: 200,
				data: { message: 'User deleted successfully' }
			});
		} catch (error) {
			console.error('Delete user error:', error);
			return res.status(500).json({
				message: 'error',
				status: 500,
				data: { message: 'Something went wrong!' }
			});
		}
	}     
}