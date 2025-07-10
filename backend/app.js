const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config();

const { sequelize, testConnection } = require('./config/database');
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const profileRoutes = require('./routes/profileRoutes');
const userController = require('./controllers/userController');
const temperatureRoutes = require('./routes/temperatureRoutes');
const waterLevelRoutes = require('./routes/waterLevelRoutes');
const pumpRoutes = require('./routes/pumpRoutes');
const waterUsageRoutes = require('./routes/waterUsageRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const batasAirRoutes = require('./routes/batasAirRoutes');
const manualPumpRoutes = require('./routes/manualPumpRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Registrasi semua route
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/profile', profileRoutes);
app.post('/api/activate-user', userController.activateUser);
app.use('/api/temperature', temperatureRoutes);
app.use('/api/water-level', waterLevelRoutes);         // ⬅️ ini penting
app.use('/api/pump', pumpRoutes);
app.use('/api/water-usage', waterUsageRoutes);
app.use('/api/batas-air', batasAirRoutes);
app.use('/api', notificationRoutes);
app.use('/api', manualPumpRoutes);
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));


// Jalankan server
(async () => {
  const connected = await testConnection();
  if (connected) {
    app.listen(PORT, () => console.log(` Backend jalan di http://localhost:${PORT}`));
  } else {
    console.error(' Gagal koneksi database. Server tidak dijalankan.');
  }
})();

