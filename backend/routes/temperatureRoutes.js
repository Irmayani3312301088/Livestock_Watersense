const express = require('express');
const router = express.Router();
const temperatureController = require('../controllers/temperatureController');

router.post('/', temperatureController.sendTemperature);
router.get('/latest', temperatureController.getLatestTemperature);

module.exports = router;
