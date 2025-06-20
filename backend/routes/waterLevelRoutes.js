const express = require('express');
const router = express.Router();
const waterLevelController = require('../controllers/waterLevelController');

router.post('/', waterLevelController.sendWaterLevel);
router.get('/latest', waterLevelController.getLatestWaterLevel);

module.exports = router;
