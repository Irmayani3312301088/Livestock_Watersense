const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const WaterLevel = sequelize.define('WaterLevel', {
  device_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  level_percentage: {
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
  tableName: 'water_levels',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = WaterLevel;
