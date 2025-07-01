const express = require('express');
const router = express.Router();
const batasAirController = require('../controllers/batasAirController');

router.get('/:device_id', batasAirController.getBatasAir);
router.post('/', batasAirController.saveBatasAir);

module.exports = router;