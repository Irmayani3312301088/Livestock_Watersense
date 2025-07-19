// backend/config/config.js

require('dotenv').config(); // Pastikan variabel dari Railway terbaca

module.exports = {
  development: {
    username: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || null,
    database: process.env.DB_NAME || "livestock_db",
    host: process.env.DB_HOST || "127.0.0.1",
    dialect: "mysql"
  },
  test: {
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    dialect: "mysql"
  },
  production: {
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: "mysql",
    dialectOptions: {
      // Opsi ini mungkin diperlukan untuk koneksi di platform cloud
      ssl: {
        require: true,
        rejectUnauthorized: false
      }
    }
  }
};