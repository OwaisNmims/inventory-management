const company = require('../models/admin/masters/company');
const Country = require('../models/admin/masters/countryMaster');
const CompanyType = require('../models/admin/masters/companyType');

module.exports = {

    companyMaster: async (req, res) => {
        let { _user } = {
            ...req.body,
        };

        if (req.method == "GET") {
            const countries = await Country.findAllActive();
            const companyTypes = await CompanyType.findAllActive();
            const companies = await company.getAllCompanies();
            console.log('companies>>> ', companies.rows);
            res.render("admin/master/company", {
                companies: companies ? companies.rows : [],
                countries: countries ? countries.rows : [],
                companyTypes: companyTypes ? companyTypes.rows : []
            });
        }
    },

    insert: async (req, res) => {
        try {
            let { _user, companyList } = {
                ...req.body,
            };

            const result = await company.insert(companyList);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].insert_companies
            });

        } catch (e) {
            console.error('Company insert error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    updateCompany: async (req, res) => {
        try {
            let { _user, companyData } = {
                ...req.body,
            };

            const result = await company.updateCompany(companyData);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].update_company
            });

        } catch (e) {
            console.error('Company update error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    deleteCompany: async (req, res) => {
        try {
            let { _user, companyLid } = {
                ...req.body,
            };

            const result = await company.deleteCompany({ companyLid });
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result
            });

        } catch (e) {
            console.error('Company delete error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    bulkInsert: async (req, res) => {
        try {
            let { _user, companies } = {
                ...req.body,
            };

            const result = await company.bulkInsert(companies, _user?.id || 1);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].add_new_companies
            });

        } catch (e) {
            console.error('Company bulk insert error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    }

}; 