const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

const SECRET_KEY = process.env.JWT_SECRET;

if (!SECRET_KEY) {
  console.warn('livestock-secret-2024');
}

const verifyToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided or wrong format.',
      });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, SECRET_KEY);

    const user = await User.findByPk(decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. User not found.',
      });
    }

    // Tambahkan role agar bisa dicek di isAdmin
    req.user = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role, 
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired.' });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, message: 'Invalid token.' });
    }

    console.error(' Auth Middleware Error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = { verifyToken };
