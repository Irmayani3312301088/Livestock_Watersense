const { Sequelize } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
  process.env.DB_NAME || 'livestock_db',
  process.env.DB_USER || 'root',
  process.env.DB_PASSWORD || '',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    pool: { max: 5, min: 0, acquire: 30000, idle: 10000 },
    define: { timestamps: true, underscored: false, freezeTableName: true },
    dialectOptions: { charset: 'utf8mb4', multipleStatements: true },
    retry: {
      match: [
        /ETIMEDOUT/, /EHOSTUNREACH/, /ECONNRESET/, /ECONNREFUSED/,
        /ESOCKETTIMEDOUT/, /EPIPE/, /EAI_AGAIN/, /ER_CON_COUNT_ERROR/
      ],
      max: 3
    }
  }
);

async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log(' Koneksi database telah berhasil dibuat.');
    return true;
  } catch (error) {
    console.error(' Tidak dapat tersambung ke database:', error.message);
    return false;
  }
}

module.exports = { sequelize, testConnection };