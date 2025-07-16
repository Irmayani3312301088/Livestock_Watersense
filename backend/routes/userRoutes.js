const express = require('express');
const router = express.Router();
const {
  getAllUsers,
  getUserById,
  createUserByAdmin,
  updateUser,
  deleteUser,
  checkEmailExists,
  checkUsernameExists,
  upload,
  activateUser
} = require('../controllers/userController');

const { verifyToken } = require('../middleware/authMiddleware');
const isAdmin = require('../middleware/adminMiddleware');

// GET all users
router.get('/', getAllUsers);

// GET user by ID
router.get('/:id', getUserById);

// POST create user by admin
router.post(
  '/',
  verifyToken,
  isAdmin,
  upload.single('profile_image'),
  createUserByAdmin
);

// PUT update user
router.put(
  '/:id',
  verifyToken,
  isAdmin,
  upload.single('profile_image'),
  updateUser
);

// DELETE user (1x saja, jangan ganda)
router.delete('/:id', verifyToken, deleteUser);

// Check email & username
router.post('/check-email', checkEmailExists);
router.post('/check-username', checkUsernameExists);

// Aktivasi user oleh admin
router.post('/activate-user', verifyToken, activateUser);

console.log('[Router] userRoutes.js loaded');

module.exports = router;
