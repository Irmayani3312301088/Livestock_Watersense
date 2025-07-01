const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

const SECRET_KEY = process.env.JWT_SECRET || 'default-secret-key';

// Self-register (pengguna daftar langsung tanpa dibuatkan admin)
const selfRegister = async (req, res) => {
  try {
    const { name, username, email, password } = req.body;

    if (!name || !username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Semua field wajib diisi.',
      });
    }

    const existingEmail = await User.findOne({ where: { email } });
    if (existingEmail) {
      return res.status(400).json({
        success: false,
        message: 'Email sudah digunakan.',
      });
    }

    const existingUsername = await User.findOne({ where: { username } });
    if (existingUsername) {
      return res.status(400).json({
        success: false,
        message: 'Username sudah digunakan.',
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await User.create({
      name,
      username,
      email,
      password: hashedPassword,
      role: null,              // Admin akan atur nanti
      status: 'pending',       // Belum aktif sampai diset admin
    });

    return res.status(201).json({
      success: true,
      message: 'Registrasi berhasil. Tunggu persetujuan admin.',
      data: {
        user: {
          id: newUser.id,
          name: newUser.name,
          username: newUser.username,
          email: newUser.email,
          role: newUser.role,
          status: newUser.status,
        }
      },
    });
  } catch (error) {
    console.error('Self Register Error:', error.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// Register untuk user yang sudah ditambahkan admin
const register = async (req, res) => {
  try {
    const { email, password, username } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password wajib diisi.',
      });
    }

    // Cari user yang dibuat admin dengan status pending
    const user = await User.findOne({ 
      where: { 
        email, 
        status: 'pending',
        password: null // Belum ada password
      } 
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Email tidak ditemukan atau sudah terdaftar. Hubungi admin.',
      });
    }

    // Update username jika ada dan belum diset
    if (username && !user.username) {
      const existingUsername = await User.findOne({ where: { username } });
      if (existingUsername) {
        return res.status(400).json({
          success: false,
          message: 'Username sudah digunakan.',
        });
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await user.update({
      password: hashedPassword,
      username: username || user.username,
      status: 'active'
    });

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      SECRET_KEY,
      { expiresIn: '1d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Registrasi berhasil.',
      data: {
        user: {
          id: user.id,
          name: user.name,
          username: user.username,
          email: user.email,
          role: user.role,
          profile_image: user.profile_image
        },
        token,
      },
    });
  } catch (error) {
    console.error('Register Error:', error.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// Login
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password wajib diisi.',
      });
    }

    const user = await User.findOne({ 
      where: { 
        email,
        status: 'active' // Hanya user yang sudah register
      } 
    });

    if (!user || !user.password) {
      return res.status(404).json({
        success: false,
        message: 'Akun tidak ditemukan atau belum terdaftar.',
      });
    }

    console.log('Input password:', password);
    console.log('DB hashed password:', user.password);

const isMatch = await bcrypt.compare(password, user.password);
console.log('Password match result:', isMatch);

if (!isMatch) {
  return res.status(401).json({
    success: false,
    message: 'Password salah.',
  });
}

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      SECRET_KEY,
      { expiresIn: '1d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Login berhasil.',
      data: {
        user: {
          id: user.id,
          name: user.name,
          username: user.username,
          email: user.email,
          role: user.role,
          profile_image: user.profile_image
        },
        token,
      },
    });
  } catch (error) {
    console.error('Login Error:', error.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

// Create Admin (untuk setup awal)
const createAdmin = async (req, res) => {
  try {
    const { name, email, password, username } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Semua field wajib diisi.',
      });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Email sudah digunakan.',
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newAdmin = await User.create({
      name,
      username,
      email,
      password: hashedPassword,
      role: 'admin',
      status: 'active'
    });

    return res.status(201).json({
      success: true,
      message: 'Admin berhasil dibuat.',
      data: {
        id: newAdmin.id,
        name: newAdmin.name,
        username: newAdmin.username,
        email: newAdmin.email,
        role: newAdmin.role,
      },
    });
  } catch (error) {
    console.error('Create Admin Error:', error.message);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};

module.exports = {
  register,
  login,
  createAdmin,
  selfRegister,
 
};
