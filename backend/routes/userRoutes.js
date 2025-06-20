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
router.post('/', upload.single('profile_image'), createUserByAdmin);

// PUT update user
router.put('/:id', upload.single('profile_image'), updateUser);

// DELETE user
router.delete('/:id', deleteUser);

// POST check email exists
router.post('/check-email', checkEmailExists);

// POST check username exists
router.post('/check-username', checkUsernameExists);

// POST activate user
console.log('[Router] userRoutes.js loaded');
router.post('/activate-user', (req, res, next) => {
  console.log('Route HIT: POST /api/users/activate-user');
  next();
}, activateUser);



module.exports = router;