const companyType = require('../models/admin/masters/companyType');

module.exports = {

    companyTypeMaster: async (req, res) => {
        let { _user } = {
            ...req.body,
        };

        if (req.method == "GET") {
            const companyTypes = await companyType.getAllCompanyTypes();
            console.log('companyTypes>>> ', companyTypes.rows);
            res.render("admin/master/companyType", {
                companyTypes: companyTypes ? companyTypes.rows : []
            });
        }
    },

    insert: async (req, res) => {
        try {
            let { _user, companyTypeList } = {
                ...req.body,
            };

            const result = await companyType.insert(companyTypeList);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].insert_company_types
            });

        } catch (e) {
            console.error('Company type insert error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    updateCompanyType: async (req, res) => {
        try {
            let { _user, companyTypeData } = {
                ...req.body,
            };

            const result = await companyType.updateCompanyType(companyTypeData);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].update_company_type
            });

        } catch (e) {
            console.error('Company type update error:', e);
            res.status(500).json({
                message: 'error',
                status: 500,
                data: {
                    message: 'Something went wrong!'
                }
            });
        }
    },

    deleteCompanyType: async (req, res) => {
        try {
            let { _user, companyTypeLid } = {
                ...req.body,
            };

            const result = await companyType.deleteCompanyType({ companyTypeLid });
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result
            });

        } catch (e) {
            console.error('Company type delete error:', e);
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
            let { _user, companyTypes } = {
                ...req.body,
            };

            const result = await companyType.bulkInsert(companyTypes, _user?.id || 1);
            
            res.status(200).json({
                message: 'success',
                status: 200,
                data: result.rows[0].add_new_company_types
            });

        } catch (e) {
            console.error('Company type bulk insert error:', e);
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