const express = require('express');
const router = express.Router();
const pumpController = require('../controllers/pumpController');

// GET status pompa terbaru
router.get('/latest', pumpController.getLatestPumpStatus);

// 🚫 Hapus router.post jika belum dipakai
// router.post('/', ...)

module.exports = router;
