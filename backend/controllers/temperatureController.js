const Temperature = require('../models/temperatureModel');

exports.storeTemperature = async (req, res) => {
  try {
    const { device_id, temperature } = req.body;

    let status = 'Normal';
    let note = 'Suhu dalam batas normal';

    if (temperature < 20) {
      status = 'Dingin';
      note = 'Suhu terlalu dingin';
    } else if (temperature > 35) {
      status = 'Panas';
      note = 'Suhu terlalu panas';
    }

    const data = await Temperature.create({
      device_id,
      temperature,
      status,
      note
    });

    res.status(201).json({ message: 'Data suhu disimpan', data });
  } catch (error) {
    console.error('❌ Gagal menyimpan suhu:', error);
    res.status(500).json({ message: 'Gagal menyimpan suhu' });
  }
};

exports.getLatestTemperature = async (req, res) => {
  try {
    const latest = await Temperature.findOne({
      order: [['created_at', 'DESC']],
    });

    if (!latest) {
      return res.status(404).json({ message: 'Data suhu belum ada.' });
    }

    res.status(200).json({
      temperature: latest.temperature,
      status: latest.status,
      note: latest.note,
    });
  } catch (err) {
    console.error('❌ Gagal mengambil data suhu:', err);
    res.status(500).json({ message: 'Gagal mengambil suhu' });
  }
};
