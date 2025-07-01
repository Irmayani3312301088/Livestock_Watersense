import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  final String _server = '96e6c0ae39ae4e31be4222ba62457f96.s1.eu.hivemq.cloud';
  final int _port = 8883;
  final String _clientId =
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
  final String _username = 'irmayani';
  final String _password = 'Irma123_';

  // Topics
  final String _sensorTopic = 'livestock/sensor/data';
  final String _pumpTopic = 'livestock/pump/status';
  final String _waterLevelTopic = 'livestock/water/level';
  final String _livestockTopic = 'livestock/data'; // Dari Arduino

  MqttServerClient? _client;

  // StreamControllers
  late StreamController<Map<String, dynamic>> _sensorDataController;
  late StreamController<Map<String, dynamic>> _pumpStatusController;
  late StreamController<Map<String, dynamic>> _waterLevelController;
  late StreamController<Map<String, dynamic>> _livestockDataController;

  // Streams
  Stream<Map<String, dynamic>> get sensorDataStream =>
      _sensorDataController.stream;
  Stream<Map<String, dynamic>> get pumpStatusStream =>
      _pumpStatusController.stream;
  Stream<Map<String, dynamic>> get waterLevelStream =>
      _waterLevelController.stream;
  Stream<Map<String, dynamic>> get livestockDataStream =>
      _livestockDataController.stream;

  MqttServerClient? get client => _client;

  Future<void> initialize() async {
    _sensorDataController = StreamController<Map<String, dynamic>>.broadcast();
    _pumpStatusController = StreamController<Map<String, dynamic>>.broadcast();
    _waterLevelController = StreamController<Map<String, dynamic>>.broadcast();
    _livestockDataController =
        StreamController<Map<String, dynamic>>.broadcast();
  }

  Future<void> connect() async {
    if (_client != null &&
        _client!.connectionStatus?.state == MqttConnectionState.connected) {
      print('MQTT already connected.');
      return;
    }

    await initialize();

    _client = MqttServerClient.withPort(_server, _clientId, _port);
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 30;
    _client!.onDisconnected = _onDisconnected;
    _client!.secure = true;
    _client!.securityContext = SecurityContext.defaultContext;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(_username, _password)
        .keepAliveFor(30)
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMess;

    try {
      await _client!.connect();
    } catch (e) {
      print('MQTT Connection Error: $e');
      _client!.disconnect();
      rethrow;
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      print(' MQTT Connected to $_server');

      _client!.subscribe(_sensorTopic, MqttQos.atLeastOnce);
      _client!.subscribe(_pumpTopic, MqttQos.atLeastOnce);
      _client!.subscribe(_waterLevelTopic, MqttQos.atLeastOnce);
      _client!.subscribe(_livestockTopic, MqttQos.atLeastOnce); // dari ESP32

      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String topic = c[0].topic;
        final String payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        try {
          final data = json.decode(payload) as Map<String, dynamic>;

          if (topic == _sensorTopic) {
            _sensorDataController.add(data);
          } else if (topic == _pumpTopic) {
            _pumpStatusController.add(data);
          } else if (topic == _waterLevelTopic) {
            _waterLevelController.add(data);
          } else if (topic == _livestockTopic) {
            _livestockDataController.add(data);
          }
        } catch (e) {
          print(' MQTT JSON Parse Error: $e\nPayload: $payload');
        }
      });
    } else {
      print(
        ' MQTT Failed to connect. Status: ${_client!.connectionStatus!.state}',
      );
      _client!.disconnect();
      throw Exception('MQTT: Gagal koneksi');
    }
  }

  void _onDisconnected() {
    print(' MQTT Disconnected');
    Timer(const Duration(seconds: 5), () async {
      print(' Reconnecting to MQTT...');
      await connect();
    });
  }

  Future<void> disconnect() async {
    _client?.disconnect();
    await _sensorDataController.close();
    await _pumpStatusController.close();
    await _waterLevelController.close();
    await _livestockDataController.close();
  }

  Future<void> publish(String topic, String message) async {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    } else {
      throw Exception('MQTT client not connected');
    }
  }

  Future<void> controlPump(bool turnOn) async {
    final message = jsonEncode({
      'command': turnOn ? 'on' : 'off',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await publish(_pumpTopic, message);
  }

  Future<void> setPumpMode(String mode) async {
    final message = jsonEncode({
      'mode': mode,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await publish('livestock/pump/mode', message);
  }

 
}
