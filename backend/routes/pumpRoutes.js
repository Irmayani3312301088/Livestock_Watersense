const express = require('express');
const router = express.Router();
const pumpController = require('../controllers/pumpController');

router.post('/manual', pumpController.setManualPumpStatus);
router.get('/latest', pumpController.getLatestPumpStatus);

module.exports = router;
