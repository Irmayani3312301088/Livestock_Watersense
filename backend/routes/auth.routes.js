const express = require('express');
const router = express.Router();
const auth = require('../controllers/auth.controller');

app.post('/register', authController.register);
app.post('/login', authController.login);

module.exports = router;
