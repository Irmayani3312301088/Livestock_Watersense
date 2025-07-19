import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class UserAddPage extends StatefulWidget {
  const UserAddPage({Key? key}) : super(key: key);

  @override
  State<UserAddPage> createState() => _UserAddPageState();
}

class _UserAddPageState extends State<UserAddPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _selectedImage;
  bool _isPasswordVisible = false;
  String _selectedRole = 'Peternak';
  final List<String> _roles = ['Peternak', 'Admin'];

  // Responsive breakpoints
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;
  bool get _isTablet => _screenWidth > 600;
  bool get _isLandscape => _screenWidth > _screenHeight;

  // Responsive padding
  EdgeInsets get _responsivePadding =>
      EdgeInsets.symmetric(horizontal: _isTablet ? 32.0 : 16.0, vertical: 16.0);

  // Responsive avatar size
  double get _avatarSize {
    if (_isTablet) return 120.0;
    return _isLandscape ? 80.0 : 100.0;
  }

  // Responsive card width for tablets
  double get _cardMaxWidth => _isTablet ? 600.0 : double.infinity;

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: _isTablet ? 400 : double.infinity,
              ),
              margin:
                  _isTablet
                      ? EdgeInsets.symmetric(
                        horizontal: (_screenWidth - 400) / 2,
                      )
                      : EdgeInsets.zero,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Pilih Sumber Gambar',
                    style: TextStyle(
                      fontSize: _isTablet ? 20 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: _isTablet ? 30 : 20),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isTablet ? 40 : 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildImageSourceOption(
                            icon: Icons.camera_alt,
                            label: 'Kamera',
                            onTap:
                                () =>
                                    Navigator.pop(context, ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildImageSourceOption(
                            icon: Icons.photo_library,
                            label: 'Galeri',
                            onTap:
                                () =>
                                    Navigator.pop(context, ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: _isTablet ? 40 : 30),
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
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: _isTablet ? 24 : 20,
          horizontal: _isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(_isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1A3E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: _isTablet ? 28 : 24),
            ),
            SizedBox(height: _isTablet ? 12 : 8),
            Text(
              label,
              style: TextStyle(
                fontSize: _isTablet ? 16 : 14,
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
    if (_formKey.currentState!.validate()) {
      // Tampilkan loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            ),
      );

      try {
        final result = await ApiService.createUser(
          name: _nameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          role: _selectedRole,
          profileImage: _selectedImage,
        );

        // Tutup loading spinner
        Navigator.of(context).pop();

        // Debug log
        print("Response dari ApiService.createUser: $result");

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pengguna berhasil ditambahkan'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          _showSuccessDialog();
        } else {
          String errorMsg = 'Gagal menambahkan pengguna.';
          if (result.containsKey('message')) {
            errorMsg = result['message'].toString();
          }
          _showErrorDialog(errorMsg);
        }
      } catch (e) {
        Navigator.of(context).pop(); // Tutup loading spinner
        _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: _isTablet ? 400 : double.infinity,
            ),
            padding: EdgeInsets.all(_isTablet ? 40 : 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _isTablet ? 100 : 80,
                  height: _isTablet ? 100 : 80,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: _isTablet ? 60 : 50,
                  ),
                ),
                SizedBox(height: _isTablet ? 30 : 20),
                Text(
                  'Pengguna berhasil\nditambahkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isTablet ? 18 : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: _isTablet ? 40 : 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // tutup dialog
                      Navigator.pop(
                        context,
                        true,
                      ); // keluar dari halaman dan kirim hasil
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C1A3E),
                      padding: EdgeInsets.symmetric(
                        vertical: _isTablet ? 18 : 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text('Error', style: TextStyle(fontSize: _isTablet ? 20 : 18)),
          content: Text(
            message,
            style: TextStyle(fontSize: _isTablet ? 16 : 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(fontSize: _isTablet ? 16 : 14),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Tambah Pengguna',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: _isTablet ? 20 : 18,
          ),
        ),
        backgroundColor: const Color(0xFF0C1A3E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: _isTablet ? _buildTabletLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: _responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagePickerCard(),
          const SizedBox(height: 16),
          _buildFormCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: _responsivePadding,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: _cardMaxWidth),
          child:
              _isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: _buildImagePickerCard()),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildFormCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImagePickerCard(),
        const SizedBox(height: 24),
        _buildFormCard(),
        const SizedBox(height: 32),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildImagePickerCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(_isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: _avatarSize,
                  height: _avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE5E7EB),
                    image:
                        _selectedImage != null
                            ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _selectedImage == null
                          ? Icon(
                            Icons.person,
                            size: _avatarSize * 0.5,
                            color: const Color(0xFF9CA3AF),
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(_isTablet ? 10 : 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C1A3E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: _isTablet ? 20 : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _isTablet ? 24 : 16),
          Text(
            'Upload Foto Profil',
            style: TextStyle(
              fontSize: _isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: _isTablet ? 8 : 4),
          Text(
            'PNG atau JPG format (Maks 5MB)',
            style: TextStyle(
              fontSize: _isTablet ? 14 : 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: _isTablet ? 24 : 16),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: Icon(Icons.image, size: _isTablet ? 20 : 16),
            label: Text(
              'Pilih Foto',
              style: TextStyle(fontSize: _isTablet ? 16 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C1A3E),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: _isTablet ? 24 : 20,
                vertical: _isTablet ? 14 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: Size(_isTablet ? 140 : 120, _isTablet ? 48 : 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_isTablet ? 32 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            _nameController,
            'Nama Lengkap',
            Icons.person_outline,
            true,
          ),
          _buildTextField(
            _usernameController,
            'Username',
            Icons.alternate_email,
            false,
          ),
          _buildTextField(
            _emailController,
            'Email',
            Icons.email_outlined,
            true,
            isEmail: true,
          ),
          _buildDropdownField(),
          _buildPasswordField(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isRequired, {
    bool isEmail = false,
    bool isPassword = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _isTablet ? 20 : 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: TextStyle(fontSize: _isTablet ? 16 : 14),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return '$label wajib diisi';
          }
          if (isEmail &&
              value != null &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Format email tidak valid';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: const Color(0xFF6B7280),
            fontSize: _isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF9CA3AF),
            size: _isTablet ? 24 : 20,
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: const Color(0xFF9CA3AF),
                      size: _isTablet ? 24 : 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0C1A3E), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: _isTablet ? 20 : 16,
            vertical: _isTablet ? 20 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      margin: EdgeInsets.only(bottom: _isTablet ? 12 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: TextStyle(fontSize: _isTablet ? 16 : 14),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password wajib diisi';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Kata Sandi',
              labelStyle: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: _isTablet ? 16 : 14,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: const Color(0xFF9CA3AF),
                size: _isTablet ? 24 : 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF9CA3AF),
                  size: _isTablet ? 24 : 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF0C1A3E),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: _isTablet ? 20 : 16,
                vertical: _isTablet ? 20 : 16,
              ),
            ),
          ),
          SizedBox(height: _isTablet ? 12 : 8),
          Text(
            'Kosongkan jika tidak ingin mengubah password',
            style: TextStyle(
              fontSize: _isTablet ? 14 : 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      margin: EdgeInsets.only(bottom: _isTablet ? 20 : 16),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        onChanged:
            (String? newValue) => setState(() => _selectedRole = newValue!),
        style: TextStyle(fontSize: _isTablet ? 16 : 14, color: Colors.black87),
        decoration: InputDecoration(
          labelText: 'Role',
          labelStyle: TextStyle(
            color: const Color(0xFF6B7280),
            fontSize: _isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            Icons.work_outline,
            color: const Color(0xFF9CA3AF),
            size: _isTablet ? 24 : 20,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0C1A3E), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: _isTablet ? 20 : 16,
            vertical: _isTablet ? 20 : 16,
          ),
        ),
        dropdownColor: Colors.white,
        items:
            _roles
                .map(
                  (String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(fontSize: _isTablet ? 16 : 14),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: SizedBox(
        width: _isTablet ? 250 : 200,
        child: ElevatedButton(
          onPressed: _saveUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0C1A3E),
            padding: EdgeInsets.symmetric(vertical: _isTablet ? 18 : 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            'Tambah Pengguna',
            style: TextStyle(
              color: Colors.white,
              fontSize: _isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
