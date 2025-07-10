import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  final String _server = 'fdeedc05bf0145268563e624aa10122c.s1.eu.hivemq.cloud';
  final int _port = 8883;
  final String _username = 'admin123';
  final String _password = 'Admin123qwe';

  final String _sensorTopic = 'livestock/sensor/data';
  final String _pumpTopic = 'livestock/pump/status';
  final String _waterLevelTopic = 'livestock/water/level';
  final String _livestockTopic = 'livestock/data';

  MqttServerClient? _client;

  late StreamController<Map<String, dynamic>> _sensorDataController;
  late StreamController<Map<String, dynamic>> _pumpStatusController;
  late StreamController<Map<String, dynamic>> _waterLevelController;
  late StreamController<Map<String, dynamic>> _livestockDataController;
  late StreamController<bool> _connectionStatusController;

  Stream<Map<String, dynamic>> get sensorDataStream =>
      _sensorDataController.stream;
  Stream<Map<String, dynamic>> get pumpStatusStream =>
      _pumpStatusController.stream;
  Stream<Map<String, dynamic>> get waterLevelStream =>
      _waterLevelController.stream;
  Stream<Map<String, dynamic>> get livestockDataStream =>
      _livestockDataController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  MqttServerClient? get client => _client;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    _sensorDataController = StreamController<Map<String, dynamic>>.broadcast();
    _pumpStatusController = StreamController<Map<String, dynamic>>.broadcast();
    _waterLevelController = StreamController<Map<String, dynamic>>.broadcast();
    _livestockDataController =
        StreamController<Map<String, dynamic>>.broadcast();
    _connectionStatusController = StreamController<bool>.broadcast();
  }

  Future<void> connect() async {
    if (_client != null &&
        _client!.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('⚠️ MQTT already connected');
      return;
    }

    await initialize();

    try {
      final clientId = 'flutterApp_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient.withPort(_server, clientId, _port);
      _client!.secure = true;
      _client!.logging(on: true);
      _client!.keepAlivePeriod = 30;

      // TLS Support
      _client!.securityContext = SecurityContext.defaultContext;

      // Connection Callbacks
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = (topic) {
        debugPrint('📌 Subscribed to topic: $topic');
      };

      final connMess = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(_username, _password)
          .withProtocolVersion(4)
          .withProtocolName('MQTT')
          .keepAliveFor(30)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMess;

      debugPrint('🔌 Connecting to HiveMQ broker...');
      await _client!.connect();

      if (_client!.connectionStatus?.state != MqttConnectionState.connected) {
        throw Exception(
          '❌ MQTT failed to connect: ${_client!.connectionStatus}',
        );
      }

      debugPrint('✅✅✅ Connected to MQTT Broker');
      _isConnected = true;
      _connectionStatusController.add(true);

      await _subscribeToTopics();
      _setupMessageListener();
    } catch (e) {
      debugPrint('❌ MQTT Connection Error: $e');
      _client?.disconnect();
      _isConnected = false;
      _connectionStatusController.add(false);
      rethrow;
    }
  }

  Future<void> _subscribeToTopics() async {
    final topics = [
      _sensorTopic,
      _pumpTopic,
      _waterLevelTopic,
      _livestockTopic,
    ];
    for (final topic in topics) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void _setupMessageListener() {
    _client!.updates?.listen(
      (List<MqttReceivedMessage<MqttMessage>> messages) {
        if (messages.isEmpty) return;
        final message = messages.first;
        final topic = message.topic;
        final payload = _parsePayload(message);

        debugPrint('📬 Received on [$topic]: $payload');
        _routeMessage(topic, payload);
      },
      onError: (error) {
        debugPrint('❌ Message stream error: $error');
      },
    );
  }

  String _parsePayload(MqttReceivedMessage<MqttMessage> message) {
    try {
      final publishMessage = message.payload as MqttPublishMessage;
      final payloadBytes = publishMessage.payload.message;
      return MqttPublishPayload.bytesToStringAsString(payloadBytes);
    } catch (e) {
      debugPrint('❌ Payload parsing error: $e');
      return '{}';
    }
  }

  void _routeMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) {
        switch (topic) {
          case 'livestock/sensor/data':
            _sensorDataController.add(data);
            break;
          case 'livestock/pump/status':
            _pumpStatusController.add(data);
            break;
          case 'livestock/water/level':
            _waterLevelController.add(data);
            break;
          case 'livestock/data':
            _livestockDataController.add(data);
            break;
          default:
            debugPrint('⚠️ Unknown topic: $topic');
        }
      }
    } catch (e) {
      debugPrint('❌ JSON decode error: $e\nPayload: $payload');
    }
  }

  void _onConnected() {
    debugPrint('🔥 onConnected callback triggered!');
    _isConnected = true;
    _connectionStatusController.add(true);
  }

  void _onDisconnected() {
    debugPrint('🔌 MQTT Disconnected');
    _isConnected = false;
    _connectionStatusController.add(false);
    Timer(const Duration(seconds: 5), () async {
      debugPrint('🔁 Trying to reconnect...');
      try {
        await connect();
      } catch (e) {
        debugPrint('❌ Reconnect failed: $e');
      }
    });
  }

  Future<void> disconnect() async {
    _client?.disconnect();
    await _sensorDataController.close();
    await _pumpStatusController.close();
    await _waterLevelController.close();
    await _livestockDataController.close();
    await _connectionStatusController.close();
    _isConnected = false;
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
