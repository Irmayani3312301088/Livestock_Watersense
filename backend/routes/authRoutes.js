const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { verifyToken } = require('../middleware/authMiddleware');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/create-admin', authController.createAdmin);
router.post('/self-register', authController.selfRegister);


router.get('/profile', verifyToken, async (req, res) => {
  res.json({ success: true, data: req.user });
});

module.exports = router;
