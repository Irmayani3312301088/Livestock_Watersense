const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const BatasAir = sequelize.define('BatasAir', {
  device_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
  },
  batas_atas: {
    type: DataTypes.FLOAT,
    allowNull: false,
  },
  batas_bawah: {
    type: DataTypes.FLOAT,
    allowNull: false,
  },
}, {
  tableName: 'batas_air', 
  timestamps: true,
  updatedAt: 'updated_at',
  createdAt: false, 
});

module.exports = BatasAir;
