const express = require('express');
const router = express.Router();
const waterLevelController = require('../controllers/waterLevelController');

// POST → Simpan data level air dari ESP
router.post('/', waterLevelController.sendWaterLevel);

// GET → Ambil data level air terbaru untuk aplikasi
router.get('/latest', waterLevelController.getLatestWaterLevel);

module.exports = router;
