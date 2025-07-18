const { OtpToken, sequelize } = require('../config/database');
const generateOtp = require('../utils/generateOtp');
const sendEmail = require('../utils/sendEmail');
const bcrypt = require('bcrypt');

exports.sendOtp = async (req, res) => {
  const { email } = req.body;

  const user = await sequelize.models.User.findOne({ where: { email } });
  if (!user) return res.status(404).json({ success: false, message: 'Email tidak terdaftar' });

  const otp = generateOtp();
  const expires = new Date(Date.now() + 10 * 60 * 1000); // 10 menit dari sekarang

  await OtpToken.create({ email, otp, expires_at: expires });

  try {
    await sendEmail(email, 'Kode OTP Reset Password', `Kode OTP kamu: ${otp}`);
    res.json({ success: true, message: 'OTP berhasil dikirim ke email' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Gagal kirim email', error: err.message });
  }
};

exports.resetPassword = async (req, res) => {
  const { email, otp, newPassword } = req.body;

  const token = await OtpToken.findOne({
    where: {
      email,
      otp,
      used: false,
      expires_at: { [sequelize.Sequelize.Op.gt]: new Date() },
    },
    order: [['createdAt', 'DESC']],
  });

  if (!token) return res.status(400).json({ success: false, message: 'OTP tidak valid atau kadaluarsa' });

  const hashed = await bcrypt.hash(newPassword, 10);
  await sequelize.models.User.update({ password: hashed }, { where: { email } });

  token.used = true;
  await token.save();

  res.json({ success: true, message: 'Password berhasil direset' });
};
