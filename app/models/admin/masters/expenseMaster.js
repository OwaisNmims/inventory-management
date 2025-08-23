const {
    pool
} = require("../../../config/dbConfig");


module.exports = class ExpensesMasters {

    static findAllActive() {
        let statement;
        statement = {
            text: `SELECT id, name FROM expenses WHERE active = true;`,
            values: []
        };
        return pool.query(statement)
    }

    static add(expenses) {
        let statement = {
            text: `SELECT insert_expense($1, $2)`,
            values: [JSON.stringify(expenses), 1]
        }
        return pool.query(statement)
    }

    static addSingle(name) {
        let statement = {
            text: `INSERT INTO expenses(name, created_by) VALUES($1, $2) RETURNING id, name;`,
            values: [name, 1]
        }
        return pool.query(statement)
    }

    static update(expense) {
        let statement = {
            text: `UPDATE expenses set name = $1, updated_by = $2, updated_at = now() where id = $3; `,
            values: [expense.expenseName, 1, expense.expenseLid]
        }
        return pool.query(statement)
    }

    static delete(expense) {
        let statement = {
            text: `UPDATE expenses SET active = false, updated_by = $1 WHERE id = $2; `,
            values: [1, expense.expenseLid]
        }
        return pool.query(statement)
    }
}