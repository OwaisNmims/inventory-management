const {
    pool
} = require("../../config/dbConfig");

module.exports = class Login { 
    static findOneForLogin(email) {
        let statement = {
            text: `SELECT id, firstname, lastname, email, password FROM users WHERE email = $1 AND active = true`,
            values: [email]
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }

}