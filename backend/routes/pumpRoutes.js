const express = require('express');
const router = express.Router();
const pumpController = require('../controllers/pumpController');

// GET status pompa terbaru
router.get('/latest', pumpController.getLatestPumpStatus);

// POST untuk set mode pompa (auto/manual)
router.post('/set-mode', pumpController.setPumpMode);

module.exports = router;