const { pool } = require("../../../config/dbConfig");
const bcrypt = require("bcrypt");

module.exports = {
    
    findAll: () => {
        const statement = {
            text: `SELECT id, firstname, lastname, email, created_at, updated_at FROM users WHERE active = true ORDER BY created_at DESC;`,
            values: []
        };
        return pool.query(statement);
    },

    findById: (userId) => {
        const statement = {
            text: `SELECT id, firstname, lastname, email, created_at, updated_at FROM users WHERE id = $1 AND active = true;`,
            values: [userId]
        };
        return pool.query(statement);
    },

    insert: async (data, createdBy = 1) => {
        // Hash the password before storing
        const hashedPassword = await bcrypt.hash(data.password, 10);
        
        const statement = {
            text: `INSERT INTO users (firstname, lastname, email, password, active, created_by, created_at) 
                   VALUES ($1, $2, $3, $4, true, $5, CURRENT_TIMESTAMP) 
                   RETURNING id, firstname, lastname, email, created_at;`,
            values: [data.firstname, data.lastname, data.email, hashedPassword, createdBy]
        };
        return pool.query(statement);
    },

    update: (data, updatedBy = 1) => {
        const statement = {
            text: `UPDATE users 
                   SET firstname = $2, 
                       lastname = $3, 
                       email = $4,
                       updated_at = CURRENT_TIMESTAMP,
                       updated_by = $5
                   WHERE id = $1 AND active = true
                   RETURNING id, firstname, lastname, email, updated_at;`,
            values: [data.userId, data.firstname, data.lastname, data.email, updatedBy]
        };
        return pool.query(statement);
    },

    updatePassword: async (userId, newPassword, updatedBy = 1) => {
        // Hash the new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        
        const statement = {
            text: `UPDATE users 
                   SET password = $2,
                       updated_at = CURRENT_TIMESTAMP,
                       updated_by = $3
                   WHERE id = $1 AND active = true
                   RETURNING id, firstname, lastname, email;`,
            values: [userId, hashedPassword, updatedBy]
        };
        return pool.query(statement);
    },

    deleteById: (id, deletedBy = 1) => {
        const statement = {
            text: `UPDATE users 
                   SET active = false, 
                       updated_at = CURRENT_TIMESTAMP,
                       updated_by = $2
                   WHERE id = $1;`,
            values: [id, deletedBy]
        };
        return pool.query(statement);
    },

    // Check if email already exists
    emailExists: async (email, excludeUserId = null) => {
        let statement;
        if (excludeUserId) {
            statement = {
                text: `SELECT id FROM users WHERE email = $1 AND id != $2 AND active = true;`,
                values: [email, excludeUserId]
            };
        } else {
            statement = {
                text: `SELECT id FROM users WHERE email = $1 AND active = true;`,
                values: [email]
            };
        }
        const result = await pool.query(statement);
        return result.rows.length > 0;
    }

}

