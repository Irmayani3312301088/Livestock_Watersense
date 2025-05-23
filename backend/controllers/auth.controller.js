const bcrypt = require('bcryptjs'); 
const jwt = require('jsonwebtoken');
const { Sequelize } = require('sequelize'); // Tambahkan import Sequelize
const User = require('../models/user.model');
const SECRET_KEY = 'react';

exports.register = async (req, res) => {
  const { name, username, email, password } = req.body;
  
  console.log("Data received from Flutter:", req.body);
  
  try {
    // Check if username or email already exists
    const existingUser = await User.findOne({
      where: {
        [Sequelize.Op.or]: [
          { username: username },
          { email: email }
        ]
      }
    });
    
    if (existingUser) {
      if (existingUser.username === username) {
        return res.status(409).json({ success: false, message: 'Username already exists' });
      }
      if (existingUser.email === email) {
        return res.status(409).json({ success: false, message: 'Email already exists' });
      }
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Create user
    const user = await User.create({
      name,
      username,
      email,
      password: hashedPassword
    });
    
    // Generate token
    const token = jwt.sign(
      { id: user.id, username: user.username, name: user.name },
      SECRET_KEY,
      { expiresIn: '1h' }
    );
    
    res.status(201).json({
      success: true,
      message: 'Registration successful',
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email
      },
      token
    });
  } catch (err) {
    console.error("Error during registration:", err.message);
    res.status(400).json({
      success: false,
      message: 'Registration failed',
      error: err.message
    });
  }
};

exports.login = async (req, res) => {
  const { username, password } = req.body;
  
  try {
    // Find user by username or email
    const user = await User.findOne({
      where: {
        [Sequelize.Op.or]: [
          { username: username },
          { email: username }
        ]
      }
    });
    
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    // Compare password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    
    if (!isPasswordValid) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    // Generate token
    const token = jwt.sign(
      { id: user.id, username: user.username, name: user.name },
      SECRET_KEY,
      { expiresIn: '1h' }
    );
    
    // Return user data (excluding password)
    const userData = user.toJSON();
    delete userData.password;
    
    res.status(200).json({
      success: true,
      message: 'Login successful',
      user: userData,
      token
    });
  } catch (err) {
    console.error("Error during login:", err.message);
    res.status(500).json({
      success: false,
      message: 'Login failed',
      error: err.message
    });
  }
};