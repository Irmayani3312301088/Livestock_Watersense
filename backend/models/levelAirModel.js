const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const LevelAir = sequelize.define('LevelAir', {
  device_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  level: {
    type: DataTypes.FLOAT,
    allowNull: false
  }
}, {
  tableName: 'level_air',
  timestamps: true
});

module.exports = LevelAir;
