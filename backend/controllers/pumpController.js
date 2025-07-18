const PumpStatus = require('../models/pumpStatusModel');

// Mengatur mode pompa (auto / manual)
exports.setPumpMode = async (req, res) => {
  try {
    const { mode } = req.body;

    if (!mode || (mode !== 'auto' && mode !== 'manual')) {
      return res.status(400).json({ message: 'Mode tidak valid.' });
    }

    const latestStatus = await PumpStatus.findOne({
      order: [['created_at', 'DESC']],
    });

    if (!latestStatus) {
      return res.status(404).json({ message: 'Status pompa tidak ditemukan.' });
    }

    await latestStatus.update({ mode });

    return res.status(200).json({ message: 'Mode pompa berhasil diubah.', mode });
  } catch (error) {
    console.error('❌ Gagal set mode pompa:', error);
    return res.status(500).json({ message: 'Gagal mengubah mode pompa.' });
  }
};

// Mengambil status pompa terbaru
exports.getLatestPumpStatus = async (req, res) => {
  try {
    const data = await PumpStatus.findOne({
      order: [['created_at', 'DESC']],
    });

    if (!data) {
      return res.status(404).json({ message: 'Status pompa belum ada.' });
    }

    res.status(200).json({
      status: data.status,
      mode: data.mode,
    });
  } catch (err) {
    console.error('❌ Gagal mengambil status pompa:', err);
    res.status(500).json({ message: 'Gagal mengambil status pompa.' });
  }
};

// Update status pompa secara otomatis berdasarkan level air dan device
exports.updatePumpAutomatically = async (level, deviceId = 1) => {
  try {
    const latestStatus = await PumpStatus.findOne({
      where: { device_id: deviceId },
      order: [['created_at', 'DESC']],
    });

    if (!latestStatus) {
      console.warn(`🚨 Status pompa tidak ditemukan untuk device_id ${deviceId}`);
      return;
    }

    // Jalankan otomatis hanya jika mode = 'auto'
    if (latestStatus.mode === 'auto') {
      let newStatus = 'OFF';

      if (level < 30) {
        newStatus = 'ON';
      }

      await latestStatus.update({ status: newStatus });

      console.log(`⚙️ Pompa [device ${deviceId}] diatur ke: ${newStatus} (level air: ${level}%)`);
    } else {
      console.log(`ℹ️ Mode pompa device ${deviceId} adalah manual, tidak diubah otomatis.`);
    }
  } catch (error) {
    console.error('❌ Gagal update otomatis pompa:', error.message);
  }
};

// Ekspor semua fungsi controller
module.exports = {
  setPumpMode: exports.setPumpMode,
  getLatestPumpStatus: exports.getLatestPumpStatus,
  updatePumpAutomatically: exports.updatePumpAutomatically,
};
