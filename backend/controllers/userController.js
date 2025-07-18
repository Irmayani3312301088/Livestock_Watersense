const User = require('../models/userModel');
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Konfigurasi multer untuk upload foto
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/profiles/';
    
    // Buat direktori jika belum ada
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Hanya file gambar yang diizinkan!'));
    }
  }
});

// GET semua user
const getAllUsers = async (req, res) => {
  try {
    const users = await User.findAll({ 
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']]
    });
    res.json({ success: true, data: users });
  } catch (err) {
    console.error('Get All Users Error:', err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data pengguna.' });
  }
};

// GET user by ID
const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByPk(id, { 
      attributes: { exclude: ['password'] }
    });
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
    }
    
    res.json({ success: true, data: user });
  } catch (err) {
    console.error('Get User By ID Error:', err);
    res.status(500).json({ success: false, message: 'Gagal mengambil data pengguna.' });
  }
};

// CREATE user by admin 
const createUserByAdmin = async (req, res) => {
  try {
    let { name, username, email, role = 'peternak', password } = req.body;
role = role.toLowerCase();
    const adminId = req.user?.id; 

    console.log('Create User Request Body:', req.body);
    console.log('Create User File:', req.file);

    if (!name || !email) {
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(400).json({
        success: false,
        message: 'Nama dan email wajib diisi.'
      });
    }

    // Validasi email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(400).json({
        success: false,
        message: 'Format email tidak valid.'
      });
    }

    // Cek email sudah ada
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(400).json({
        success: false,
        message: 'Email sudah digunakan.'
      });
    }

    // Cek username
    if (username) {
      const existingUsername = await User.findOne({ where: { username } });
      if (existingUsername) {
        if (req.file && fs.existsSync(req.file.path)) {
          fs.unlinkSync(req.file.path);
        }
        return res.status(400).json({
          success: false,
          message: 'Username sudah digunakan.'
        });
      }
    }

    // Validasi dan hash password
    if (!password || password.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Kata Sandi wajib diisi minimal 8 karakter.'
      });
    }
    const hashedPassword = await bcrypt.hash(password, 10);

    const profileImage = req.file ? req.file.filename : null;

    const newUser = await User.create({
      name,
      username: username || null,
      email,
      password: hashedPassword, 
      role,
      profile_image: profileImage,
      status: 'pending',
      created_by_admin: adminId || null
    });

    res.status(201).json({
      success: true,
      message: 'User berhasil ditambahkan.',
      data: {
        id: newUser.id,
        name: newUser.name,
        username: newUser.username,
        email: newUser.email,
        role: newUser.role,
        status: newUser.status,
        profile_image: newUser.profile_image
      }
    });
  } catch (err) {
    console.error('Create User Error:', err);
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ success: false, message: 'Gagal menambah pengguna.' });
  }
};


// UPDATE user
const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, username, email, role } = req.body;
    

    const user = await User.findByPk(id);
    if (!user) {
      // Hapus file yang sudah diupload jika ada error
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
    }

    // Check email uniqueness
    if (email && email !== user.email) {
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        if (req.file && fs.existsSync(req.file.path)) {
          fs.unlinkSync(req.file.path);
        }
        return res.status(400).json({
          success: false,
          message: 'Email sudah digunakan.'
        });
      }
    }

    // Check username uniqueness
    if (username && username !== user.username) {
      const existingUsername = await User.findOne({ where: { username } });
      if (existingUsername) {
        if (req.file && fs.existsSync(req.file.path)) {
          fs.unlinkSync(req.file.path);
        }
        return res.status(400).json({
          success: false,
          message: 'Username sudah digunakan.'
        });
      }
    }

    const updateData = { name, username, email, role };
    
    if (req.file) {
      // Hapus gambar lama jika ada
      if (user.profile_image) {
        const oldImagePath = path.join('uploads/profiles/', user.profile_image);
        if (fs.existsSync(oldImagePath)) {
          fs.unlinkSync(oldImagePath);
        }
      }
      updateData.profile_image = req.file.filename;
    }

    await user.update(updateData);

    res.json({ 
      success: true, 
      message: 'Data pengguna berhasil diperbarui.',
      data: {
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
        role: user.role,
        profile_image: user.profile_image
      }
    });
  } catch (err) {
    console.error('Update User Error:', err);
    
    // Hapus file yang sudah diupload jika ada error
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    
    res.status(500).json({ success: false, message: 'Gagal update pengguna.' });
  }
};

// DELETE user
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    // Tambahkan logging ID
    console.log('DELETE request masuk, ID:', id);

    const user = await User.findByPk(id);

    if (!user) {
      return res.status(404).json({ success: false, message: 'Pengguna tidak ditemukan.' });
    }

    // Hapus foto profil jika ada
    if (user.profile_image) {
      const imagePath = path.join('uploads/profiles/', user.profile_image);
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }
    }

    await user.destroy();

    return res.json({ success: true, message: 'Pengguna berhasil dihapus.' });

  } catch (err) {
    // Tambahkan log error detail
    console.error('Delete User Error:', err);
    return res.status(500).json({ success: false, message: 'Gagal hapus pengguna.' });
  }
};



// ADDED: Check email exists
const checkEmailExists = async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email wajib diisi.'
      });
    }

    const existingUser = await User.findOne({ where: { email } });
    
    res.json({
      success: true,
      exists: !!existingUser,
      message: existingUser ? 'Email sudah digunakan.' : 'Email tersedia.'
    });
  } catch (err) {
    console.error('Check Email Error:', err);
    res.status(500).json({ success: false, message: 'Gagal mengecek email.' });
  }
};

// ADDED: Check username exists
const checkUsernameExists = async (req, res) => {
  try {
    const { username } = req.body;
    
    if (!username) {
      return res.status(400).json({
        success: false,
        message: 'Username wajib diisi.'
      });
    }

    const existingUser = await User.findOne({ where: { username } });
    
    res.json({
      success: true,
      exists: !!existingUser,
      message: existingUser ? 'Username sudah digunakan.' : 'Username tersedia.'
    });
  } catch (err) {
    console.error('Check Username Error:', err);
    res.status(500).json({ success: false, message: 'Gagal mengecek username.' });
  }
};

// Admin aktivasi user
const activateUser = async (req, res) => {
  try {
    const { id } = req.body;

    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Pengguna tidak ditemukan.' });
    }

    await user.update({ status: 'active' });

    return res.status(200).json({ success: true, message: 'Pengguna berhasil diaktifkan.' });
  } catch (error) {
    console.error('Activate User Error:', error.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

module.exports = { 
  getAllUsers, 
  getUserById,
  createUserByAdmin, 
  updateUser, 
  deleteUser,
  checkEmailExists,
  checkUsernameExists,
  upload,
  activateUser,
};