const express = require('express');
const router = express.Router();
const manualPumpController = require('../controllers/manualPumpController');

// Kirim log konfirmasi pompa manual
router.post('/manual-pump', manualPumpController.konfirmasiPompaManual);

// Ambil histori log
router.get('/manual-pump/logs', manualPumpController.getLogPompaManual);

// Ambil status pompa sekarang
router.get('/status-pompa', manualPumpController.getStatusPompa);

// Ubah status pompa (on/off)
router.post('/ubah-status-pompa', manualPumpController.ubahStatusPompa);

// Ambil data level air terbaru
router.get('/level-air-terakhir', manualPumpController.getLevelAirTerakhir);

module.exports = router;
