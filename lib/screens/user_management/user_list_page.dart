import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_add_page.dart';
import 'user_edit_page.dart';
import '../../utils/dialog_utils.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String searchText = '';
  bool isLoading = true;

  // Base URL untuk API
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  String selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Fungsi untuk mendapatkan token auth
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Fungsi untuk mengambil data users dari backend
  Future<void> _fetchUsers() async {
    print(' Mengambil data user dari backend...');
    try {
      setState(() {
        isLoading = true;
      });

      String? token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(' Status code: ${response.statusCode}');
      print(' Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            users = List<Map<String, dynamic>>.from(
              data['data'].map(
                (user) => {
                  'id': user['id'],
                  'name': user['name'] ?? '',
                  'username': user['username'] ?? '',
                  'email': user['email'] ?? '',
                  'role': user['role'] ?? '',
                  'imageUrl':
                      user['profile_image'] != null
                          ? 'http://10.0.2.2:5000/uploads/profiles/${user['profile_image']}'
                          : '',
                  'status': user['status'] ?? 'pending',
                },
              ),
            );
            _filterUsers();
            isLoading = false;
          });
          print(' Data berhasil di-load');
        } else {
          print(' Backend success = false: ${data['message']}');
          _showErrorSnackBar(data['message'] ?? 'Gagal ambil data user');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print(' Gagal: Status code bukan 200');
        _showErrorSnackBar('Gagal mengambil data pengguna');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(' Error: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserAddPage()),
    );

    if (result == true) {
      _fetchUsers();
    }
  }

  void _editUser(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserEditPage(user: filteredUsers[index]),
      ),
    );

    if (result != null) {
      // Refresh data setelah edit user
      _fetchUsers();
    }
  }

  void _deleteUser(int index) {
    final user = filteredUsers[index];
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Konfirmasi Hapus',
              style: TextStyle(color: Colors.black),
            ),
            content: Text(
              'Yakin ingin menghapus ${user['name']}?',
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performDelete(user['id']);
                },
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Fungsi untuk menghapus user ke backend
  Future<void> _performDelete(int userId) async {
    try {
      String? token = await _getAuthToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          showUserDeletedPopup(
            context,
            onDone: () {
              _fetchUsers();
            },
          );

          // Refresh data setelah hapus
          _fetchUsers();
        } else {
          _showErrorSnackBar(data['message'] ?? 'Gagal menghapus user');
        }
      } else {
        _showErrorSnackBar('Gagal menghapus user');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _activateUser(int userId) async {
    try {
      String? token = await _getAuthToken();

      final response = await http.post(
        Uri.parse('$baseUrl/activate-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'id': userId}),
      );

      final data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User berhasil diaktifkan!'),
            backgroundColor: Colors.green,
          ),
        );

        // Penting! Panggil fetch lagi agar UI diperbarui
        _fetchUsers();
      } else {
        _showErrorSnackBar(data['message'] ?? 'Gagal mengaktifkan user');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _filterUsers() {
    setState(() {
      filteredUsers =
          users.where((user) {
            final matchesSearch =
                user['name']!.toLowerCase().contains(
                  searchText.toLowerCase(),
                ) ||
                (user['username'] ?? '').toLowerCase().contains(
                  searchText.toLowerCase(),
                ) ||
                (user['email'] ?? '').toLowerCase().contains(
                  searchText.toLowerCase(),
                );

            final matchesStatus =
                selectedStatus == 'all' || user['status'] == selectedStatus;

            return matchesSearch && matchesStatus;
          }).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 252, 253),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 253, 252, 253),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manajemen User',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search dan Tambah
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari user...',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF0C1A3E),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                          _filterUsers();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _addUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C1A3E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Tambah',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                Theme(
                  data: Theme.of(context).copyWith(canvasColor: Colors.white),
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Semua')),
                      DropdownMenuItem(value: 'active', child: Text('Aktif')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus = value;
                          _filterUsers();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // List User
            Expanded(
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0C1A3E),
                        ),
                      )
                      : filteredUsers.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchText.isEmpty
                                  ? 'Belum ada user yang terdaftar'
                                  : 'User tidak ditemukan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetchUsers,
                        color: const Color(0xFF0C1A3E),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        backgroundColor: Colors.grey[300],
                                        radius: 24,
                                        backgroundImage:
                                            user['imageUrl'] != ''
                                                ? NetworkImage(user['imageUrl'])
                                                : null,
                                        child:
                                            user['imageUrl'] == ''
                                                ? const Icon(
                                                  Icons.person,
                                                  size: 24,
                                                  color: Colors.white,
                                                )
                                                : null,
                                      ),
                                      const SizedBox(width: 16),
                                      // User Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['name']!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (user['email'] != null &&
                                                user['email'].isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  user['email'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Action Buttons
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Tombol Edit
                                          SizedBox(
                                            height: 32,
                                            child: ElevatedButton(
                                              onPressed: () => _editUser(index),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                elevation: 1,
                                                minimumSize: Size.zero,
                                              ),
                                              child: const Text(
                                                'Edit',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),

                                          // Tombol Hapus
                                          SizedBox(
                                            height: 32,
                                            child: ElevatedButton(
                                              onPressed:
                                                  () => _deleteUser(index),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                elevation: 1,
                                                minimumSize: Size.zero,
                                              ),
                                              child: const Text(
                                                'Hapus',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Tombol Aktifkan (jika status = pending)
                                          if (user['status'] == 'pending') ...[
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              height: 32,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AlertDialog(
                                                          title: const Text(
                                                            'Konfirmasi Aktivasi',
                                                          ),
                                                          content: Text(
                                                            'Yakin ingin mengaktifkan ${user['name']}?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                      ),
                                                              child: const Text(
                                                                'Batal',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                _activateUser(
                                                                  user['id'],
                                                                );
                                                              },
                                                              child: const Text(
                                                                'Aktifkan',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  elevation: 1,
                                                  minimumSize: Size.zero,
                                                ),
                                                child: const Text(
                                                  'Aktifkan',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
