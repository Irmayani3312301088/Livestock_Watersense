import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/models/notification_item.dart';
import 'mqtt_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:async';

class ApiService {
  // Set pump mode (auto/manual)
  static Future<bool> setPumpMode(String mode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pump/set-mode'),
        headers: await getHeaders(),
        body: json.encode({'mode': mode}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Gagal mengubah mode pompa: $e');
      return false;
    }
  }

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
      var uri = Uri.parse('$baseUrl/users');
      var request = http.MultipartRequest('POST', uri);

      // Ambil token dan set Authorization
      String? token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      } else {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Harap login ulang.',
        };
      }

      // Set field yang wajib
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['role'] = role;

      // Field opsional
      if (username != null && username.isNotEmpty) {
        request.fields['username'] = username;
      }

      // Tambahkan foto jika ada
      if (profileImage != null) {
        final mimeType = lookupMimeType(profileImage.path);
        if (mimeType != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'profile',
              profileImage.path,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[DEBUG] Create User Status Code: ${response.statusCode}');
      print('[DEBUG] Create User Response: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('[ERROR] createUser: $e');
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
      var uri = Uri.parse('$baseUrl/users/$userId');
      var request = http.MultipartRequest('PUT', uri);

      // Tambahkan token
      String? token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Isi field
      request.fields['name'] = name;
      request.fields['email'] = email;
      if (username != null) request.fields['username'] = username;
      if (role != null) request.fields['role'] = role;

      // Upload gambar jika ada
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Debug respons (sementara)
      print('[UPDATE USER] Status: ${response.statusCode}');
      print('[UPDATE USER] Body: ${response.body}');

      // Cek apakah response JSON
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {
          'success': false,
          'message': 'Server mengirim non-JSON:\n${response.body}',
        };
      }

      // Cek status sukses
      if (response.statusCode != 200 && response.statusCode != 201) {
        return {
          'success': false,
          'message':
              'Gagal update user. Kode: ${response.statusCode}\n${response.body}',
        };
      }

      // Parse JSON aman
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan saat update: $e'};
    }
  }

  // Delete user
  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await getHeaders(),
      );

      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus user: $e'};
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
      final uri = Uri.parse('$baseUrl/profile');
      var request = http.MultipartRequest('PUT', uri);

      // Tambahkan Authorization token jika ada
      final token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Tambahkan form fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['username'] = username;
      request.fields['role'] = role;
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      // Validasi dan kirim file gambar (dengan mime type)
      if (profileImage != null) {
        final fileSize = await profileImage.length();
        if (fileSize > 5 * 1024 * 1024) {
          return {
            'success': false,
            'message': 'Ukuran gambar terlalu besar. Maksimal 5MB.',
          };
        }

        // Deteksi mime type berdasarkan isi file
        final mimeType = lookupMimeType(profileImage.path);
        if (mimeType == null ||
            !(mimeType == 'image/jpeg' || mimeType == 'image/png')) {
          return {
            'success': false,
            'message': 'Hanya file JPEG, JPG, atau PNG yang diperbolehkan.',
          };
        }

        final multipartFile = await http.MultipartFile.fromPath(
          'profile_image',
          profileImage.path,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      // Kirim request ke server
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      // Pastikan response JSON
      if (!response.headers['content-type']!.contains('application/json')) {
        return {'success': false, 'message': 'Server mengembalikan non-JSON'};
      }

      return json.decode(response.body);
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

    // Log response body before parsing
    print('[DEBUG] getLatestPumpStatus response body: ${response.body}');

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
    final token = await getToken(); // 
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // 
      },
    );

    // debug
    print(' Status: ${response.statusCode}');
    print(' Body: ${response.body}');

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

    print('POST Notif - Status Code: ${response.statusCode}');
    print('POST Notif - Body: ${response.body}');

    if (response.statusCode != 201) {
      throw Exception('Gagal mengirim notifikasi');
    }
  }

  static Future<void> deleteAllNotifications() async {
    final response = await http.delete(Uri.parse('$baseUrl/notifications'));

    print('DELETE Notif - Status Code: ${response.statusCode}');
    print('DELETE Notif - Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus semua notifikasi');
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
    );

    print('PATCH Notif - Status Code: ${response.statusCode}');
    print('PATCH Notif - Body: ${response.body}');

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

  //OTP
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return data;
    } on TimeoutException {
      return {'success': false, 'message': 'Timeout: Server lambat, coba lagi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal kirim OTP: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> resetPasswordWithOtp(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final payload = {'email': email, 'otp': otp, 'newPassword': newPassword};
      print('Payload: $payload');

      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      print('Response: ${response.body}');
      final responseData = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message':
            responseData['message'] ??
            (response.statusCode == 200
                ? 'Password berhasil direset'
                : 'Gagal reset password'),
        'data': responseData,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timeout, coba lagi ya',
        'data': null,
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Format data tidak valid',
        'data': null,
      };
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Jaringan error: ${e.message}',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error ga jelas nih: ${e.toString()}',
        'data': null,
      };
    }
  }
}
