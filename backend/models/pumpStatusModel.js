const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const PumpStatus = sequelize.define('PumpStatus', {
  device_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  status: {
    type: DataTypes.STRING,
    allowNull: false
  },
  mode: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'auto'
  }
}, {
  tableName: 'pump_status',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false
});

module.exports = PumpStatus;
