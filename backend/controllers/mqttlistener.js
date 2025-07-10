const mqtt = require('mqtt');
const axios = require('axios');

// 1. Konfigurasi yang Lebih Robust
const brokerUrl = 'mqtts://fdeedc05bf0145268563e624aa10122c.s1.eu.hivemq.cloud:8883'; // SSL/TLS port
const options = {
  clientId: `livestock_backend_${Math.random().toString(16).substr(2, 8)}`,
  username: 'admin123', // Add username
  password: 'Admin123qwe', // Add password
  clean: false, // Maintain session
  reconnectPeriod: 5000, // Auto-reconnect every 5s
  connectTimeout: 10000, // 10s timeout
  keepalive: 30, // Ping interval
  rejectUnauthorized: false // Bypass SSL certificate verification (for testing)
};

// 2. Handle Multiple Connection Scenarios
const client = mqtt.connect(brokerUrl, options);

// 3. Topik yang Diperlukan
const topics = {
  data: 'livestock/data',
  sensor: 'livestock/sensor/data',
  config: 'livestock/device/+/request-config',
  pumpStatus: 'livestock/pump/status'
};

// 4. Enhanced Connection Handler
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

// 5. Improved Error Handling
client.on('error', (err) => {
  console.error('‼️ MQTT Error:', err);
});

client.on('reconnect', () => {
  console.log('♻️ Attempting MQTT reconnection...');
});

client.on('close', () => {
  console.log('🔌 MQTT connection closed');
});

// 6. Enhanced Message Processing
client.on('message', async (topic, payload) => {
  try {
    const data = safeParse(payload);
    
    if (!data) {
      console.warn(`⚠️ Invalid JSON on ${topic}: ${payload.toString()}`);
      return;
    }

    console.log(`📥 [${topic}] Received:`, data);

    // 7. Topic-Specific Handlers
    switch (true) {
      case topic === topics.data:
        await handleWaterData(data);
        break;
        
      case topic === topics.sensor:
        await handleSensorData(data);
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

// 8. Helper Functions
function safeParse(payload) {
  try {
    return JSON.parse(payload.toString());
  } catch {
    return null;
  }
}

async function handleWaterData(data) {
  if (!data.level || !data.status) {
    throw new Error('Invalid water data structure');
  }

  // 9. Parallel API Requests
  await Promise.all([
    axios.post('http://localhost:5000/api/water-level', {
      device_id: 1,
      level_percentage: data.level,
      status: data.status,
    }),
    axios.post('http://localhost:5000/api/water-usage', {
      device_id: 1,
      usage_ml: (data.volume || 0) * 1000,
    })
  ]);

  // 10. QoS 1 for critical messages
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

// 11. Graceful Shutdown
process.on('SIGINT', () => {
  client.end(() => {
    console.log('🛑 MQTT connection terminated');
    process.exit(0);
  });
});