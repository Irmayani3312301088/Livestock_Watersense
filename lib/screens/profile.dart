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

  Widget _buildProfileField(String label, String value, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.032, // Responsive font size
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: screenWidth * 0.015), // Responsive spacing
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.03,
            horizontal: screenWidth * 0.01,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.038, // Responsive font size
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1F2937),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.032,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: screenWidth * 0.015),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
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
                    fontSize: screenWidth * 0.038,
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
                  size: screenWidth * 0.05, // Responsive icon size
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
    required double screenWidth,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.09, // Responsive container size
            height: screenWidth * 0.09,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: screenWidth * 0.045, // Responsive icon size
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: const Color(0xFF9CA3AF),
            size: screenWidth * 0.035,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1A3E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get screen dimensions
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isTablet = screenWidth > 600;

            // Calculate responsive values
            final horizontalPadding = screenWidth * (isTablet ? 0.1 : 0.05);
            final avatarRadius = screenWidth * (isTablet ? 0.08 : 0.12);
            final cardMargin = screenWidth * (isTablet ? 0.08 : 0.05);

            if (userProfile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (userProfile!.isEmpty) {
              return const Center(
                child: Text(
                  'Gagal memuat profil.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header Bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: screenHeight * 0.015,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            RoleNavigationHelper.goToDashboard(context);
                          },

                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.02),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.12),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Profile Avatar
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.grey[300],
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
                              size: avatarRadius * 1.2,
                              color: Colors.white,
                            )
                            : null,
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Profile Info Card
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: cardMargin),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      child: Column(
                        children: [
                          _buildProfileField(
                            'Nama',
                            userProfile!['name'] ?? '',
                            screenWidth,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildProfileField(
                            'Username',
                            userProfile!['username'] ?? '',
                            screenWidth,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildProfileField(
                            'Email',
                            userProfile!['email'] ?? '',
                            screenWidth,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildProfileField(
                            'Role',
                            userProfile!['role'] ?? '',
                            screenWidth,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _buildPasswordField('Password', screenWidth),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Action Card
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: cardMargin),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                                  builder: (context) => const EditProfilePage(),
                                ),
                              );
                              if (result != null && result['success'] == true) {
                                _loadProfile();
                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profile updated successfully',
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
                              text: 'Edit Profile',
                              color: const Color(0xFF1E3A8A),
                              screenWidth: screenWidth,
                            ),
                          ),
                        ),
                        Container(
                          height: 1,
                          margin: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          color: const Color(0xFFE5E7EB),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                () => _showSignOutDialog(context, screenWidth),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: _buildActionItem(
                              icon: Icons.logout_outlined,
                              text: 'Logout',
                              color: const Color(0xFFDC2626),
                              screenWidth: screenWidth,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, double screenWidth) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Keluar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
              fontSize: screenWidth * 0.045,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: screenWidth * 0.035,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService.clearSession();

                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
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
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
