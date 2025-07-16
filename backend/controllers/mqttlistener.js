const mqtt = require('mqtt');
const axios = require('axios');
const { savePumpStatus } = require('./pumpController');

// 1. Konfigurasi
const brokerUrl = 'mqtts://fdeedc05bf0145268563e624aa10122c.s1.eu.hivemq.cloud:8883';
const options = {
  clientId: `livestock_backend_${Math.random().toString(16).substr(2, 8)}`,
  username: 'admin123',
  password: 'Admin123qwe',
  clean: false,
  reconnectPeriod: 5000,
  connectTimeout: 10000,
  keepalive: 30,
  rejectUnauthorized: false
};

// 2. Koneksi ke broker
const client = mqtt.connect(brokerUrl, options);

// 3. Daftar topik
const topics = {
  data: 'livestock/data',
  sensor: 'livestock/sensor/data',
  config: 'livestock/device/+/request-config',
  pumpStatus: 'livestock/pump/status'
};

// 4. Koneksi berhasil
client.on('connect', () => {
  console.log(`✅ MQTT Connected (Client ID: ${options.clientId})`);
  client.subscribe(Object.values(topics), { qos: 1 }, (err) => {
    if (err) {
      console.error('❌ Subscribe error:', err);
    } else {
      console.log(`📡 Subscribed to: ${Object.values(topics).join(', ')}`);
    }
  });
});

// 5. Event lainnya
client.on('error', (err) => {
  console.error('‼️ MQTT Error:', err);
});
client.on('reconnect', () => {
  console.log('♻️ Attempting MQTT reconnection...');
});
client.on('close', () => {
  console.log('🔌 MQTT connection closed');
});

// 6. Message handler
client.on('message', async (topic, payload) => {
  try {
    const data = safeParse(payload);
    if (!data) {
      console.warn(`⚠️ Invalid JSON on ${topic}: ${payload.toString()}`);
      return;
    }

    console.log(`📥 [${topic}] Received:`, data);

    switch (true) {
      case topic === topics.data:
        await handleWaterData(data);
        break;
      case topic === topics.sensor:
        await handleSensorData(data);
        break;
      case topic === topics.pumpStatus:
        await handlePumpStatus(data);
        break;
      case topic.includes('request-config'):
        console.log('⚙️ Config request received');
        break;
      default:
        console.log('🌐 Unhandled topic:', topic);
    }
  } catch (err) {
    console.error(`❌ Processing error [${topic}]:`, err.message);
  }
});

// 7. Helper
function safeParse(payload) {
  try {
    return JSON.parse(payload.toString());
  } catch {
    return null;
  }
}

// 8. Handler fungsi
async function handleWaterData(data) {
  if (!data.level || !data.status) {
    throw new Error('Invalid water data structure');
  }

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

  client.publish(topics.pumpStatus, JSON.stringify({
    status: data.pump?.toLowerCase() === 'on' ? 'on' : 'off',
    mode: 'auto',
    timestamp: new Date().toISOString()
  }), { qos: 1 });

  console.log('✅ Water data processed');
}

async function handleSensorData(data) {
  if (!data.temperature && !data.humidity) {
    throw new Error('Invalid sensor data');
  }

  await axios.post('http://localhost:5000/api/temperature', {
    device_id: 1,
    temperature: data.temperature,
    humidity: data.humidity,
    recorded_at: new Date().toISOString()
  });

  console.log('✅ Sensor data processed');
}

async function handlePumpStatus(data) {
  if (!data.status || !data.mode || !data.timestamp) {
    throw new Error('Invalid pump status payload');
  }

  await savePumpStatus({
    device_id: 1,
    status: data.status,
    mode: data.mode,
    timestamp: data.timestamp
  });

  console.log('✅ Pump status saved to database');
}

// 9. Shutdown
process.on('SIGINT', () => {
  client.end(() => {
    console.log('🛑 MQTT connection terminated');
    process.exit(0);
  });
});
