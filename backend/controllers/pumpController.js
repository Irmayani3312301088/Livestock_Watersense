const PumpStatus = require('../models/pumpStatusModel');

// Fungsi otomatis berdasarkan level air
exports.updatePumpAutomatically = async (level_percentage, device_id) => {
  let newStatus = 'off';

  if (level_percentage <= 30) {
    newStatus = 'on';
  } else if (level_percentage >= 95) {
    newStatus = 'off';
  }

  try {
    await PumpStatus.create({
      device_id,
      mode: 'auto',
      status: newStatus,
    });
  } catch (err) {
    console.error('Gagal update status pompa:', err);
  }
};

// Fungsi manual dari admin
exports.setManualPumpStatus = async (req, res) => {
  const { device_id, status } = req.body;

  try {
    await PumpStatus.create({
      device_id,
      mode: 'manual',
      status,
    });

    res.status(201).json({ message: 'Pompa diatur manual.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Gagal mengatur pompa secara manual.' });
  }
};

// Ambil status terakhir pompa
exports.getLatestPumpStatus = async (req, res) => {
  try {
    const latest = await PumpStatus.findOne({
      order: [['created_at', 'DESC']],
    });

    if (!latest) {
      return res.status(404).json({ message: 'Belum ada status pompa.' });
    }

    res.status(200).json(latest);
  } catch (err) {
    res.status(500).json({ message: 'Gagal ambil status pompa.' });
  }
};
