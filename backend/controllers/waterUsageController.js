const { sequelize } = require('../config/database');
const { Op } = require('sequelize');
const WaterUsage = require('../models/waterUsageModel');

// Ambil total penggunaan air hari ini
const getTodayUsage = async (req, res) => {
  try {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const result = await WaterUsage.findOne({
      attributes: [
        [sequelize.fn('SUM', sequelize.col('usage_ml')), 'total_usage']
      ],
      where: {
        date: {
          [Op.between]: [startOfDay, endOfDay]
        }
      },
      raw: true
    });

    const total = result?.total_usage ?? 0;

    res.status(200).json({
      success: true,
      data: total
    });
  } catch (error) {
    console.error('Gagal ambil data penggunaan air hari ini:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal ambil data hari ini.'
    });
  }
};

// Tambah atau update penggunaan air hari ini berdasarkan device
const sendWaterUsage = async (req, res) => {
  const { device_id, usage_ml } = req.body;

  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [record, created] = await WaterUsage.findOrCreate({
      where: {
        device_id,
        date: {
          [Op.gte]: today
        }
      },
      defaults: { usage_ml }
    });

    if (!created) {
      record.usage_ml += Number(usage_ml);
      await record.save();
    }

    res.status(201).json({
      success: true,
      message: created
        ? 'Data baru penggunaan air ditambahkan.'
        : 'Penggunaan air hari ini diperbarui.',
      data: record
    });
  } catch (error) {
    console.error('Gagal menyimpan penggunaan air:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal menyimpan penggunaan air.'
    });
  }
};

// Ambil riwayat penggunaan air 7 hari terakhir
const getDailyUsageHistory = async (req, res) => {
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

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    console.error('Gagal ambil riwayat penggunaan air:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal ambil riwayat penggunaan air.'
    });
  }
};

module.exports = {
  getTodayUsage,
  sendWaterUsage,
  getDailyUsageHistory
};
