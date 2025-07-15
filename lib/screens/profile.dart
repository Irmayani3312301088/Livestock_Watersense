import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import '../helpers/role_navigation_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final response = await ApiService.getProfile();

    if (response['success'] == true) {
      setState(() {
        userProfile = response['data'];
      });
    } else {
      debugPrint("Gagal mengambil profile: ${response['message']}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat profil: ${response['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        userProfile = {};
      });
    }
  }

  ResponsiveValues _getResponsiveValues(double width, double height) {
    if (width < 400) {
      return ResponsiveValues(
        horizontalPadding: width * 0.04,
        verticalPadding: height * 0.015,
        avatarRadius: width * 0.14,
        cardMargin: width * 0.04,
        titleFontSize: width * 0.065,
        labelFontSize: width * 0.035,
        valueFontSize: width * 0.04,
        buttonFontSize: width * 0.037,
        iconSize: width * 0.055,
        spacing: width * 0.032,
        maxCardWidth: double.infinity,
      );
    } else if (width < 500) {
      return ResponsiveValues(
        horizontalPadding: width * 0.05,
        verticalPadding: height * 0.02,
        avatarRadius: width * 0.12,
        cardMargin: width * 0.05,
        titleFontSize: width * 0.06,
        labelFontSize: width * 0.032,
        valueFontSize: width * 0.038,
        buttonFontSize: width * 0.035,
        iconSize: width * 0.05,
        spacing: width * 0.03,
        maxCardWidth: double.infinity,
      );
    } else {
      return ResponsiveValues(
        horizontalPadding: width * 0.06,
        verticalPadding: height * 0.025,
        avatarRadius: width * 0.1,
        cardMargin: width * 0.06,
        titleFontSize: width * 0.055,
        labelFontSize: width * 0.03,
        valueFontSize: width * 0.035,
        buttonFontSize: width * 0.032,
        iconSize: width * 0.045,
        spacing: width * 0.028,
        maxCardWidth: double.infinity,
      );
    }
  }

  Widget _buildProfileField(
    String label,
    String value,
    ResponsiveValues responsive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: responsive.spacing * 0.5),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: responsive.spacing * 0.8,
            horizontal: responsive.spacing * 0.3,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.valueFontSize,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1F2937),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, ResponsiveValues responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: responsive.spacing * 0.5),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: responsive.spacing * 0.3),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '••••••••',
                  style: TextStyle(
                    fontSize: responsive.valueFontSize,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1F2937),
                    height: 1.2,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey,
                  size: responsive.iconSize * 0.8,
                ),
                onPressed: null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String text,
    required Color color,
    required ResponsiveValues responsive,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing),
      child: Row(
        children: [
          Container(
            width: responsive.iconSize * 1.8,
            height: responsive.iconSize * 1.8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: responsive.iconSize * 0.9),
          ),
          SizedBox(width: responsive.spacing),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: responsive.valueFontSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: const Color(0xFF9CA3AF),
            size: responsive.iconSize * 0.7,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1A3E),
      body: Container(
        color: const Color(0xFF0C1A3E), // Warna biru tua untuk area atas
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;
              final responsive = _getResponsiveValues(
                screenWidth,
                screenHeight,
              );

              if (userProfile == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }

              if (userProfile!.isEmpty) {
                return const Center(
                  child: Text(
                    'Gagal memuat profil.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return Container(
                color: const Color(0xFF0C1A3E), // Warna solid biru tua
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Bar
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalPadding,
                          vertical: responsive.verticalPadding,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                RoleNavigationHelper.goToDashboard(context);
                              },
                              child: Container(
                                padding: EdgeInsets.all(
                                  responsive.spacing * 0.6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: responsive.iconSize,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Profil',
                                style: TextStyle(
                                  color: Colors.white, // Kembalikan ke putih
                                  fontSize: responsive.titleFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: responsive.iconSize * 2.4),
                          ],
                        ),
                      ),

                      SizedBox(height: responsive.spacing * 1.5),

                      // Profile Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: responsive.avatarRadius,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          backgroundImage:
                              userProfile?['profile_image'] != null
                                  ? NetworkImage(
                                    'http://10.0.2.2:5000/uploads/profiles/${userProfile!['profile_image']}',
                                  )
                                  : null,
                          child:
                              userProfile?['profile_image'] == null
                                  ? Icon(
                                    Icons.person,
                                    size: responsive.avatarRadius * 1.2,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                      ),

                      SizedBox(height: responsive.spacing * 1.5),

                      // Profile Info Card
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: responsive.maxCardWidth,
                        ),
                        margin: EdgeInsets.symmetric(
                          horizontal: responsive.cardMargin,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(responsive.spacing * 1.5),
                          child: Column(
                            children: [
                              _buildProfileField(
                                'Nama',
                                userProfile!['name'] ?? '',
                                responsive,
                              ),
                              SizedBox(height: responsive.spacing * 0.8),
                              _buildProfileField(
                                'Nama pengguna',
                                userProfile!['username'] ?? '',
                                responsive,
                              ),
                              SizedBox(height: responsive.spacing * 0.8),
                              _buildProfileField(
                                'Email',
                                userProfile!['email'] ?? '',
                                responsive,
                              ),
                              SizedBox(height: responsive.spacing * 0.8),
                              _buildProfileField(
                                'Role',
                                userProfile!['role'] ?? '',
                                responsive,
                              ),
                              SizedBox(height: responsive.spacing * 0.8),
                              _buildPasswordField('Kata Sandi', responsive),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: responsive.spacing),

                      // Action Card
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: responsive.maxCardWidth,
                        ),
                        margin: EdgeInsets.symmetric(
                          horizontal: responsive.cardMargin,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const EditProfilePage(),
                                    ),
                                  );
                                  if (result != null &&
                                      result['success'] == true) {
                                    _loadProfile();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).clearSnackBars();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Profil berhasil diperbarui',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: _buildActionItem(
                                  icon: Icons.settings_outlined,
                                  text: 'Edit Profil',
                                  color: const Color(0xFF1E3A8A),
                                  responsive: responsive,
                                ),
                              ),
                            ),
                            Container(
                              height: 1,
                              margin: EdgeInsets.symmetric(
                                horizontal: responsive.spacing,
                              ),
                              color: const Color(0xFFE5E7EB),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap:
                                    () =>
                                        _showSignOutDialog(context, responsive),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                child: _buildActionItem(
                                  icon: Icons.logout_outlined,
                                  text: 'Keluar',
                                  color: const Color(0xFFDC2626),
                                  responsive: responsive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: responsive.spacing * 1.5),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, ResponsiveValues responsive) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Keluar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
              fontSize: responsive.titleFontSize * 0.8,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
            style: TextStyle(
              color: Colors.black,
              fontSize: responsive.buttonFontSize,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: responsive.buttonFontSize,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService.clearSession();

                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: responsive.buttonFontSize,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ResponsiveValues {
  final double horizontalPadding;
  final double verticalPadding;
  final double avatarRadius;
  final double cardMargin;
  final double titleFontSize;
  final double labelFontSize;
  final double valueFontSize;
  final double buttonFontSize;
  final double iconSize;
  final double spacing;
  final double maxCardWidth;

  ResponsiveValues({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.avatarRadius,
    required this.cardMargin,
    required this.titleFontSize,
    required this.labelFontSize,
    required this.valueFontSize,
    required this.buttonFontSize,
    required this.iconSize,
    required this.spacing,
    required this.maxCardWidth,
  });
}
