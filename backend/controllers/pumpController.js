const PumpStatus = require('../models/pumpStatusModel');
const BatasAir = require('../models/batasAirModel');

const savePumpStatus = async ({ device_id, status, mode, timestamp }) => {
  try {
    await PumpStatus.create({
      device_id,
      status,
      mode,
      recorded_at: timestamp, // pastikan model punya kolom ini
    });
  } catch (error) {
    console.error('❌ Failed to save pump status:', error.message);
  }
};

exports.updatePumpAutomatically = async (level_percentage, device_id) => {
  try {
    console.log(`🔁 [PumpController] updatePumpAutomatically → device_id=${device_id}, level=${level_percentage}`);

    const batas = await BatasAir.findOne({ where: { device_id } });

    if (!batas) {
      console.warn(`⚠️ Batas air untuk device_id=${device_id} tidak ditemukan.`);
      return;
    }

    console.log(`📊 Batas: atas=${batas.batas_atas}, bawah=${batas.batas_bawah}`);

    let newStatus = 'off';

    if (level_percentage < batas.batas_bawah) {
      newStatus = 'on';
    } else if (level_percentage >= batas.batas_atas) {
      newStatus = 'off';
    }

    const existing = await PumpStatus.findOne({ where: { device_id } });

    if (existing) {
      console.log(`🔄 Status pompa sebelumnya: ${existing.status}`);

      if (existing.status !== newStatus) {
        await existing.update({ status: newStatus, mode: 'auto' });
        console.log(`✅ [Pump] Status Diperbarui ke: ${newStatus.toUpperCase()}`);
      } else {
        console.log('ℹ️ [Pump] Status pompa tetap, tidak ada perubahan.');
      }
    } else {
      await PumpStatus.create({ device_id, status: newStatus, mode: 'auto' });
      console.log(`🆕 [Pump] Status pompa baru dibuat: ${newStatus.toUpperCase()}`);
    }
  } catch (err) {
    console.error('❌ Gagal update pompa otomatis:', err.message);
    throw err;
  }
};

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

module.exports = {
  savePumpStatus,
  updatePumpAutomatically: exports.updatePumpAutomatically,
  getLatestPumpStatus: exports.getLatestPumpStatus,
};