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

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;

  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark, // Changed to dark for white background
      ),
    );

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Setup animations
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Start animations with delays
    _fadeController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _onButtonPressed() async {
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
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0C1A3E),
                  const Color(0xFF1A2B5E).withOpacity(0.8),
                  const Color(0xFF0C1A3E),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Hero image with white background inside clipped area
          ClipPath(
            clipper: SmoothBottomClipper(),
            child: Container(
              height: imageHeight,
              width: double.infinity,
              // Changed to white background
              color: Colors.white,
              child: Stack(
                children: [
                  // Main image with white background
                  Hero(
                    tag: 'landing_image',
                    child: Container(
                      width: double.infinity,
                      height: imageHeight,
                      // Added white background for the image container
                      color: Colors.white,
                      child: Transform.scale(
                        scale: 1.1,
                        child: Image.asset(
                          'assets/Live.png',
                          fit:
                              BoxFit
                                  .contain, // Changed to contain to preserve aspect ratio
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color:
                                  Colors
                                      .white, // White background for error state
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
                ],
              ),
            ),
          ),

          // Main content with enhanced animations
          SafeArea(
            child: FadeTransition(
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

                        // Enhanced button
                        ScaleTransition(
                          scale: _buttonScaleAnimation,
                          child: Container(
                            width: buttonWidth,
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.grey.shade100],
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
                                  _isButtonPressed ? null : _onButtonPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: const Color(0xFF0C1A3E),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Selanjutnya",
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isLandscape ? 15 : 20),

                        // Additional info text
                        Text(
                          "Geser untuk memulai dengan pemantauan pintar",
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
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
