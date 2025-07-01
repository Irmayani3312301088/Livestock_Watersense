import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/dialog_utils.dart';

class UserEditPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isEditMode;

  const UserEditPage({Key? key, required this.user, this.isEditMode = true})
    : super(key: key);

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;
  late TextEditingController _passwordController;

  File? _selectedImage;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _baseUrl = 'http://10.0.2.2:5000/api';

  // Focus nodes for better UX
  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
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
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _pickImage() async {
    try {
      // Show image source selection modal bottom sheet
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder:
            (context) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar di atas
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title "Pilih Sumber Gambar"
                    const Text(
                      'Pilih Sumber Gambar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Row dengan 2 pilihan: Kamera dan Galeri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildImageSourceOption(
                          icon: Icons.camera_alt,
                          label: 'Kamera',
                          onTap:
                              () => Navigator.pop(context, ImageSource.camera),
                        ),
                        _buildImageSourceOption(
                          icon: Icons.photo_library,
                          label: 'Galeri',
                          onTap:
                              () => Navigator.pop(context, ImageSource.gallery),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      );

      if (source == null) return;

      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto berhasil dipilih'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih foto: ${e.toString()}');
    }
  }

  // Method yang membuat setiap pilihan (Kamera/Galeri)
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Column(
          children: [
            // Container dengan icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1A3E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            // Text label
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUser() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Mohon lengkapi semua field yang wajib diisi');
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400),
                const SizedBox(width: 8),
                const Text('Error'),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _deleteProfileImage() {
    setState(() {
      _selectedImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Foto profil dihapus'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
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

  Widget _buildProfileImageSection() {
    String imageUrl = _getImageUrl();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          children: [
            // Profile Image Container
            Stack(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE5E7EB),
                    border: Border.all(
                      color: const Color(0xFFD1D5DB),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child:
                        imageUrl.isNotEmpty
                            ? (_selectedImage != null
                                ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: 130,
                                  height: 130,
                                )
                                : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: 130,
                                  height: 130,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 65,
                                      color: Colors.grey.shade400,
                                    );
                                  },
                                ))
                            : Icon(
                              Icons.person,
                              size: 65,
                              color: Colors.grey.shade400,
                            ),
                  ),
                ),
                // Camera icon for upload indication
                if (imageUrl.isEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1A3E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Upload Info
            Text(
              'Upload Foto Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'PNG atau JPG format (Maks 5MB)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pilih Foto Button
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Pilih Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C1A3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                ),

                const SizedBox(width: 12),

                // Hapus Foto Button
                if (imageUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _deleteProfileImage,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1A3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditMode ? 'Edit User' : 'Tambah User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // Profile Image Section with Card
              _buildProfileImageSection(),

              // Form Fields Section
              Card(
                elevation: 3,
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Lengkap
                      _buildFormField(
                        label: 'Nama Lengkap',
                        isRequired: true,
                        child: _buildTextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          nextFocus: _usernameFocus,
                          hintText: 'Masukkan nama lengkap',
                          icon: Icons.person,
                          textInputAction: TextInputAction.next,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Username
                      _buildFormField(
                        label: 'Username',
                        child: _buildTextField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          nextFocus: _emailFocus,
                          hintText: 'Masukkan username',
                          icon: Icons.alternate_email,
                          textInputAction: TextInputAction.next,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Email
                      _buildFormField(
                        label: 'Email',
                        isRequired: true,
                        child: _buildTextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          nextFocus: _passwordFocus,
                          hintText: 'Masukkan email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Role
                      _buildFormField(
                        label: 'Role',
                        child: _buildRoleDropdown(),
                      ),

                      const SizedBox(height: 20),

                      // Password
                      _buildFormField(
                        label: 'Kata Sandi',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isEditMode)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Kosongkan jika tidak ingin mengubah password',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            _buildPasswordField(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF94A3B8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Save Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C1A3E),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        widget.isEditMode
                                            ? 'Simpan Perubahan'
                                            : 'Tambah User',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          if (hintText.contains('nama lengkap'))
            return 'Nama lengkap wajib diisi';
          if (hintText.contains('username')) return 'Username wajib diisi';
          if (hintText.contains('email')) return 'Email wajib diisi';
        }
        if (hintText.contains('email') &&
            value != null &&
            value.isNotEmpty &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Format email tidak valid';
        }
        if (hintText.contains('username') &&
            value != null &&
            value.length < 3) {
          return 'Username minimal 3 karakter';
        }
        return null;
      },
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0C1A3E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
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
      style: const TextStyle(fontSize: 16, color: Colors.black),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(
          Icons.admin_panel_settings_outlined,
          color: Colors.grey.shade600,
          size: 22,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0C1A3E), width: 2),
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
      focusNode: _passwordFocus,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _saveUser(),
      validator: (value) {
        if (!widget.isEditMode && (value == null || value.isEmpty)) {
          return 'Password wajib diisi';
        }
        if (value != null && value.isNotEmpty && value.length < 6) {
          return 'Password minimal 8 karakter';
        }
        return null;
      },
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText:
            widget.isEditMode ? 'Masukkan password baru' : 'Masukkan password',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.grey.shade600,
          size: 22,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0C1A3E), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
