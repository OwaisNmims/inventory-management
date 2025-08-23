const { pool } = require("../../../config/dbConfig");


module.exports = {
  getAllTaxes : () => {
    const statement = {
		  text : `SELECT id, name, percentage FROM tax WHERE active = true;`,
			values: []
		}

    return pool.query(statement);
  },
  insert : (taxList) => {
    JSON.parse(taxList);

      const statement = {
        text : `select add_new_tax($1, $2)`,
        values: [taxList, 1]
      }

      return pool.query(statement);
   

  },
  update: (tax) => {
    const statement = {
      text: `SELECT update_tax($1, $2, $3);`,
      values: [ tax.taxId, tax.taxName, tax.taxPercentage]
    }
    return pool.query(statement);
  },
  delete: (data) => {
    const statement = {
      text: `UPDATE tax SET active = false WHERE id = $1;`,
      values:[data.taxId]
    };
    return pool.query(statement);
  }
};