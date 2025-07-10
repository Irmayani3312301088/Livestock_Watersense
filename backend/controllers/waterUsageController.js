const { sequelize } = require('../config/database');
const { Op } = require('sequelize');
const WaterUsage = require('../models/waterUsageModel');

// ✅ Ambil total penggunaan air hari ini
exports.getTodayUsage = async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    const result = await WaterUsage.findOne({
      attributes: [
        [sequelize.fn('SUM', sequelize.col('usage_ml')), 'total_usage']
      ],
      where: { date: today },
      raw: true
    });

    const total = result?.total_usage ?? 0;
    res.status(200).json({ today_usage: total });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Gagal ambil data hari ini." });
  }
};

// ✅ Tambah/update penggunaan air (1 data per hari per device)
exports.sendWaterUsage = async (req, res) => {
  const { device_id, usage_ml } = req.body;

  try {
    const today = new Date().toISOString().split('T')[0];

    const [record, created] = await WaterUsage.findOrCreate({
      where: { device_id, date: today },
      defaults: { usage_ml }
    });

    if (!created) {
      // Sudah ada → tambahkan volume baru
      record.usage_ml += Number(usage_ml);
      await record.save();
    }

    res.status(201).json({
      message: created
        ? 'Data baru penggunaan air ditambahkan.'
        : 'Penggunaan air hari ini diperbarui.',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Gagal menyimpan penggunaan air." });
  }
};

// ✅ Ambil riwayat penggunaan air 7 hari terakhir (untuk laporan)
exports.getDailyUsageHistory = async (req, res) => {
  try {
    const result = await WaterUsage.findAll({
      attributes: [
        'date',
        [sequelize.fn('SUM', sequelize.col('usage_ml')), 'total_usage']
      ],
      group: ['date'],
      order: [['date', 'DESC']],
      limit: 7
    });

    res.status(200).json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Gagal ambil riwayat penggunaan air." });
  }
};
