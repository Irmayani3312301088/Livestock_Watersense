const express = require('express');
const router = express.Router();
const batasAirController = require('../controllers/batasAirController');

router.post('/', batasAirController.updateBatasAir);           // POST: tambah/update
router.get('/:device_id', batasAirController.getBatasAir);     // GET: ambil per device

module.exports = router;
