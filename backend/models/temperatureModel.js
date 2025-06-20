const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Temperature = sequelize.define('Temperature', {
  device_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  temperature: {
    type: DataTypes.FLOAT,
    allowNull: false,
  },
  status: {
    type: DataTypes.STRING,
  },
  note: {
    type: DataTypes.STRING,
  },
}, {
  tableName: 'temperature_logs',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = Temperature;
