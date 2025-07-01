import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_page.dart';
import 'regis_page.dart';
import 'user_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscureText = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSavedCredentials();

    // Add listeners for focus changes to trigger rebuild
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      if (savedEmail != null && mounted) {
        setState(() => _rememberMe = true);
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Tambahkan method validasi untuk checkbox "Ingat saya"
  bool _validateRememberMe() {
    if (!_rememberMe) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar('Harap centang "Ingat saya" untuk melanjutkan');
      return false;
    }
    return true;
  }

  // method _login()
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // Validasi checkbox "Ingat saya"
      if (!_validateRememberMe()) return;

      HapticFeedback.lightImpact();
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);

      try {
        // Simpan email jika centang "ingat saya"
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_email', _emailController.text.trim());
        }

        final response = await ApiService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (response['success'] == true) {
          final user = response['data']['user'];
          final token = response['data']['token'];

          await ApiService.saveToken(token);
          await ApiService.saveUserData(user);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', user['email'] ?? '');
          await prefs.setString('name', user['name'] ?? '');
          await prefs.setString('role', user['role']);

          final profile = await ApiService.getProfile();
          if (profile['success']) {
            print("User profile: ${profile['data']}");
          }

          HapticFeedback.mediumImpact();
          _showSuccessSnackBar(
            'Login berhasil! Selamat datang ${user['name'] ?? 'User'}',
          );

          if (mounted) {
            final role = user['role'];

            //  Validasi jika role null / kosong
            if (role == null || role.toString().trim().isEmpty) {
              _showErrorSnackBar(
                'Role tidak ditemukan. Silakan hubungi admin.',
              );
              return;
            }

            //  Arahkan ke halaman sesuai role
            Widget targetPage;
            if (role == 'admin') {
              targetPage = const HomePage();
            } else if (role == 'user') {
              targetPage = const UserDashboard();
            } else {
              _showErrorSnackBar('Akun belum memiliki role. Hubungi admin.');
              return;
            }

            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) => targetPage,
                transitionDuration: const Duration(milliseconds: 600),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                    child: child,
                  );
                },
              ),
            );
          }
        } else {
          // Cek jika akun belum aktif
          if (response['message'].toString().toLowerCase().contains(
                'tidak ditemukan',
              ) ||
              response['message'].toString().toLowerCase().contains(
                'belum terdaftar',
              )) {
            _showErrorSnackBar('Akun belum aktif. Silakan hubungi admin.');
          } else {
            _showErrorSnackBar(
              response['message'] ?? 'Login gagal. Silakan coba lagi.',
            );
          }
          HapticFeedback.heavyImpact();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          HapticFeedback.heavyImpact();
          _showErrorSnackBar('Terjadi kesalahan. Silakan coba lagi.');
        }
      }
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final headerHeight = size.height * (isTablet ? 0.35 : 0.30);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1A3E),
      body: Column(
        children: [
          // Animated Header section with profile icon
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  height: headerHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1A3E),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.0, // Made thinner
                                ),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: isTablet ? 100 : 80,
                                color: Colors.white.withOpacity(0.9),
                                weight: 300, // Made lighter
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Animated Form section
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500 : double.infinity,
                ),
                margin:
                    isTablet
                        ? const EdgeInsets.symmetric(horizontal: 50)
                        : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 40 : 30),
                    topRight: Radius.circular(isTablet ? 40 : 30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 40.0 : 32.0),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isTablet ? 32 : 24),

                          // Login Title with animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: Center(
                                    child: Text(
                                      "Masuk",
                                      style: TextStyle(
                                        fontSize: isTablet ? 32 : 28,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0C1A3E),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 40 : 32),

                          // Email Field
                          _buildAnimatedTextField(
                            label: "E-mail",
                            hintText: "email@gmail.com",
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            delay: 200,
                            onFieldSubmitted:
                                (_) => _passwordFocus.requestFocus(),
                          ),

                          // Password Field
                          _buildAnimatedTextField(
                            label: "Kata Sandi",
                            hintText: "Minimal 8 karakter",
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _obscureText,
                            prefixIcon: Icons.lock_outline,
                            delay: 400,
                            suffixIcon: IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  key: ValueKey(_obscureText),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _obscureText = !_obscureText);
                              },
                            ),
                            onFieldSubmitted: (_) => _login(),
                          ),

                          // Remember Me & Forgot Password Row
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Remember Me
                                      Row(
                                        children: [
                                          Transform.scale(
                                            scale: 0.9,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                HapticFeedback.selectionClick();
                                                setState(
                                                  () =>
                                                      _rememberMe =
                                                          value ?? false,
                                                );
                                              },
                                              activeColor: const Color(
                                                0xFF0C1A3E,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "Ingat saya",
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Forgot Password
                                      TextButton(
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          // Handle forgot password
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                        ),
                                        child: Text(
                                          "Lupa Kata Sandi?",
                                          style: TextStyle(
                                            color: const Color(0xFF0C1A3E),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 32 : 24),

                          // Login Button with animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: isTablet ? 56 : 50,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0C1A3E,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: _isLoading ? 0 : 8,
                                          shadowColor: const Color(
                                            0xFF0C1A3E,
                                          ).withOpacity(0.3),
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child:
                                              _isLoading
                                                  ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : Text(
                                                    "Masuk",
                                                    style: TextStyle(
                                                      fontSize:
                                                          isTablet ? 18 : 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 1.1,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 40 : 32),

                          // Sign up link with animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Belum punya akun? ",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: isTablet ? 16 : 14,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                    ) => const RegisPage(),
                                                transitionDuration:
                                                    const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                transitionsBuilder: (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child,
                                                ) {
                                                  return SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: const Offset(
                                                        1.0,
                                                        0.0,
                                                      ),
                                                      end: Offset.zero,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: animation,
                                                        curve:
                                                            Curves
                                                                .easeInOutCubic,
                                                      ),
                                                    ),
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: Text(
                                            "Daftar",
                                            style: TextStyle(
                                              color: const Color(0xFF0C1A3E),
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: isTablet ? 32 : 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    int delay = 0,
    Function(String)? onFieldSubmitted,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: EdgeInsets.only(bottom: isTablet ? 24.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0C1A3E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      obscureText: obscureText,
                      keyboardType: keyboardType,
                      onFieldSubmitted: onFieldSubmitted,
                      style: TextStyle(fontSize: isTablet ? 16 : 14),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Field ini wajib diisi';
                        }
                        if (keyboardType == TextInputType.emailAddress) {
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Format email tidak valid';
                          }
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            focusNode.hasFocus
                                ? const Color(0xFFF0F4FF)
                                : const Color(0xFFF9FAFB),
                        prefixIcon:
                            prefixIcon != null
                                ? Icon(
                                  prefixIcon,
                                  color:
                                      focusNode.hasFocus
                                          ? const Color(0xFF0C1A3E)
                                          : Colors.grey.shade500,
                                  size: isTablet ? 24 : 20,
                                )
                                : null,
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
                          borderSide: const BorderSide(
                            color: Color(0xFF0C1A3E),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        suffixIcon: suffixIcon,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: isTablet ? 20 : 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
