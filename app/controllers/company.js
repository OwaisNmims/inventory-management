const company = require('../models/admin/masters/company');
const Country = require('../models/admin/masters/countryMaster');
const CompanyType = require('../models/admin/masters/companyType');
const StateMaster = require('../models/admin/masters/stateMaster');
const CityModel = require('../models/admin/masters/city');

module.exports = {

    companyMaster: async (req, res) => {
        let { _user } = {
            ...req.body,
        };

        if (req.method == "GET") {
            const countries = await Country.findAllActive();
            const companyTypes = await CompanyType.findAllActive();
            const states = await StateMaster.findAllActive();
            const cities = await CityModel.getAllCities();
            const companies = await company.getAllCompanies();
            res.render("admin/master/company", {
                companies: companies ? companies.rows : [],
                countries: countries ? countries.rows : [],
                companyTypes: companyTypes ? companyTypes.rows : [],
                states: states ? states.rows : [],
                cities: cities ? cities.rows : []
            });
        }
    },

    insert: async (req, res) => {
        try {
            let { _user, companyList } = {
                ...req.body,
            };

            const invalidEntry = companyList?.find(
                (entry) => !entry.stateLid || !entry.cityLid
            );
            if (invalidEntry) {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'State and city are required for every company' }
                });
            }

            const result = await company.insert(companyList);
            const insertResult = result.rows[0].insert_companies;
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: { 
                    message: insertResult.message,
                    inserted_count: insertResult.inserted_count,
                    duplicate_count: insertResult.duplicate_count
                }
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

            if (!companyData.stateLid || !companyData.cityLid) {
                return res.status(400).json({
                    message: 'error',
                    status: 400,
                    data: { message: 'State and city are required for the company' }
                });
            }

            const result = await company.updateCompany(companyData);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: { message: 'Company updated successfully', company: result.rows[0] }
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
            const userId = _user?.id || 1;

            // Validate if company can be deleted (business logic in model)
            const validation = await company.validateCompanyDeletion(companyLid);

            if (!validation.canDelete) {
                const statusCode = validation.reason === 'Company not found' ? 404 : 400;
                return res.status(statusCode).json({
                    message: 'error',
                    status: statusCode,
                    data: { message: validation.reason }
                });
            }

            // Proceed with deletion
            const result = await company.deleteCompany({ companyLid }, userId);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: { message: 'Company deleted successfully' }
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
                data: { message: 'Company created successfully', company: result.rows[0] }
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