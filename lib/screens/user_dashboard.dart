import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'riwayat_page.dart';
import 'notifikasi_page.dart';
import 'pompa_manual.dart';
import 'profile.dart';
import '../services/api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const UserDashboard(),
    );
  }
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;
  String? username;

  final List<Widget> _pages = [
    DashboardPage(),
    RiwayatPage(),
    NotifikasiPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ApiService.getProfile();
      if (response['success'] == true) {
        setState(() {
          username = response['data']['name'];
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Riwayat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ResponsiveDashboard(constraints: constraints);
      },
    );
  }
}

class ResponsiveDashboard extends StatelessWidget {
  final BoxConstraints constraints;

  const ResponsiveDashboard({super.key, required this.constraints});

  // Helper methods untuk responsivitas mobile
  bool get isSmallScreen => constraints.maxWidth < 400;
  bool get isMediumScreen =>
      constraints.maxWidth >= 400 && constraints.maxWidth < 600;
  bool get isLargeScreen => constraints.maxWidth >= 600;

  double get horizontalPadding =>
      isSmallScreen ? 12 : (isMediumScreen ? 16 : 20);
  double get verticalPadding => isSmallScreen ? 16 : 20;

  double get logoSize => isSmallScreen ? 60 : (isMediumScreen ? 75 : 90);
  double get logoHeight => isSmallScreen ? 55 : (isMediumScreen ? 70 : 85);

  double get avatarRadius => isSmallScreen ? 18 : (isMediumScreen ? 22 : 26);

  double get titleFontSize => isSmallScreen ? 18 : (isMediumScreen ? 22 : 26);
  double get subtitleFontSize =>
      isSmallScreen ? 14 : (isMediumScreen ? 16 : 18);
  double get bodyFontSize => isSmallScreen ? 12 : (isMediumScreen ? 14 : 15);

  double get cardPadding => isSmallScreen ? 12 : (isMediumScreen ? 16 : 18);
  double get itemSpacing => isSmallScreen ? 10 : (isMediumScreen ? 14 : 16);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: itemSpacing),
          _buildGreeting(),
          SizedBox(height: itemSpacing),
          _buildTemperatureCard(),
          SizedBox(height: itemSpacing * 1.5),
          _buildMainMenuSection(context),
          SizedBox(height: itemSpacing * 1.5),
          _buildRealtimeReportSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Image.asset(
            'assets/logo.png',
            width: logoSize,
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ),
        FutureBuilder<Map<String, dynamic>>(
          future: ApiService.getProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey[300],
              );
            }

            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data!['success'] == true) {
              final profileData = snapshot.data!['data'];
              final photoFilename = profileData['profile_image'];
              final photoUrl =
                  photoFilename != null
                      ? 'http://10.0.2.2:5000/uploads/profiles/$photoFilename'
                      : null;

              if (photoUrl != null && photoUrl.isNotEmpty) {
                return CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: NetworkImage(photoUrl),
                );
              }
            }

            return CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: avatarRadius * 0.8,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getProfile(),
      builder: (context, snapshot) {
        String name = "Pengguna";
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!['success'] == true) {
          name = snapshot.data!['data']['name'];
        }
        return Row(
          children: [
            Flexible(
              child: Text(
                "Halo $name",
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.waving_hand,
              color: Colors.amber,
              size: titleFontSize * 1.2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTemperatureCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getLatestTemperature(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "Gagal memuat data suhu",
              style: TextStyle(fontSize: subtitleFontSize),
            ),
          );
        }

        final suhu = snapshot.data!['temperature'].toString();
        final note = snapshot.data!['note'] ?? '-';

        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              isSmallScreen
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Suhu sekitar kandang",
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(note, style: TextStyle(fontSize: bodyFontSize)),
                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "$suhu°C",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: subtitleFontSize * 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Suhu sekitar kandang",
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              note,
                              style: TextStyle(fontSize: bodyFontSize),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$suhu°C",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: subtitleFontSize * 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildMainMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Menu Utama",
          style: TextStyle(
            fontSize: titleFontSize * 0.9,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: itemSpacing),
        FutureBuilder<Map<String, dynamic>>(
          future: ApiService.getLatestWaterLevel(),
          builder: (context, snapshot) {
            String levelStatus = 'Memuat...';

            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data != null) {
              levelStatus = snapshot.data!['status'] ?? '-';
            }

            return _buildMenuItem(
              context: context,
              icon: Icons.water_drop,
              title: "Level Air",
              color: Colors.blue,
              status: levelStatus,
            );
          },
        ),
        SizedBox(height: itemSpacing),
        _buildMenuItem(
          context: context,
          icon: Icons.settings,
          title: "Pompa Manual",
          color: Colors.black87,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PompaManualPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    String? status,
    VoidCallback? onTap,
  }) {
    double containerHeight = isSmallScreen ? 60 : (isMediumScreen ? 70 : 80);
    double iconSize = isSmallScreen ? 18 : (isMediumScreen ? 22 : 26);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: containerHeight,
        padding: EdgeInsets.symmetric(
          horizontal: cardPadding,
          vertical: cardPadding * 0.5,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            SizedBox(width: cardPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: subtitleFontSize,
                    ),
                  ),
                  if (status != null)
                    Text(
                      status,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: bodyFontSize,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Laporan Real-time",
          style: TextStyle(
            fontSize: titleFontSize * 0.9,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: itemSpacing),
        Column(
          children: [
            _buildWaterUsageCard(),
            SizedBox(height: itemSpacing),
            _buildPumpStatusCard(),
          ],
        ),
      ],
    );
  }

  Widget _buildWaterUsageCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<double>(
        future: ApiService.getTodayWaterUsage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: EdgeInsets.all(cardPadding),
              child: Text(
                "Memuat...",
                style: TextStyle(fontSize: bodyFontSize),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Container(
              padding: EdgeInsets.all(cardPadding),
              child: Text(
                "Gagal memuat",
                style: TextStyle(fontSize: bodyFontSize),
              ),
            );
          }

          final usageMl = snapshot.data!;
          final usageLiter = usageMl / 1000;

          final formattedUsage = NumberFormat(
            "#,##0.000",
            "en_US",
          ).format(usageLiter);

          return Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                  size: subtitleFontSize * 1.5,
                ),
                SizedBox(width: cardPadding * 0.75),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Penggunaan air",
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$formattedUsage L",
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPumpStatusCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getLatestPumpStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: EdgeInsets.all(cardPadding),
              child: Text(
                "Memuat status pompa...",
                style: TextStyle(fontSize: bodyFontSize),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Container(
              padding: EdgeInsets.all(cardPadding),
              child: Text(
                "Gagal ambil status pompa",
                style: TextStyle(fontSize: bodyFontSize),
              ),
            );
          }

          final data = snapshot.data!;
          final status = data['status'] == 'on' ? 'Hidup' : 'Mati';
          final mode = data['mode'] == 'auto' ? 'Otomatis' : 'Manual';

          final iconColor = status == 'Hidup' ? Colors.green : Colors.red;

          return Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.power,
                  color: iconColor,
                  size: subtitleFontSize * 1.5,
                ),
                SizedBox(width: cardPadding * 0.75),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Status pompa: $status",
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Mode: $mode",
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
