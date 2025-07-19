const { Sequelize, DataTypes } = require('sequelize');
require('dotenv').config();

// Konfigurasi dasar
const dbConfig = {
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  dialect: 'mysql',
  logging: false, // Sebaiknya matikan logging SQL di produksi
  pool: { max: 5, min: 0, acquire: 30000, idle: 10000 }
};

// Tambahkan opsi SSL HANYA untuk lingkungan produksi (di Railway)
if (process.env.NODE_ENV === 'production') {
  dbConfig.dialectOptions = {
    ssl: {
      require: true,
      rejectUnauthorized: false // Opsi ini penting untuk Railway
    }
  };
}

const sequelize = new Sequelize(
  dbConfig.database,
  dbConfig.username,
  dbConfig.password,
  dbConfig
);

// Model import (jika ada di sini)
const OtpToken = require('../models/OtpToken')(sequelize, DataTypes);

async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log('✅ Koneksi database berhasil dibuat.');
    return true;
  } catch (error) {
    console.error('❌ Tidak dapat tersambung ke database:', error.message);
    // Tampilkan error yang lebih detail untuk debugging
    console.error('Detail Error:', error);
    return false;
  }
}

module.exports = {
  sequelize,
  testConnection,
  OtpToken
};