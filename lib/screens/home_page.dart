import 'package:flutter/material.dart';
import 'riwayat_page.dart';
import 'notifikasi_page.dart';
import 'user_management/user_list_page.dart';
import 'profile.dart';
import '../services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String? userName;

  final List<Widget> _pages = [
    const DashboardPage(),
    const RiwayatPage(),
    const NotifikasiPage(),
    const ProfilePage(),
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
          userName = response['data']['name'];
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
        items: const [
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
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/logo.png',
                width: isSmallScreen ? 70 : 90,
                height: isSmallScreen ? 65 : 85,
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: ApiService.getProfile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                    );
                  }

                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!['success'] == true) {
                    final profileData = snapshot.data!['data'];
                    final photoUrl = profileData['photo'];

                    if (photoUrl != null && photoUrl.isNotEmpty) {
                      return CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(photoUrl),
                      );
                    }
                  }

                  return const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
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
                  Text(
                    "Halo $name",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.waving_hand, color: Colors.amber, size: 28),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getLatestTemperature(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text("Gagal memuat data suhu"),
                );
              }

              final suhu = snapshot.data!['temperature'].toString();
              final note = snapshot.data!['note'] ?? '-';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Suhu sekitar kandang",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(note, style: const TextStyle(fontSize: 14)),
                      ],
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text(
            "Menu Utama",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              buildMenuItem(
                context,
                icon: Icons.manage_accounts,
                title: "Manajemen Pengguna",
                color: const Color.fromARGB(255, 2, 50, 88),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserListPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>>(
                future: ApiService.getLatestWaterLevel(),
                builder: (context, snapshot) {
                  String levelStatus = 'Memuat...';

                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      snapshot.data != null) {
                    levelStatus = snapshot.data!['status'] ?? '-';
                  }

                  return buildMenuItem(
                    context,
                    icon: Icons.water_drop,
                    title: "Level Air",
                    color: Colors.blue,
                    status: levelStatus,
                  );
                },
              ),

              const SizedBox(height: 12),
              buildMenuItem(
                context,
                icon: Icons.settings,
                title: "Kustom Batas Air",
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Laporan Real-time",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: FutureBuilder<double>(
              future: ApiService.getTodayWaterUsage(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Memuat...");
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text("Gagal memuat");
                }

                final usage = snapshot.data!;
                final formattedUsage = usage
                    .toStringAsFixed(0)
                    .replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.',
                    );

                return Container(
                  padding: const EdgeInsets.all(16),
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
                      Icon(Icons.water_drop, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Penggunaan air",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$formattedUsage ml",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: ApiService.getLatestPumpStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(title: Text("Memuat status pompa..."));
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const ListTile(
                    title: Text("Gagal ambil status pompa"),
                  );
                }

                final data = snapshot.data!;
                final status = data['status'] == 'on' ? 'Hidup' : 'Mati';
                final mode = data['mode'] == 'auto' ? 'Otomatis' : 'Manual';

                final iconColor = status == 'Hidup' ? Colors.green : Colors.red;

                return Container(
                  padding: const EdgeInsets.all(16),
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
                      Icon(Icons.power, color: iconColor, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Status pompa: $status",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Mode: $mode",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    String? status,
    VoidCallback? onTap,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth < 400 ? 12 : 14;
    double containerHeight = screenWidth < 400 ? 65 : 75;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: containerHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
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
                      fontSize: fontSize,
                    ),
                  ),
                  if (status != null)
                    Text(
                      status,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize - 1,
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
}
