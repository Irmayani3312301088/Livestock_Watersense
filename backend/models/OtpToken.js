const { sequelize, DataTypes } = require('../config/database');

const OtpToken = sequelize.define('OtpToken', {
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
  used: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
}, {
  tableName: 'otp_tokens',
  timestamps: true,
});

module.exports = OtpToken;
