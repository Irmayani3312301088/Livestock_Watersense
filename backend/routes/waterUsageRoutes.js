const express = require('express');
const router = express.Router();
const controller = require('../controllers/waterUsageController');

router.post('/', controller.sendWaterUsage);
router.get('/today', controller.getTodayUsage);
router.get('/history', controller.getDailyUsageHistory);

module.exports = router;
