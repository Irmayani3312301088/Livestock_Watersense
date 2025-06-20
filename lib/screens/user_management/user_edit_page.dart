import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_list_page.dart';
import '../../utils/dialog_utils.dart'; 

class UserEditPage extends StatefulWidget {
  final Map<String, dynamic>
  user;
  final bool isEditMode; 

  const UserEditPage({Key? key, required this.user, this.isEditMode = true})
    : super(key: key);

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;
  late TextEditingController _passwordController;

  File? _selectedImage;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _baseUrl = 'http://10.0.2.2:5000/api';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user['name']?.toString() ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.user['username']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.user['email']?.toString() ?? '',
    );
    _roleController = TextEditingController(
      text: widget.user['role']?.toString() ?? 'user',
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? token = await _getAuthToken();
      if (token == null) {
        _showErrorDialog('Token tidak ditemukan. Silakan login ulang.');
        return;
      }

      var request = http.MultipartRequest(
        widget.isEditMode ? 'PUT' : 'POST',
        Uri.parse(
          widget.isEditMode
              ? '$_baseUrl/users/${widget.user['id']}'
              : '$_baseUrl/users',
        ),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
      });

      // Add form fields
      request.fields.addAll({
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _roleController.text.trim(),
      });

      // Add password field only if it's filled (for edit mode it's optional)
      if (_passwordController.text.isNotEmpty) {
        request.fields['password'] = _passwordController.text;
      }

      // Add image file if selected
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _selectedImage!.path,
          ),
        );
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success - gunakan dialog utils
        _showSimpleSuccessDialog(responseData);
      } else {
        // Error from server
        _showErrorDialog(
          responseData['message'] ?? 'Terjadi kesalahan saat menyimpan data.',
        );
      }
    } catch (e) {
      print('Error saving user: $e');
      _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSimpleSuccessDialog(Map<String, dynamic> responseData) {
    showAutoCloseSuccessPopup(
      context,
      'User berhasil\ndisimpan!',
      onDone: () {
        // Kembali ke halaman sebelumnya dengan data
        Navigator.of(context).pop({
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'User berhasil disimpan!',
        });
      },
      durationSeconds: 2,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _getImageUrl() {
    if (_selectedImage != null) {
      return _selectedImage!.path;
    } else if (widget.user['profile_image'] != null &&
        widget.user['profile_image'].isNotEmpty) {
      // Return full URL for network image
      return '$_baseUrl/uploads/profiles/${widget.user['profile_image']}';
    }
    return '';
  }

  Widget _buildProfileImage() {
    String imageUrl = _getImageUrl();

    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.purple.shade100,
        backgroundImage:
            imageUrl.isNotEmpty
                ? (_selectedImage != null
                    ? FileImage(_selectedImage!) as ImageProvider
                    : NetworkImage(imageUrl))
                : null,
        child:
            imageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.isEditMode
                            ? 'Manajemen User - Edit'
                            : 'Manajemen User - Tambah',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildProfileImage(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _nameController,
                              hintText: 'Nama',
                              icon: Icons.person,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _usernameController,
                        hintText: 'Username',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildRoleDropdown(),
                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00296B),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    widget.isEditMode
                                        ? 'Simpan Perubahan'
                                        : 'Tambah User',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$hintText wajib diisi';
        }
        if (hintText == 'Email' &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Format email tidak valid';
        }
        if (hintText == 'Username' && value.length < 3) {
          return 'Username minimal 3 karakter';
        }
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    final roleValue =
        ['admin', 'user'].contains(_roleController.text)
            ? _roleController.text
            : 'user';

    return DropdownButtonFormField<String>(
      value: roleValue,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Role',
        prefixIcon: const Icon(Icons.work_outline),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
        DropdownMenuItem(value: 'user', child: Text('User')),
      ],
      onChanged: (value) {
        setState(() {
          _roleController.text = value ?? 'user';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Role wajib dipilih';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (!widget.isEditMode && (value == null || value.isEmpty)) {
          return 'Password wajib diisi';
        }
        if (value != null && value.isNotEmpty && value.length < 6) {
          return 'Password minimal 6 karakter';
        }
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: widget.isEditMode ? 'Password Baru (Opsional)' : 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
