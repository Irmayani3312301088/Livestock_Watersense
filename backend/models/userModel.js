const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const User = sequelize.define('User', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: {
    type: DataTypes.STRING(100),
    allowNull: false,
    validate: { notEmpty: true, len: [2, 100] }
  },
  username: {
    type: DataTypes.STRING(50),
    allowNull: true,
    unique: true,
    validate: { len: [3, 50] }
  },
  email: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true,
    validate: { notEmpty: true, isEmail: true, len: [5, 100] }
  },
  password: {
    type: DataTypes.STRING(255),
    allowNull: true, // Null untuk user yang belum register
    validate: { len: [6, 255] }
  },
  role: {
  type: DataTypes.STRING,
  allowNull: true, 
  defaultValue: null, 
},

  profile_image: {
    type: DataTypes.STRING(255),
    allowNull: true,
    defaultValue: null
  },
  status: {
    type: DataTypes.ENUM('pending', 'active', 'inactive'),
    allowNull: false,
    defaultValue: 'pending'
  },
  created_by_admin: {
    type: DataTypes.INTEGER,
    allowNull: true,
  }
}, {
  tableName: 'users',
  timestamps: true
});

module.exports = User;