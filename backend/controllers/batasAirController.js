const BatasAir = require('../models/batasAirModel');
const mqtt = require('mqtt');

const MQTT_BROKER = 'mqtt://broker.hivemq.com:1883';
const MQTT_TOPIC = 'livestock/config/batas-air';

// POST /api/batas-air
exports.updateBatasAir = async (req, res) => {
  const { device_id, batas_atas, batas_bawah } = req.body;

  if (!device_id || batas_atas == null || batas_bawah == null) {
    return res.status(400).json({ message: 'Semua data wajib diisi.' });
  }

  try {
    const existing = await BatasAir.findOne({ where: { device_id } });

    if (existing) {
      await existing.update({ batas_atas, batas_bawah });
    } else {
      await BatasAir.create({ device_id, batas_atas, batas_bawah });
    }

    // === Kirim MQTT ke ESP ===
    const client = mqtt.connect(MQTT_BROKER);

    client.on('connect', () => {
      const payload = JSON.stringify({
        device_id,
        batas_atas,
        batas_bawah,
      });

      client.publish(MQTT_TOPIC, payload, { retain: true }, (err) => {
        if (err) {
          console.error('❌ Gagal publish MQTT batas air:', err.message);
        } else {
          console.log('✅ [MQTT] Batas air dikirim ke ESP:', payload);
        }
        client.end();
      });
    });

    res.status(200).json({ message: 'Batas air berhasil diperbarui dan dikirim ke ESP.' });
  } catch (err) {
    console.error('❌ Gagal simpan batas air:', err);
    res.status(500).json({ message: 'Gagal simpan batas air' });
  }
};

// GET /api/batas-air/:device_id
exports.getBatasAir = async (req, res) => {
  const { device_id } = req.params;

  try {
    const data = await BatasAir.findOne({ where: { device_id } });

    if (!data) {
      return res.status(404).json({ message: 'Data batas air belum ada.' });
    }

    res.status(200).json(data);
  } catch (err) {
    console.error('❌ Gagal ambil batas air:', err);
    res.status(500).json({ message: 'Gagal ambil data batas air' });
  }
};
