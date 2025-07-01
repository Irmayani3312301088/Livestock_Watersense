const User = require('../models/user.model');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');

// GET: Ambil data profil user yang login
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: ['id', 'name', 'username', 'email', 'role', 'profile_image']
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
    }

    res.json({ success: true, data: user });
  } catch (err) {
    console.error("Gagal mengambil profile:", err);
    res.status(500).json({ success: false, message: 'Gagal mengambil profil.', error: err.message });
  }
};

// PUT: Update profil user yang login
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, email, username, role, password } = req.body;

    const user = await User.findByPk(userId);
    if (!user) {
      if (req.file) fs.existsSync(req.file.path) && fs.unlinkSync(req.file.path);
      return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
    }

    // Cek duplikasi email
    if (email && email !== user.email) {
      const emailExists = await User.findOne({ where: { email } });
      if (emailExists) {
        if (req.file) fs.existsSync(req.file.path) && fs.unlinkSync(req.file.path);
        return res.status(400).json({ success: false, message: 'Email sudah digunakan.' });
      }
    }

    // Cek duplikasi username
    if (username && username !== user.username) {
      const usernameExists = await User.findOne({ where: { username } });
      if (usernameExists) {
        if (req.file) fs.existsSync(req.file.path) && fs.unlinkSync(req.file.path);
        return res.status(400).json({ success: false, message: 'Username sudah digunakan.' });
      }
    }

    const updatedData = { name, email, username, role };

    if (password) {
      updatedData.password = await bcrypt.hash(password, 10);
    }

    if (req.file) {
      if (user.profile_image) {
        const oldPath = path.join('uploads/profiles/', user.profile_image);
        fs.existsSync(oldPath) && fs.unlinkSync(oldPath);
      }
      updatedData.profile_image = req.file.filename;
    }

    await user.update(updatedData);

    res.json({
      success: true,
      message: 'Profil berhasil diperbarui.',
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        username: user.username,
        role: user.role,
        profile_image: user.profile_image,
      }
    });
  } catch (err) {
    if (req.file) fs.existsSync(req.file.path) && fs.unlinkSync(req.file.path);
    console.error("Gagal update profil:", err);
    res.status(500).json({ success: false, message: 'Gagal update profil.', error: err.message });
  }
};
