const ManualPump = require('../models/manualPumpModel');
const PumpStatus = require('../models/pumpStatusModel');
const LevelAir = require('../models/levelAirModel');

// Ambil status pompa (GET)
exports.getStatusPompa = async (req, res) => {
  try {
    const pump = await PumpStatus.findOne({ where: { device_id: 1 } });
    if (!pump) {
      return res.status(404).json({ message: 'Data pump_status tidak ditemukan' });
    }

    res.status(200).json({ status: pump.status });
  } catch (err) {
    res.status(500).json({ message: 'Gagal ambil status pompa', error: err.message });
  }
};

// Ubah status pompa (POST)
exports.ubahStatusPompa = async (req, res) => {
  const { status } = req.body;

  if (!['on', 'off'].includes(status)) {
    return res.status(400).json({ message: 'Status tidak valid' });
  }

  try {
    const pump = await PumpStatus.findOne({ where: { device_id: 1 } });
    if (!pump) {
      return res.status(404).json({ message: 'Data pump_status tidak ditemukan' });
    }

    // Update status
    pump.status = status;
    await pump.save();

    // Catat juga ke log
    await ManualPump.create({
      level_air: 'N/A',
      batas_ketinggian: 'N/A',
      batas_rendah: 'N/A',
      status_pompa: status,
    });

    res.status(200).json({ message: 'Status berhasil diubah', status });
  } catch (err) {
    res.status(500).json({ message: 'Gagal ubah status', error: err.message });
  }
};

// Kirim log pompa manual (POST)
exports.konfirmasiPompaManual = async (req, res) => {
  const { level_air, batas_ketinggian, batas_rendah, status_pompa } = req.body;

  if (!['on', 'off'].includes(status_pompa)) {
    return res.status(400).json({ message: 'Status pompa tidak valid' });
  }

  try {
    // Simpan ke log
    await ManualPump.create({
      level_air,
      batas_ketinggian,
      batas_rendah,
      status_pompa,
    });

    // Update juga status terakhir
    const pump = await PumpStatus.findOne({ where: { device_id: 1 } });
    if (pump) {
      pump.status = status_pompa;
      await pump.save();
    }

    res.status(200).json({ message: 'Pompa manual berhasil dikonfirmasi' });
  } catch (err) {
    res.status(500).json({ message: 'Gagal mencatat data', error: err.message });
  }
};

// Ambil histori log (GET)
exports.getLogPompaManual = async (req, res) => {
  try {
    const data = await ManualPump.findAll({
      order: [['waktu_konfirmasi', 'DESC']],
    });

    res.status(200).json(data);
  } catch (err) {
    res.status(500).json({ message: 'Gagal ambil histori', error: err.message });
  }
};

exports.getLevelAirTerakhir = async (req, res) => {
  try {
    const latest = await LevelAir.findOne({
      order: [['createdAt', 'DESC']],
    });

    if (!latest) {
      return res.status(404).json({ message: 'Data level air tidak ditemukan' });
    }

    res.status(200).json({ level_air: latest.level_air });
  } catch (err) {
    res.status(500).json({ message: 'Gagal mengambil level air', error: err.message });
  }
};
