const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const PasswordReset = sequelize.define('PasswordReset', {
  email: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  otp: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  expires_at: {
    type: DataTypes.DATE,
    allowNull: false,
  },
}, {
  tableName: 'password_resets',
  timestamps: true,
});

module.exports = PasswordReset;
