const {
    pool
} = require("../../../config/dbConfig");

module.exports = class StateMasters {

    static findAllActive() {
        let statement;
        statement = {
            text: `select s.id, s.country_lid, c.name as country_name, s.name as state_name 
            from state s 
            join country c on c.id = s.country_lid
            where s.active = true and c.active = true;`,
            values: []
        };
        console.log('statement::::::::::::::::::::', statement)
        return pool.query(statement)
    }

    static addNewState(states) {
        JSON.parse(states);
        let statement;
        statement = {
            text: `select add_new_state($1, $2)`,
            values: [states, 'admin']
        }
        console.log('statement::::::::::::::::::', statement)
        return pool.query(statement)
    }

    static editState(stateName, countryLid, stateLid) {
        let statement;
        statement = {
            text: `UPDATE state set name = $1, country_lid = $2::int, updated_by = $3, updated_at = now() where id = $4::int; `,
            values: [stateName, countryLid, 'admin', stateLid]
        }
        console.log('statement for edit state::::::::::::::::::', statement)
        return pool.query(statement)
    }

    static diableState(stateLid) {
        let statement = {
            text: `UPDATE state set active = $1, updated_by = $2, updated_at = now() where id = $3; `,
            values: [false, 'admin', stateLid]
        }
        return pool.query(statement)
    }

    static findByCountry(countryLid) {
        let statement = {
            text: `SELECT id, name FROM state WHERE country_lid = $1; `,
            values: [countryLid]
        }
        return pool.query(statement)
    }
    
};