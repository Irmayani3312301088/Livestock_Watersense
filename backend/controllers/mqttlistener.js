const mqtt = require('mqtt');
const axios = require('axios');
const { savePumpStatus } = require('./pumpController');

// MQTT Konfigurasi
const brokerUrl = 'mqtts://fdeedc05bf0145268563e624aa10122c.s1.eu.hivemq.cloud:8883';
const options = {
  clientId: `livestock_backend_${Math.random().toString(16).substr(2, 8)}`,
  username: 'admin123',
  password: 'Admin123qwe',
  clean: false,
  reconnectPeriod: 5000,
  connectTimeout: 10000,
  keepalive: 30,
  rejectUnauthorized: false,
};

const client = mqtt.connect(brokerUrl, options);

// Topik
const topics = {
  data: 'livestock/data',
  sensor: 'livestock/sensor/data',
  pumpStatus: 'livestock/pump/status',
};

// Anti-spam notifikasi cache
const notificationCache = new Map(); // key: type+msg, value: timestamp

// Fungsi anti-spam
function shouldSendNotification(type, message) {
  const key = `${type}:${message}`;
  const now = Date.now();
  const lastSent = notificationCache.get(key);

  if (!lastSent || now - lastSent > 10 * 60 * 1000) {
    notificationCache.set(key, now);
    return true;
  }
  return false;
}

// Koneksi MQTT
client.on('connect', () => {
  console.log(`✅ MQTT Connected (Client ID: ${options.clientId})`);
  client.subscribe(Object.values(topics), { qos: 1 }, (err) => {
    if (err) console.error('❌ Subscribe error:', err);
    else console.log(`📡 Subscribed to: ${Object.values(topics).join(', ')}`);
  });
});

client.on('message', async (topic, payload) => {
  try {
    const data = safeParse(payload);
    if (!data) return;

    console.log(`📥 [${topic}] Received:`, data);

    if (topic === topics.data) await handleWaterData(data);
    else if (topic === topics.sensor) await handleSensorData(data);
    else if (topic === topics.pumpStatus) await handlePumpStatus(data);
  } catch (err) {
    console.error(`❌ Processing error [${topic}]:`, err.message);
  }
});

function safeParse(payload) {
  try {
    return JSON.parse(payload.toString());
  } catch {
    return null;
  }
}

// 💧 Level Air & Suhu dari livestock/data
async function handleWaterData(data) {
  if (!data.level || !data.status) throw new Error('Invalid water data');

  await Promise.all([
    axios.post('http://localhost:5000/api/water-level', {
      device_id: 1,
      level_percentage: data.level,
      status: data.status
    }),
    axios.post('http://localhost:5000/api/water-usage', {
      device_id: 1,
      usage_ml: (data.volume || 0) * 1000
    })
  ]);

  if (data.level <= 20) {
    const title = 'Level Air Rendah';
    const message = 'Air melewati batas rendah. Pompa otomatis menyala. Harap mengisi air secepatnya.';
    const type = 'air_rendah';

    if (shouldSendNotification(type, message)) {
      await sendNotification(title, message, type);
    }
  }

  if (data.temperature > 35) {
    const title = 'Suhu Terlalu Tinggi';
    const message = 'Suhu lingkungan terlalu tinggi! Harap perhatikan pemberian minum untuk ternak.';
    const type = 'suhu_tinggi';

    if (shouldSendNotification(type, message)) {
      await sendNotification(title, message, type);
    }
  }

  console.log('✅ Water data processed');
}

// 🌡️ Suhu & Kelembaban dari sensor
async function handleSensorData(data) {
  if (!data.temperature && !data.humidity) throw new Error('Invalid sensor data');

  await axios.post('http://localhost:5000/api/temperature', {
    device_id: 1,
    temperature: data.temperature,
    humidity: data.humidity,
    recorded_at: new Date().toISOString()
  });

  if (data.temperature > 25) {
    const title = 'Suhu Terlalu Tinggi';
    const message = 'Suhu lingkungan terlalu tinggi! Harap perhatikan pemberian minum untuk ternak.';
    const type = 'suhu_tinggi';

    if (shouldSendNotification(type, message)) {
      await sendNotification(title, message, type);
    }
  }

  console.log('✅ Sensor data processed');
}

// ⚙️ Status Pompa
async function handlePumpStatus(data) {
  if (!data.status || !data.mode || !data.timestamp) throw new Error('Invalid pump status');

  await savePumpStatus({
    device_id: 1,
    status: data.status,
    mode: data.mode,
    timestamp: data.timestamp
  });

  if (data.mode === 'auto' && data.status === 'on') {
    const title = 'Pompa Aktif (Mode Otomatis)';
    const message = 'Air melewati batas rendah. Pompa otomatis menyala. Harap mengisi air secepatnya.';
    const type = 'pompa_otomatis';

    if (shouldSendNotification(type, message)) {
      await sendNotification(title, message, type);
    }
  }

  console.log('✅ Pump status saved to database');
}

// 🔔 Kirim notifikasi
async function sendNotification(title, message, type) {
  try {
    await axios.post('http://localhost:5000/api/notifications', {
      title,
      message,
      type
    });
    console.log(`✅ Notifikasi "${title}" dikirim`);
  } catch (err) {
    console.error(`❌ Gagal kirim notifikasi "${title}":`, err.message);
  }
}

// 🛑 Handle Exit
process.on('SIGINT', () => {
  client.end(() => {
    console.log('🛑 MQTT connection terminated');
    process.exit(0);
  });
});
