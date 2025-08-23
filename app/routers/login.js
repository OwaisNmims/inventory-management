const express = require('express');
const router = express.Router()
const loginController = require('../controllers/loginController');
const indexController = require('../controllers/indexController');
// const {
//     validate
// } = require("../utils/index")

router.get('/', indexController.getPage)
router.get('/login', loginController.login);
router.post('/authenticate', loginController.Authenticate);

module.exports = router;