import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/models/notification_item.dart';
import 'mqtt_service.dart';
import 'package:mqtt_client/mqtt_client.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> get authHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get token from SharedPreferences
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Save token to SharedPreferences
  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }

  // Clear session
  static Future<void> clearSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  // Get headers with auth
  static Future<Map<String, String>> getHeaders() async {
    String? token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await getHeaders(),
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await saveToken(data['data']['token']);
        await saveUserData(data['data']['user']);
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/self-register'),
        headers: await getHeaders(),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          if (username != null) 'username': username,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await saveToken(data['data']['token']);
        await saveUserData(data['data']['user']);
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // Get all users (admin only)
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: await getHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // UPDATED: Create user by admin
  static Future<Map<String, dynamic>> createUser({
    required String name,
    String? username,
    required String email,
    required String password,
    String role = '',
    File? profileImage,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users'));

      // Header otentikasi
      String? token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Field data
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password; // ← ini bagian penting
      request.fields['role'] = role;
      if (username != null && username.isNotEmpty) {
        request.fields['username'] = username;
      }

      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      print('Create User Response Status: ${response.statusCode}');
      print('Create User Response Body: ${response.body}');

      return data;
    } catch (e) {
      print('Create User Error: $e');
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // Update user
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String name,
    String? username,
    required String email,
    String? role,
    File? profileImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/users/$userId'),
      );

      // Add headers
      String? token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      if (username != null) request.fields['username'] = username;
      if (role != null) request.fields['role'] = role;

      // Add file if exists
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // Delete user
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await getHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // ADDED: Get user by ID
  static Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await getHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // ADDED: Check if email exists
  static Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/check-email'),
        headers: await getHeaders(),
        body: json.encode({'email': email}),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // ADDED: Check if username exists
  static Future<Map<String, dynamic>> checkUsernameExists(
    String username,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/check-username'),
        headers: await getHeaders(),
        body: json.encode({'username': username}),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  // GET: Ambil profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: await getHeaders(),
      );

      print(' GET /profile response status: ${response.statusCode}');
      print(' GET /profile response body: ${response.body}');

      // Coba deteksi apakah body JSON atau bukan
      if (!response.headers['content-type']!.contains('application/json')) {
        return {
          'success': false,
          'message': 'Respon bukan JSON: ${response.body}',
        };
      }

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil profil: $e'};
    }
  }

  // PUT: Update/Edit Profil
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String username,
    required String role,
    String? password,
    File? profileImage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/profile/edit');
      var request = http.MultipartRequest('PUT', uri);

      //  Tambahkan token
      final token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      //  Tambahkan field
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['username'] = username;
      request.fields['role'] = role;
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      //  Validasi dan upload file
      if (profileImage != null) {
        final fileSize = await profileImage.length();
        if (fileSize > 5 * 1024 * 1024) {
          // Jika > 5MB
          return {
            'success': false,
            'message': 'Ukuran gambar terlalu besar. Maksimal 5MB.',
          };
        }

        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }

      // Kirim request
      final response = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final res = await http.Response.fromStream(response);

      if (!res.headers['content-type']!.contains('application/json')) {
        return {'success': false, 'message': 'Server mengembalikan non-JSON'};
      }

      return json.decode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal update profil: $e'};
    }
  }

  //  Delete photo
  static Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/profile/photo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (!response.headers['content-type']!.contains('application/json')) {
        print("Respon bukan JSON:\n${response.body}");
        return {
          'success': false,
          'message': 'Respon bukan JSON: ${response.body}',
        };
      }

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus foto: $e'};
    }
  }

  // Temperature
  static Future<Map<String, dynamic>> getLatestTemperature() async {
    final response = await http.get(Uri.parse('$baseUrl/temperature/latest'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengambil data suhu');
    }
  }

  static Future<bool> sendTemperature({
    required int deviceId,
    required double temperature,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/temperature'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId, 'temperature': temperature}),
    );

    return response.statusCode == 201;
  }

  // Water Level
  static Future<Map<String, dynamic>> getLatestWaterLevel() async {
    final response = await http.get(Uri.parse('$baseUrl/water-level/latest'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengambil data level air');
    }
  }

  // pump status
  static Future<Map<String, dynamic>> getLatestPumpStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/pump/latest'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal ambil status pompa');
    }
  }

  // water usage
  static Future<List<Map<String, dynamic>>> getWaterUsageHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/water-usage/history'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Gagal ambil riwayat penggunaan air');
    }
  }

  static Future<double> getTodayWaterUsage() async {
    final response = await http.get(Uri.parse('$baseUrl/water-usage/today'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['today_usage'] ?? 0).toDouble();
    } else {
      throw Exception('Gagal ambil data penggunaan air hari ini');
    }
  }

  // notification
  static Future<List<NotificationItem>> getAllNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/notifications'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationItem.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil notifikasi');
    }
  }

  static Future<void> sendNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title, 'message': message, 'type': type}),
    );

    if (response.statusCode != 201) {
      throw Exception('Gagal mengirim notifikasi');
    }
  }

  static Future<void> deleteAllNotifications() async {
    final response = await http.delete(Uri.parse('$baseUrl/notifications'));
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus semua notifikasi');
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menandai semua notifikasi');
    }
  }

  // Batas Air
  static Future<Map<String, dynamic>?> fetchBatasAir(int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/batas-air/$deviceId'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Gagal fetch batas air: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetchBatasAir: $e');
      return null;
    }
  }

  static Future<bool> updateBatasAir({
    required int deviceId,
    required double batasAtas,
    required double batasBawah,
  }) async {
    try {
      print('[DEBUG] Kirim batas air:');
      print('deviceId: $deviceId');
      print('batasAtas: $batasAtas');
      print('batasBawah: $batasBawah');

      final response = await http.post(
        Uri.parse('$baseUrl/batas-air'),
        headers: await getHeaders(),
        body: jsonEncode({
          'device_id': deviceId,
          'batas_atas': batasAtas,
          'batas_bawah': batasBawah,
        }),
      );

      if (response.statusCode == 200) {
        print('[DEBUG] Berhasil update batas air.');
        return true;
      } else {
        print('[ERROR] Gagal update batas air. Status: ${response.statusCode}');
        print('[ERROR] Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[ERROR] Exception saat update batas air: $e');
      return false;
    }
  }

  // Manual Pump
  Future<String> getStatusPompa() async {
    final response = await http.get(Uri.parse('$baseUrl/status-pompa'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['status'];
    } else {
      throw Exception('Gagal ambil status');
    }
  }

  Future<bool> ubahStatusPompa(String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ubah-status-pompa'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  Future<bool> kirimKonfirmasi({
    required String levelAir,
    required String batasKetinggian,
    required String batasRendah,
    required String statusPompa,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/manual-pump'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'level_air': levelAir,
        'batas_ketinggian': batasKetinggian,
        'batas_rendah': batasRendah,
        'status_pompa': statusPompa,
      }),
    );
    return response.statusCode == 200;
  }

  // mqtt
  Future<void> sendToMQTT({
    required String topic,
    required Map<String, dynamic> data,
  }) async {
    try {
      final mqttService = MQTTService();
      if (mqttService.client?.connectionStatus?.state !=
          MqttConnectionState.connected) {
        await mqttService.connect();
      }
      await mqttService.publish(topic, json.encode(data));
    } catch (e) {
      print('Error sending to MQTT: $e');
      throw Exception('Failed to send MQTT message: $e');
    }
  }
}
