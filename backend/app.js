const express = require('express');
const https = require('https');
const fs = require('fs');
const mysql = require('mysql2');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = 5000;
const SECRET_KEY = 'react';

// Membaca sertifikat SSL
const sslServer = https.createServer({
  key: fs.readFileSync('./server.key'),
  cert: fs.readFileSync('./server.cert')
}, app);

// Middleware
app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// Koneksi ke MySQL
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'livestock_db'
});

db.connect(err => {
  if (err) {
    console.error(' Database connection failed:', err);
    return;
  }
  console.log(' Connected to MySQL database');
});

// Middleware autentikasi JWT
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ message: 'No token provided' });

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, SECRET_KEY);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ message: 'Invalid or expired token' });
  }
};

// REGISTER
app.post('/register', async (req, res) => {
  try {
    const { name, username, email, password } = req.body;
    if (!name || !username || !email || !password) {
      return res.status(400).json({ message: 'Please provide all required fields' });
    }

    const checkQuery = 'SELECT * FROM user WHERE username = ? OR email = ?';
    db.query(checkQuery, [username, email], async (err, results) => {
      if (err) return res.status(500).json({ message: 'Server error' });

      if (results.length > 0) {
        const isDuplicateUsername = results.some(user => user.username === username);
        const isDuplicateEmail = results.some(user => user.email === email);
        return res.status(409).json({
          message: isDuplicateUsername
            ? 'Username already exists'
            : 'Email already exists'
        });
      }

      const hashedPassword = await bcrypt.hash(password, 10);
      const insertQuery = 'INSERT INTO user (name, username, email, password) VALUES (?, ?, ?, ?)';
      db.query(insertQuery, [name, username, email, hashedPassword], (err, result) => {
        if (err) return res.status(500).json({ message: 'Failed to register user' });

        const token = jwt.sign({ id: result.insertId, username, name }, SECRET_KEY, { expiresIn: '1h' });
        res.status(201).json({
          message: 'User registered successfully',
          token,
          user: { id: result.insertId, name, username, email }
        });
      });
    });
  } catch (error) {
    res.status(500).json({ message: 'Internal server error' });
  }
});

// LOGIN
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ message: 'Please provide both username and password' });

  const query = 'SELECT * FROM user WHERE username = ? OR email = ?';
  db.query(query, [username, username], async (err, results) => {
    if (err) return res.status(500).json({ message: 'Server error' });
    if (results.length === 0) return res.status(401).json({ message: 'Invalid credentials' });

    const user = results[0];
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) return res.status(401).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ id: user.id, username: user.username, name: user.name }, SECRET_KEY, { expiresIn: '1h' });
    const { password: _, ...userWithoutPassword } = user;
    res.status(200).json({
      message: 'Login successful',
      token,
      user: userWithoutPassword
    });
  });
});

// Route terlindungi
app.get('/protected', verifyToken, (req, res) => {
  res.json({ message: 'This is a protected route', user: req.user });
});

// Menjalankan server HTTPS
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});

