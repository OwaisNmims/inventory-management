const {
    pool
  } = require("../../../config/dbConfig");

  module.exports = class CountryMasters {

    static findAllActive (){
        let statement;
        statement = {
            text: `select id, name, code from country where active = true order by name`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement)
        return pool.query(statement)
    }

    static addNewCountries(countries){
        JSON.parse(countries);
        let statement;
        statement = {
            text: `select add_new_countries($1, $2)`,
            values: [countries, 'admin']
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }
    static editCountry(countryName, countryId){

        let statement;
        statement = {
            text: `UPDATE country set name = $1, updated_by = $2, updated_at = now() where id = $3; `,
            values: [countryName, 'admin', countryId]
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }
    static disableCountry(countryId){

        let statement;
        statement = {
            text: `UPDATE country set active = $1, updated_by = $2, updated_at = now() where id = $3; `,
            values: [false, 'admin', countryId]
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }
    static searchCountry(countryName){

        let statement;
        statement = {
            text: `select name from country where active = true and LOWER(name) ILIKE LOWER('%' || $1 || '%')  `,
            values: [countryName]
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }
  };