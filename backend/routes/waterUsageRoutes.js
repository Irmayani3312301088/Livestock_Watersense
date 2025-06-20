const express = require('express');
const router = express.Router();
const controller = require('../controllers/waterUsageController');

router.post('/', controller.sendWaterUsage);
router.get('/history', controller.getDailyUsageHistory);
router.get('/today', controller.getTodayUsage);

module.exports = router;
