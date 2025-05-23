const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('livestock_db', 'root', '', {
  host: 'localhost',
  dialect: 'mysql',
  // Hapus opsi SSL karena MySQL lokal tidak mendukungnya
  // dialectOptions: { ... } -> hanya digunakan jika MySQL mendukung SSL
});

// Test the connection
async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log('Connection to database has been established successfully.');
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
}

testConnection();

module.exports = sequelize;
