const { sequelize } = require('../config/database');
const bcrypt = require('bcrypt');
const generateOtp = require('../utils/generateOtp');
const sendEmail = require('../utils/sendEmail');

// Pakai model langsung
const User = require('../models/userModel');
const OtpToken = require('../models/OtpToken');

// --------------------
// Kirim OTP ke email
// --------------------
exports.sendOtp = async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Email tidak terdaftar',
      });
    }

    const otp = generateOtp();
    const expires = new Date(Date.now() + 10 * 60 * 1000); // 10 menit

    console.log(`✅ OTP: ${otp} untuk ${email}`);

    await OtpToken.create({ email, otp, expires_at: expires });
    console.log(`✅ Kirim OTP ke: ${email}, kode OTP: ${otp}`);

    await sendEmail(email, 'Kode OTP Reset Password', `Kode OTP kamu: ${otp}`);

    res.json({ success: true, message: 'OTP berhasil dikirim ke email' });

  } catch (err) {
    console.error('❌ Gagal kirim OTP:', err.message);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan saat mengirim OTP',
      error: err.message
    });
  }
};

// ------------------------
// Verifikasi OTP & Reset Password
// ------------------------
exports.resetPassword = async (req, res) => {
  const { email, otp, newPassword } = req.body;

  try {
    const token = await OtpToken.findOne({
      where: {
        email,
        otp,
        used: false,
        expires_at: { [sequelize.Sequelize.Op.gt]: new Date() },
      },
      order: [['createdAt', 'DESC']],
    });

    if (!token) {
      console.log(`❌ OTP tidak valid/kadaluarsa untuk email: ${email}, otp: ${otp}`);
      return res.status(400).json({
        success: false,
        message: 'OTP tidak valid atau sudah kadaluarsa',
      });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await User.update({ password: hashedPassword }, { where: { email } });

    token.used = true;
    await token.save();

    console.log(`✅ Password berhasil direset untuk ${email}`);
    res.json({ success: true, message: 'Password berhasil direset' });

  } catch (err) {
    console.error('❌ Gagal reset password:', err.message);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan saat reset password',
      error: err.message
    });
  }
};
