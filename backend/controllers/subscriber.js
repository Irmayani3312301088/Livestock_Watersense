const mqtt = require('mqtt');
const mysql = require('mysql');

// 1. Koneksi ke MQTT Broker
const client = mqtt.connect('mqtt://broker.hivemq.com');

// 2. Koneksi ke MySQL
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'livestock_db'
});

db.connect((err) => {
  if (err) throw err;
  console.log('Terhubung ke MySQL');
});

// 3. Subscribe ke Topik
client.on('connect', () => {
  client.subscribe('livestock/sensor_data');
});

// 4. Proses Data Masuk
client.on('message', (topic, message) => {
  const data = JSON.parse(message.toString());
  
  // Simpan ke MySQL
  const sql = `INSERT INTO sensor_data (temperature, humidity) 
               VALUES (${data.temperature}, ${data.humidity})`;
  
  db.query(sql, (err) => {
    if (err) console.error('Error MySQL:', err);
    else console.log('Data tersimpan!');
  });
});