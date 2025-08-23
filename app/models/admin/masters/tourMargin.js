const { pool } = require("../../../config/dbConfig");
module.exports = {
  findByTourId : (tour_lid) => {
    const statement = {
		  text : `select margin  from tour_margin tm  where tour_lid = $1`,
			values: [tour_lid]
		}
    return pool.query(statement);
  },

  insert : (margin, tour_lid, created_by) => {
      const statement = {
        text : `select * from insert_update_margin($1, $2, $3);`,
        values: [margin, tour_lid, created_by]
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