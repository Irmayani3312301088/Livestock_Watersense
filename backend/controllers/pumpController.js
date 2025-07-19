const PumpStatus = require('../models/pumpStatusModel');

// ✅ 1. Mengatur mode pompa (auto / manual)
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

// ✅ 2. Mengambil status pompa terbaru
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

// ✅ 3. Update status pompa secara otomatis berdasarkan level air dan mode
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

// ✅ 4. Menyimpan status pompa baru dari MQTT
exports.savePumpStatus = async (data) => {
  try {
    await PumpStatus.create({
      device_id: data.device_id,
      status: data.status,
      mode: data.mode,
      created_at: data.timestamp || new Date().toISOString()
    });

    console.log('💾 Status pompa berhasil disimpan ke DB');
  } catch (error) {
    console.error('❌ Gagal menyimpan status pompa:', error.message);
  }
};

// ✅ 5. Ekspor semua fungsi controller

// Simpan status pompa dari MQTT ke database
exports.savePumpStatus = async ({ device_id, status, mode, timestamp }) => {
  try {
    await PumpStatus.create({
      device_id,
      status: status.toUpperCase(),
      mode: mode.toLowerCase(),
      created_at: new Date(timestamp),
    });

    console.log(`💾 Status pompa disimpan: ${status} | Mode: ${mode} | Waktu: ${timestamp}`);
  } catch (err) {
    console.error('❌ Gagal menyimpan status pompa:', err.message);
    throw err;
  }
};

// Ekspor semua fungsi controller

module.exports = {
  setPumpMode: exports.setPumpMode,
  getLatestPumpStatus: exports.getLatestPumpStatus,
  updatePumpAutomatically: exports.updatePumpAutomatically,

  savePumpStatus: exports.savePumpStatus, // Penting untuk MQTT

  savePumpStatus: exports.savePumpStatus,

};
