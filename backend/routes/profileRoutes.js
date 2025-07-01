const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { verifyToken } = require('../middleware/authMiddleware');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const User = require('../models/user.model'); 

// Konfigurasi penyimpanan gambar profil
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = 'uploads/profiles/';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const unique = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'profile-' + unique + ext);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // Maks 5MB
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png/;
    const validExt = allowed.test(path.extname(file.originalname).toLowerCase());
    const validMime = allowed.test(file.mimetype);
    if (validExt && validMime) cb(null, true);
    else cb(new Error('Hanya file JPEG, JPG, atau PNG yang diperbolehkan.'));
  }
});

//  GET /api/profile
router.get('/', verifyToken, profileController.getProfile);

//  PUT /api/profile
router.put('/', verifyToken, upload.single('profile_image'), profileController.updateProfile);

//  DELETE /api/profile/photo
router.delete('/photo', verifyToken, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }

    // Hapus file foto jika ada
    if (user.profile_image) {
      const filePath = path.join(__dirname, '../uploads/profiles', user.profile_image);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }

    user.profile_image = null;
    await user.save();

    return res.json({ success: true, message: 'Foto profil berhasil dihapus' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Gagal menghapus foto profil' });
  }
});

module.exports = router;
