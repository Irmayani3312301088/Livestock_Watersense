const Temperature = require('../models/temperatureModel');

// Simpan data suhu ke database
exports.sendTemperature = async (req, res) => {
  const { device_id, temperature } = req.body;

  let status = "Normal";
  let note = "Suhu dalam batas normal";

  if (temperature >= 38) {
    status = "Tinggi";
    note = "Peringatan: Suhu terlalu tinggi!";
  } else if (temperature < 25) {
    status = "Rendah";
    note = "Peringatan: Suhu terlalu rendah!";
  }

  try {
    await Temperature.create({
      device_id,
      temperature,
      status,
      note,
    });

    res.status(201).json({ message: "Data suhu berhasil disimpan." });
  } catch (err) {
    console.error("Error saat simpan suhu:", err);
    res.status(500).json({ message: "Gagal menyimpan data suhu." });
  }
};

// Ambil suhu terbaru
exports.getLatestTemperature = async (req, res) => {
  try {
    const latest = await Temperature.findOne({
      order: [['created_at', 'DESC']],
    });

    if (!latest) {
      return res.status(404).json({ message: "Belum ada data suhu." });
    }

    res.status(200).json(latest);
  } catch (err) {
    console.error("Error ambil data suhu:", err);
    res.status(500).json({ message: "Gagal mengambil data suhu." });
  }
};
