const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const WaterUsage = sequelize.define('WaterUsage', {
  device_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  usage_ml: {
    type: DataTypes.FLOAT,
    allowNull: false,
  },
  date: {
  type: DataTypes.DATEONLY,
  allowNull: false,
  defaultValue: sequelize.literal('CURDATE()'),
},

}, {
  tableName: 'water_usages',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = WaterUsage;
