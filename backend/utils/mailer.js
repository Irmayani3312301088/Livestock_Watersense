const nodemailer = require('nodemailer');

// DEBUG CEK ENV
console.log('SMTP Email:', process.env.EMAIL_USER);
console.log('SMTP Pass:', process.env.EMAIL_PASS ? 'Loaded' : 'Missing');

// Setup transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Kirim email OTP
async function sendOtpEmail(to, otp) {
  const mailOptions = {
    from: `"Livestock App" <${process.env.EMAIL_USER}>`,
    to,
    subject: 'Kode OTP Reset Password',
    text: `Berikut kode OTP Anda: ${otp}\nKode ini berlaku selama 5 menit.`
  };

  await transporter.sendMail(mailOptions);
}

module.exports = sendOtpEmail;
