const { sequelize } = require('../config/database');
const { Op } = require('sequelize');
const WaterUsage = require('../models/waterUsageModel');

exports.getTodayUsage = async (req, res) => {
  try {

    const today = new Date().toLocaleDateString('en-CA'); 

    const result = await WaterUsage.findAll({
  attributes: [
    [sequelize.fn('SUM', sequelize.col('usage_ml')), 'total_usage']
  ],
  where: { date: today },
  raw: true
});

const total = result[0]?.total_usage ?? 0;

    res.status(200).json({ today_usage: total });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Gagal ambil data hari ini." });
  }
};


// Kirim data penggunaan air
exports.sendWaterUsage = async (req, res) => {
  const { device_id, usage_ml } = req.body;

  try {
    const today = new Date().toISOString().split('T')[0];
    
    await WaterUsage.create({
      device_id,
      usage_ml,
      date: today,
    });

    res.status(201).json({ message: "Penggunaan air berhasil disimpan." });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Gagal menyimpan penggunaan air." });
  }
};

// Ambil riwayat penggunaan air per tanggal
exports.getDailyUsageHistory = async (req, res) => {
  try {
    const result = await WaterUsage.findAll({
      attributes: [
        'date',
        [sequelize.fn('SUM', sequelize.col('usage_ml')), 'total_usage']
      ],
      group: ['date'],
      order: [['date', 'DESC']],
      limit: 7 // 7 hari terakhir
    });

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Gagal ambil riwayat penggunaan air." });
  }
};
