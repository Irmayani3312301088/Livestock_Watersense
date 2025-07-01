import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'regis_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late AnimationController _backgroundController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _backgroundAnimation;

  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Setup animations with proper curves
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Start animations with proper delays
    _startAnimations();
  }

  void _startAnimations() async {
    // Start fade animation immediately
    _fadeController.forward();

    // Start slide animation after a short delay
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _onButtonPressed() async {
    if (_isButtonPressed) return;

    setState(() => _isButtonPressed = true);

    // Button press animation
    await _buttonController.forward();
    await _buttonController.reverse();

    // Add haptic feedback
    HapticFeedback.lightImpact();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) {
            return const RegisPage();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    final titleFontSize =
        isTablet ? (isLandscape ? 22.0 : 28.0) : (isLandscape ? 18.0 : 24.0);
    final buttonWidth = isTablet ? 250.0 : 200.0;
    final buttonHeight = isTablet ? 55.0 : 50.0;
    final imageHeight = isLandscape ? height * 0.5 : height * 0.6;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1A3E),
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0C1A3E),
                      Color.lerp(
                        const Color(0xFF1A2B5E),
                        const Color(0xFF2A3B6E),
                        _backgroundAnimation.value,
                      )!.withOpacity(0.8),
                      const Color(0xFF0C1A3E),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // Hero image with white background inside clipped area
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: ClipPath(
                  clipper: SmoothBottomClipper(),
                  child: Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: Colors.white,
                    child: Hero(
                      tag: 'landing_image',
                      child: Container(
                        width: double.infinity,
                        height: imageHeight,
                        color: Colors.white,
                        child: Transform.scale(
                          scale: 1.0 + (_fadeAnimation.value * 0.1),
                          child: Image.asset(
                            'assets/Live.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.white,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Main content with enhanced animations
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: isLandscape ? 40 : 60,
                          left: 24,
                          right: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Enhanced title
                            Text(
                              "Sistem Pintar\nOtomatisasi Air Minum dan\nPemantauan Suhu Pada Kandang Kambing",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.7),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isLandscape ? 20 : 30),

                            // Enhanced button with animation
                            AnimatedBuilder(
                              animation: _buttonScaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _buttonScaleAnimation.value,
                                  child: Container(
                                    width: buttonWidth,
                                    height: buttonHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.grey.shade100,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.1),
                                          blurRadius: 5,
                                          offset: const Offset(0, -2),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          _isButtonPressed
                                              ? null
                                              : _onButtonPressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: const Color(
                                          0xFF0C1A3E,
                                        ),
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        "Selanjutnya",
                                        style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: isLandscape ? 15 : 20),

                            // Additional info text with fade animation
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value * 0.7,
                                  child: Text(
                                    "Geser untuk memulai dengan pemantauan pintar",
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 12,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced clipper with smoother curve matching the image
class SmoothBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start from top-left
    path.lineTo(0, size.height - 100);

    // Create a smooth single curve that matches the image style
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 20,
      size.width,
      size.height - 100,
    );

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
