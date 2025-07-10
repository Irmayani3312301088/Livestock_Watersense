const express = require('express');
const router = express.Router();
const temperatureController = require('../controllers/temperatureController');

// POST /api/temperature
router.post('/', temperatureController.storeTemperature);

// GET /api/temperature/latest
router.get('/latest', temperatureController.getLatestTemperature);

module.exports = router;
