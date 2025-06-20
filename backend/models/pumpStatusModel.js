const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const PumpStatus = sequelize.define('PumpStatus', {
  device_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  mode: {
    type: DataTypes.ENUM('auto', 'manual'),
    defaultValue: 'auto',
  },
  status: {
    type: DataTypes.ENUM('on', 'off'),
    allowNull: false,
  },
}, {
  tableName: 'pump_status',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = PumpStatus;
