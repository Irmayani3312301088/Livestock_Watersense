const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const ManualPump = sequelize.define('ManualPump', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  level_air: {
    type: DataTypes.STRING(10),
    allowNull: true,
  },
  batas_ketinggian: {
    type: DataTypes.STRING(10),
    allowNull: true,
  },
  batas_rendah: {
    type: DataTypes.STRING(10),
    allowNull: true,
  },
  status_pompa: {
    type: DataTypes.ENUM('on', 'off'),
    allowNull: true,
    defaultValue: 'off',
  },
}, {
  tableName: 'manual_pump_logs',
  timestamps: true,
  createdAt: 'waktu_konfirmasi',
  updatedAt: false,
});

module.exports = ManualPump;
