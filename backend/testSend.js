require('dotenv').config();
const sendEmail = require('./utils/sendEmail');

sendEmail('alamatemailmu@gmail.com', 'Test Kirim OTP', 'Ini email tes OTP')
  .then(() => console.log('Email berhasil dikirim!'))
  .catch(err => console.error('Gagal kirim email:', err));
