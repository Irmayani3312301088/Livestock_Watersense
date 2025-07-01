import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'landing_page.dart';

class RegisPage extends StatelessWidget {
  const RegisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SignUpScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Focus nodes for better UX
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Set status bar - make it match the header color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0C1A3E), // Same as header color
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Setup animations
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _agreeToTerms) {
      setState(() => _isLoading = true);
      HapticFeedback.lightImpact();

      try {
        final response = await ApiService.register(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (!mounted) return;

        if (response['success'] == true) {
          final user = response['data']['user'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', user['name']);
          await prefs.setString('username', user['username']);
          await prefs.setString('email', user['email']);

          if (!mounted) return;

          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Registrasi berhasil!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (context, animation, secondaryAnimation) {
                return const LoginPage();
              },
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
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
            ),
          );
        } else {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(response['message'] ?? 'Registrasi gagal'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint('REGISTER ERROR: $e');
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Terjadi kesalahan: $e')),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else if (!_agreeToTerms) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Harap setujui syarat dan ketentuan'),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isTablet = width > 600;
    final isLandscape = width > height;

    // Responsive measurements
    final headerHeight = isLandscape ? 120.0 : (isTablet ? 180.0 : 150.0);
    final titleFontSize = isTablet ? 28.0 : 24.0;
    final maxFormWidth = isTablet ? 500.0 : 400.0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      // Remove SafeArea to allow header to extend to status bar
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header section with full blue background extending to status bar
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                // Add status bar height to header height
                height: headerHeight + MediaQuery.of(context).padding.top,
                child: Stack(
                  children: [
                    // Custom painted background with full coverage
                    CustomPaint(
                      size: Size(
                        width,
                        headerHeight + MediaQuery.of(context).padding.top,
                      ),
                      painter: HeaderPainter(),
                    ),

                    // Add padding for status bar
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      child: IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                milliseconds: 600,
                              ),
                              pageBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                              ) {
                                return const LandingPage();
                              },
                              transitionsBuilder: (
                                context,
                                animation,
                                secondaryAnimation,
                                child,
                              ) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(-1.0, 0.0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOutCubic,
                                    ),
                                  ),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),

                    // Title 
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 20,
                        ),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Daftar Akun",
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Bergabunglah dengan sistem monitoring",
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w300,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ],
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
            ),

            // Form section with enhanced styling
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: isTablet ? 40.0 : 24.0,
                  right: isTablet ? 40.0 : 24.0,
                  top: isTablet ? 32.0 : 24.0,
                  bottom: 60.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxFormWidth),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0C1A3E).withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                              spreadRadius: -5,
                            ),
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                label: "Nama Lengkap",
                                hintText: "Masukkan nama lengkap",
                                controller: _nameController,
                                focusNode: _nameFocus,
                                nextFocus: _usernameFocus,
                                prefixIcon: Icons.person_outline,
                                isTablet: isTablet,
                              ),
                              _buildTextField(
                                label: "Username",
                                hintText: "Masukkan username",
                                controller: _usernameController,
                                focusNode: _usernameFocus,
                                nextFocus: _emailFocus,
                                prefixIcon: Icons.alternate_email,
                                isTablet: isTablet,
                              ),
                              _buildTextField(
                                label: "Email",
                                hintText: "email@gmail.com",
                                controller: _emailController,
                                focusNode: _emailFocus,
                                nextFocus: _passwordFocus,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                isTablet: isTablet,
                              ),
                              _buildTextField(
                                label: "Kata Sandi",
                                hintText: "Minimal 8 karakter",
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                prefixIcon: Icons.lock_outline,
                                isTablet: isTablet,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(
                                      0xFF0C1A3E,
                                    ).withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                    HapticFeedback.selectionClick();
                                  },
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Enhanced terms checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Transform.scale(
                                    scale: isTablet ? 1.2 : 1.0,
                                    child: Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreeToTerms = value ?? false;
                                        });
                                        HapticFeedback.selectionClick();
                                      },
                                      activeColor: const Color(0xFF0C1A3E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12.0,
                                        left: 8,
                                      ),
                                      child: Text.rich(
                                        TextSpan(
                                          text: "Saya menyetujui ",
                                          style: TextStyle(
                                            fontSize: isTablet ? 16 : 14,
                                            color: Colors.black,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: "Terms of Service",
                                              style: TextStyle(
                                                color: const Color(0xFF0C1A3E),
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                            const TextSpan(text: " & "),
                                            TextSpan(
                                              text: "Privacy Policy",
                                              style: TextStyle(
                                                color: const Color(0xFF0C1A3E),
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: isTablet ? 32 : 24),

                              // Enhanced register button
                              Container(
                                width: double.infinity,
                                height: isTablet ? 60 : 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: const Color(0xFF0C1A3E),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF0C1A3E,
                                      ).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C1A3E),
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Text(
                                            "Daftar",
                                            style: TextStyle(
                                              fontSize: isTablet ? 18 : 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                ),
                              ),

                              SizedBox(height: isTablet ? 24 : 16),

                              // Enhanced login link
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(
                                          milliseconds: 600,
                                        ),
                                        pageBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) {
                                          return const LoginPage();
                                        },
                                        transitionsBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(-1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOutCubic,
                                              ),
                                            ),
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Text.rich(
                                      TextSpan(
                                        text: "Sudah punya akun? ",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: isTablet ? 16 : 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "Login di sini",
                                            style: TextStyle(
                                              color: const Color(0xFF0C1A3E),
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
    required String label,
    required String hintText,
    required TextEditingController controller,
    required bool isTablet,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction:
                nextFocus != null ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (nextFocus != null) {
                FocusScope.of(context).requestFocus(nextFocus);
              } else {
                _register();
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Field ini wajib diisi';
              }
              if (label == "Username" && value.length < 3) {
                return 'Username minimal 3 karakter';
              }
              if (label == "Username" &&
                  !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Username hanya boleh mengandung huruf, angka, dan underscore';
              }
              if (label == "Email" &&
                  !RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                return 'Format email tidak valid';
              }
              if (label == "Password" && value.length < 8) {
                return 'Password minimal 8 karakter';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: isTablet ? 16 : 14,
              ),
              prefixIcon:
                  prefixIcon != null
                      ? Icon(
                        prefixIcon,
                        color: const Color(0xFF0C1A3E).withOpacity(0.7),
                        size: isTablet ? 24 : 20,
                      )
                      : null,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF0C1A3E),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 18 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter untuk header biru dengan kurva setengah lingkaran yang sangat halus
class HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    // Header rectangle
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.6);

    // Buat kurva setengah lingkaran yang sangat halus
    // Menggunakan arcTo untuk hasil yang perfect seperti gambar referensi
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.6),
      width: size.width * 1.2, // Lebih lebar untuk kurva yang natural
      height: size.height * 0.8, // Tinggi yang proporsional
    );

    // Menambahkan arc dari kanan ke kiri (180 derajat)
    path.arcTo(
      rect,
      0, // Start angle (0 radian = kanan)
      3.14159, // Sweep angle (pi radian = 180 derajat)
      false, // Force move to
    );

    // Kembali ke titik awal
    path.lineTo(0, size.height * 0.6);
    path.close();

    // Paint dengan gradient halus
    final gradientRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradientPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0C1A3E), const Color(0xFF0A1535)],
          ).createShader(gradientRect);

    canvas.drawPath(path, gradientPaint);

    // Bayangan halus
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.save();
    canvas.translate(0, 1);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
