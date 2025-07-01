const BatasAir = require('../models/batasAirModel'); 

exports.getBatasAir = async (req, res) => {
  const { device_id } = req.params;

  try {
    const data = await BatasAir.findOne({ where: { device_id } });

    if (!data) {
      return res.status(404).json({ message: 'Data tidak ditemukan' });
    }

    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ message: 'Gagal mengambil data', error: error.message });
  }
};

exports.saveBatasAir = async (req, res) => {
  const { device_id, batas_atas, batas_bawah } = req.body;

  console.log('[DEBUG] Data diterima dari frontend:', { device_id, batas_atas, batas_bawah });

  // Validasi input
  if (!device_id || batas_atas == null || batas_bawah == null) {
    return res.status(400).json({ message: 'Data tidak lengkap' });
  }

  try {
    // Cek apakah device_id sudah ada
    const existing = await BatasAir.findOne({ where: { device_id } });

    if (existing) {
      console.log('[DEBUG] Melakukan UPDATE batas_air');
      await BatasAir.update(
        { batas_atas, batas_bawah },
        { where: { device_id } }
      );
    } else {
      console.log('[DEBUG] Melakukan INSERT batas_air');
      await BatasAir.create({ device_id, batas_atas, batas_bawah });
    }

    res.status(200).json({ message: 'Data batas air berhasil disimpan' });
  } catch (error) {
    console.error('[ERROR] Gagal menyimpan data batas air:', error);
    res.status(500).json({ message: 'Gagal menyimpan data', error: error.message });
  }
};
