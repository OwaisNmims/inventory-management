const express = require("express");
const router = express.Router();

//import controllers
const adminController = require('../controllers/adminController')
const indexController = require('../controllers/indexController');
const countryMasterController = require('../controllers/countryMasterController');
const stateMasterController = require('../controllers/stateMasterController');
const tourController = require('../controllers/tourController');
const city = require('../controllers/city');
const modeOfTransport = require('../controllers/modeOfTransport');
const carrier = require('../controllers/carrier');
const expense = require('../controllers/expense');
const currency = require('../controllers/currency');
const passenger = require('../controllers/passenger');
const hotel = require('../controllers/hotel');
const fareClass =  require('../controllers/fareClass');
const invoice = require('../controllers/invoice');
const costSheet =  require('../controllers/costSheet');
const tax = require('../controllers/tax')
const tourPax =  require('../controllers/tourPassenger');
const tourExpense =  require('../controllers/tourExpenses');
const userController =  require('../controllers/userController');
const tourTax = require("../controllers/tourTax.js");
const company = require('../controllers/company');
const companyType = require('../controllers/companyType');
const product = require('../controllers/product');
const productCompanyMapping = require('../controllers/productCompanyMapping');
// const {
//     validate
// } = require("../utils/index")

// router.get('/cost-sheet', indexController.getPage)

// router.get('/mode-of-transport', adminController.modeOfTransport);


router.get('/dashboard', adminController.dashboard);



router.get('/masters', adminController.masterDashboard);
router.get('/room-type', adminController.roomTypeMaster);


// COUNTRY PAGE CRUD OPERATION
router.get('/country', adminController.countryMaster);
router.post('/country/add', countryMasterController.addNewCountry);
router.get('/country/search', countryMasterController.searchCountry);
router.post('/country/edit', countryMasterController.editCountry);
router.post('/country/delete', countryMasterController.disableCountry);

// State PAGE CRUD OPERATION
router.get('/state', adminController.stateMaster);
router.get('/state/find-by-country', stateMasterController.findByCountry);
router.post('/state/add', stateMasterController.addNewState);
// router.get('/contry-search', countryMasterController.searchCountry);
router.post('/state/edit', stateMasterController.editState);
router.post('/state/delete', stateMasterController.disableState);

//City page CRUD OPERATION
router.get('/city', city.cityMaster);
router.post('/city/add', city.insert)
router.post('/city/update', city.updateCity);
router.post('/city/delete', city.deleteCity);

//Company page CRUD OPERATION
router.get('/company', company.companyMaster);
router.post('/company/insert', company.insert);
router.post('/company/update', company.updateCompany);
router.post('/company/delete', company.deleteCompany);
router.post('/company/bulk-insert', company.bulkInsert);

//Company Type page CRUD OPERATION
router.get('/company-type', companyType.companyTypeMaster);
router.post('/company-type/insert', companyType.insert);
router.post('/company-type/update', companyType.updateCompanyType);
router.post('/company-type/delete', companyType.deleteCompanyType);
router.post('/company-type/bulk-insert', companyType.bulkInsert);

//Product page CRUD OPERATION
router.get('/product', product.productMaster);
router.get('/product/:productId', product.getProductById);
router.post('/product/insert', product.insert);
router.post('/product/update', product.updateProduct);
router.post('/product/delete', product.deleteProduct);

//Product Company Mapping page CRUD OPERATION
router.get('/product-company-mapping', productCompanyMapping.productCompanyMappingMaster);
router.post('/product-company-mapping/create', productCompanyMapping.createMapping);
router.post('/product-company-mapping/bulk-create', productCompanyMapping.bulkMapProducts);
router.get('/product-company-mapping/availability/:productId', productCompanyMapping.getProductAvailability);
router.get('/product-company-mapping/receipts', productCompanyMapping.getMappingReceipts);
router.post('/product-company-mapping/update-label', productCompanyMapping.updateMappingLabel);
router.post('/product-company-mapping/delete', productCompanyMapping.deleteMapping);
router.post('/product-company-mapping/transfer', productCompanyMapping.transferProduct);
router.get('/product-company-mapping/by-company', productCompanyMapping.getMappingsByCompany);
router.post('/product-company-mapping/record-sales', productCompanyMapping.recordSales);

// Receipts page and data integrity
router.get('/receipts', productCompanyMapping.receiptsPage);
router.get('/data-integrity/validate-mappings', productCompanyMapping.validateDataIntegrity);

// Currency PAGE CRUD OPERATION
router.get('/currency', currency.currencyMaster);
router.get('/currency/getAll', currency.currencyMaster);
router.post('/currency/add', currency.insert);
router.post('/currency/update',currency.updateCurrency);
router.post('/currency/delete',currency.deleteCurrency);

// expense PAGE CRUD OPERATION
router.post('/add-new-expense', countryMasterController.addNewCountry);
router.get('/expense-search', countryMasterController.searchCountry);
router.post('/edit-expense', countryMasterController.editCountry);
router.post('/disable-expense', countryMasterController.disableCountry);

// Mode of transport 
router.get('/mode-of-transport', modeOfTransport.getModeOfTransports);
router.post('/mode-of-transport/add', modeOfTransport.insert);
router.post('/mode-of-transport/update', modeOfTransport.updateMode);
router.post('/mode-of-transport/delete', modeOfTransport.deleteMode);

// Tour PAGE routes
router.get('/tour', tourController.tourDashboard);
router.get('/tour/create', tourController.createTourPage);
router.post('/tour/create', tourController.create);
router.post('/tour/update', tourController.update);
router.get('/tour/edit-details/:tourId', tourController.editDetails);
router.get('/tour/generate/:tourId', tourController.tourInvoice);
router.post('/tour/delete', tourController.delete);
// Carrier
router.get('/carrier', carrier.getCarriers);
router.post('/carrier/add', carrier.insert);
router.post('/carrier/update', carrier.updateCarrier);
router.post('/carrier/delete', carrier.deleteCarrier);


//Expenses
router.get('/expenses', expense.expensesMaster);
router.get('/expenses/getAll', expense.getAll);
router.post('/expenses/add', expense.add);
router.post('/expenses/add-single', expense.addSingle);
router.post('/expenses/update', expense.update);
router.post('/expenses/delete', expense.delete);

//Passenger
router.get('/passenger', passenger.passengerMaster);
router.post('/passenger/add', passenger.add);
router.post('/passenger/update', passenger.update);
router.post('/passenger/delete', passenger.delete);

//Hotel
router.get('/hotels', hotel.hotelMaster);



//fare class
router.get('/fare-class', fareClass.getFareClass);
router.post('/fare-class/add', fareClass.insert);
router.post('/fare-class/update', fareClass.updateFareClass);
router.post('/fare-class/delete', fareClass.deleteFareClas);

//Cost Sheet
router.get('/cost-sheet', costSheet.renderCostSheets);
router.get('/cost-sheet/generator', costSheet.renderCostSheetGenerator);
router.post('/cost-sheet/margin', costSheet.addMargin)
// tax
router.get('/tax', tax.getAllTaxes);
router.post('/tax/add', tax.insert);
router.post('/tax/update', tax.updateTax);
router.post('/tax/delete', tax.deleteTax);

// invoice
router.get('/invoice', invoice.getAllTaxesForInvoice);
//Tour Passenger Details
router.post('/tour-pax/add', tourPax.add);
router.post('/tour-pax/update', tourPax.update);
router.post('/tour-pax/delete', tourPax.delete);

//Tour Expenses
router.post('/tour-expense/add', tourExpense.add);
router.post('/tour-expense/update', tourExpense.update);
router.post('/tour-expense/delete', tourExpense.delete);
//Tour Expenses

// Tour Tax
router.post('/tour-tax/add', tourTax.add);
router.post('/tour-tax/delete', tourExpense.delete);

router.post('/tour-taxes/delete', tourTax.delete);
//Users
router.get('/users', userController.getAllUsers);


module.exports = router;