const WaterLevel = require('../models/waterLevelModel');
const pumpController =require('./pumpController');

exports.sendWaterLevel = async (req, res) => {
  const { device_id, level_percentage } = req.body;

  let status = 'Normal';
  let note = 'Level air dalam kondisi normal';

  if (level_percentage <= 30) {
    status = 'Rendah';
    note = 'Peringatan: Level air rendah, isi manual atau aktifkan pompa!';
  } else if (level_percentage >= 95) {
    status = 'Penuh';
    note = 'Tangki air hampir penuh.';
  }

  try {
    await WaterLevel.create({
      device_id,
      level_percentage,
      status,
      note
    });

    // Jalankan kontrol otomatis pompa
    await pumpController.updatePumpAutomatically(level_percentage, device_id);

    res.status(201).json({ message: 'Data level air berhasil disimpan.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Gagal menyimpan data level air.' });
  }
};

exports.getLatestWaterLevel = async (req, res) => {
  try {
    const latest = await WaterLevel.findOne({
      order: [['created_at', 'DESC']],
    });

    if (!latest) {
      return res.status(404).json({ message: 'Data level air belum ada.' });
    }

    res.status(200).json(latest);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Gagal mengambil data level air.' });
  }
};
