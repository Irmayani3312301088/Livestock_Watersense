const User = require('../models/userModel');
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

    // Siapkan data yang akan diupdate
    const updatedData = { name, email, username, role };

    // Jika password diisi, hash dulu
    if (password) {
      updatedData.password = await bcrypt.hash(password, 10);
    }

    // Jika ada file baru, hapus yang lama lalu simpan yang baru
    if (req.file) {
      if (user.profile_image) {
        const oldPath = path.join('uploads/profiles/', user.profile_image);
        fs.existsSync(oldPath) && fs.unlinkSync(oldPath);
      }
      updatedData.profile_image = req.file.filename;
    }

    // Update data user
    await user.update(updatedData);

    // Fetch ulang data user yang telah diperbarui
    const updatedUser = await User.findByPk(userId);

    // Kirim response
    res.json({
      success: true,
      message: 'Profil berhasil diperbarui.',
      data: {
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        username: updatedUser.username,
        role: updatedUser.role,
        profile_image: updatedUser.profile_image,
      }
    });

  } catch (err) {
    if (req.file) fs.existsSync(req.file.path) && fs.unlinkSync(req.file.path);
    console.error("Gagal update profil:", err);
    return res.status(500).json({
      success: false,
      message: 'Gagal update profil.',
      error: err.message
    });
  }
};
