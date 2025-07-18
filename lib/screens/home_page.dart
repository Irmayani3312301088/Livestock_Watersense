import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'riwayat_page.dart';
import 'notifikasi_page.dart';
import 'user_management/user_list_page.dart';
import 'profile.dart';
import 'kustom_batas_air_page.dart';
import '../services/api_service.dart';
import '../services/mqtt_service.dart';

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
  final MQTTService mqttService = MQTTService();

  double? currentTemperature;
  double? currentHumidity;
  String? pumpStatus;
  double? waterLevel;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _connectToMqtt();
    _pages = [
      DashboardPage(mqttService: mqttService),
      const RiwayatPage(),
      const NotifikasiPage(),
      const ProfilePage(),
    ];
  }

  Future<void> _connectToMqtt() async {
    try {
      await mqttService.connect();
      mqttService.sensorDataStream.listen((data) {
        setState(() {
          currentTemperature = data['temperature'];
          currentHumidity = data['humidity'];
        });
      });
      mqttService.pumpStatusStream.listen((data) {
        setState(() {
          pumpStatus = data['status'];
        });
      });
      mqttService.waterLevelStream.listen((data) {
        setState(() {
          waterLevel = data['level'];
        });
      });
      mqttService.livestockDataStream.listen((data) {});
    } catch (e) {
      print('Error connecting to MQTT: $e');
    }
  }

  @override
  void dispose() {
    mqttService.disconnect();
    super.dispose();
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

class DashboardPage extends StatefulWidget {
  final MQTTService mqttService;
  const DashboardPage({super.key, required this.mqttService});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<Map<String, dynamic>>? _pumpStatusFuture;

  bool? isAutoMode;

  @override
  void initState() {
    super.initState();
    _pumpStatusFuture = ApiService.getLatestPumpStatus();
    _loadInitialPumpMode();
  }

  void _loadInitialPumpMode() async {
    try {
      final data = await ApiService.getLatestPumpStatus();
      setState(() {
        isAutoMode = data['mode'] == 'auto';
      });
    } catch (e) {
      print('Gagal ambil data mode pompa: $e');
    }
  }

  DeviceType _getDeviceType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return DeviceType.small;
    if (screenWidth < 600) return DeviceType.medium;
    if (screenWidth < 1024) return DeviceType.large;
    return DeviceType.extraLarge;
  }

  EdgeInsets _getResponsivePadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
      case DeviceType.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
      case DeviceType.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
      case DeviceType.extraLarge:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 28);
    }
  }

  double _getResponsiveFontSize(DeviceType deviceType, TextSizeType type) {
    switch (type) {
      case TextSizeType.title:
        switch (deviceType) {
          case DeviceType.small:
            return 20;
          case DeviceType.medium:
            return 24;
          case DeviceType.large:
            return 28;
          case DeviceType.extraLarge:
            return 32;
        }
      case TextSizeType.subtitle:
        switch (deviceType) {
          case DeviceType.small:
            return 16;
          case DeviceType.medium:
            return 18;
          case DeviceType.large:
            return 20;
          case DeviceType.extraLarge:
            return 22;
        }
      case TextSizeType.body:
        switch (deviceType) {
          case DeviceType.small:
            return 12;
          case DeviceType.medium:
            return 14;
          case DeviceType.large:
            return 16;
          case DeviceType.extraLarge:
            return 18;
        }
      case TextSizeType.caption:
        switch (deviceType) {
          case DeviceType.small:
            return 10;
          case DeviceType.medium:
            return 12;
          case DeviceType.large:
            return 14;
          case DeviceType.extraLarge:
            return 16;
        }
    }
  }

  Widget buildPumpModeControl(
    BuildContext context, {
    required DeviceType deviceType,
    required bool isAutoMode,
    required Function(bool) onChanged,
  }) {
    double containerHeight =
        deviceType == DeviceType.small
            ? 60
            : deviceType == DeviceType.medium
            ? 70
            : 80;

    return Container(
      width: double.infinity,
      height: containerHeight,
      padding: EdgeInsets.symmetric(
        horizontal: deviceType == DeviceType.small ? 12 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_suggest,
            color: Colors.white,
            size: _getResponsiveFontSize(deviceType, TextSizeType.title),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Mode Pompa",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: _getResponsiveFontSize(
                      deviceType,
                      TextSizeType.body,
                    ),
                  ),
                ),
                Text(
                  isAutoMode ? "Otomatis" : "Manual",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(
                      deviceType,
                      TextSizeType.caption,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAutoMode,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: isAutoMode ? Colors.green : Colors.red,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor:
                isAutoMode ? Colors.green : Colors.red.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final double logoSize =
        deviceType == DeviceType.small
            ? 60
            : (deviceType == DeviceType.medium ? 75 : 90);

    final double avatarSize =
        deviceType == DeviceType.small
            ? 22
            : (deviceType == DeviceType.medium ? 26 : 30);

    return SingleChildScrollView(
      padding: _getResponsivePadding(deviceType),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan logo dan profile
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo dengan ukuran lebih besar dan stabil
              Container(
                width: logoSize,
                height: logoSize,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Image.asset('assets/logo.png'),
                ),
              ),

              // photo profile
              FutureBuilder<Map<String, dynamic>>(
                future: ApiService.getProfile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      radius: avatarSize,
                      backgroundColor: Colors.grey[300],
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }

                  if (snapshot.hasData &&
                      snapshot.data!['success'] == true &&
                      snapshot.data!['data']['profile_image'] != null) {
                    final imageUrl =
                        'http://10.0.2.2:5000/uploads/profiles/${snapshot.data!['data']['profile_image']}';
                    return CircleAvatar(
                      radius: avatarSize,
                      backgroundImage: NetworkImage(imageUrl),
                    );
                  }

                  return CircleAvatar(
                    radius: avatarSize,
                    backgroundColor: Colors.grey,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: avatarSize * 0.8,
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: deviceType == DeviceType.small ? 12 : 16),

          // Greeting
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
                  Flexible(
                    child: Text(
                      "Halo $name",
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(
                          deviceType,
                          TextSizeType.title,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.waving_hand,
                    color: Colors.amber,
                    size:
                        _getResponsiveFontSize(deviceType, TextSizeType.title) +
                        4,
                  ),
                ],
              );
            },
          ),

          SizedBox(height: deviceType == DeviceType.small ? 12 : 16),

          // Temperature Card
          FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getLatestTemperature(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: EdgeInsets.all(
                    deviceType == DeviceType.small ? 12 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Container(
                  padding: EdgeInsets.all(
                    deviceType == DeviceType.small ? 12 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Gagal memuat data suhu",
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(
                        deviceType,
                        TextSizeType.body,
                      ),
                    ),
                  ),
                );
              }

              final suhu =
                  snapshot.data!['temperature']?.toStringAsFixed(1) ?? '-';
              final status = snapshot.data!['status'] ?? '-';
              final note = snapshot.data!['note'] ?? '-';

              Color backgroundColor;
              if (status == 'Panas') {
                backgroundColor = Colors.red[100]!;
              } else if (status == 'Dingin') {
                backgroundColor = Colors.deepPurple[100]!;
              } else {
                backgroundColor = Colors.blue[50]!;
              }

              return Container(
                padding: EdgeInsets.all(
                  deviceType == DeviceType.small ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    isTablet
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Suhu sekitar kandang",
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        deviceType,
                                        TextSizeType.subtitle,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note,
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        deviceType,
                                        TextSizeType.body,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$suhu°C",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _getResponsiveFontSize(
                                    deviceType,
                                    TextSizeType.title,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Suhu sekitar kandang",
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        deviceType,
                                        TextSizeType.subtitle,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    note,
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(
                                        deviceType,
                                        TextSizeType.body,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$suhu°C",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _getResponsiveFontSize(
                                    deviceType,
                                    TextSizeType.subtitle,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
              );
            },
          ),

          SizedBox(height: deviceType == DeviceType.small ? 16 : 24),

          // Menu Utama
          Text(
            "Menu Utama",
            style: TextStyle(
              fontSize: _getResponsiveFontSize(
                deviceType,
                TextSizeType.subtitle,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: deviceType == DeviceType.small ? 8 : 12),

          // Menu items - Grid layout untuk tablet
          isTablet
              ? GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3.5,
                children: [
                  buildMenuItem(
                    context,
                    deviceType: deviceType,
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
                        deviceType: deviceType,
                        icon: Icons.water_drop,
                        title: "Level Air",
                        color: Colors.blue,
                        status: levelStatus,
                      );
                    },
                  ),
                  buildMenuItem(
                    context,
                    deviceType: deviceType,
                    icon: Icons.settings,
                    title: "Kustom Batas Air",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KustomBatasAirPage(deviceId: 1),
                        ),
                      );
                    },
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _pumpStatusFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData &&
                          snapshot.data != null) {
                        isAutoMode = snapshot.data!['mode'] == 'auto';
                      }

                      return buildPumpModeControl(
                        context,
                        deviceType: deviceType,
                        isAutoMode: isAutoMode ?? true,
                        onChanged: (bool newMode) async {
                          try {
                            String modeStr = newMode ? 'auto' : 'manual';
                            await ApiService.setPumpMode(modeStr);

                            setState(() {
                              isAutoMode = newMode;
                              _pumpStatusFuture =
                                  ApiService.getLatestPumpStatus();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Mode pompa berhasil diubah'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal mengubah mode pompa'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              )
              : Column(
                children: [
                  buildMenuItem(
                    context,
                    deviceType: deviceType,
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
                        deviceType: deviceType,
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
                    deviceType: deviceType,
                    icon: Icons.settings,
                    title: "Kustom Batas Air",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KustomBatasAirPage(deviceId: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _pumpStatusFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData &&
                          snapshot.data != null) {
                        isAutoMode = snapshot.data!['mode'] == 'auto';
                      }

                      return buildPumpModeControl(
                        context,
                        deviceType: deviceType,
                        isAutoMode: isAutoMode ?? true,
                        onChanged: (bool newMode) async {
                          try {
                            String modeStr = newMode ? 'auto' : 'manual';
                            await ApiService.setPumpMode(modeStr);

                            setState(() {
                              isAutoMode =
                                  newMode; // ini yang bikin Switch berubah
                              _pumpStatusFuture =
                                  ApiService.getLatestPumpStatus();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Mode pompa berhasil diubah'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal mengubah mode pompa'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),

          SizedBox(height: deviceType == DeviceType.small ? 16 : 24),

          // Laporan Real-time
          Text(
            "Laporan Real-time",
            style: TextStyle(
              fontSize: _getResponsiveFontSize(
                deviceType,
                TextSizeType.subtitle,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: deviceType == DeviceType.small ? 12 : 16),

          // Real-time cards - Grid untuk tablet
          isTablet
              ? GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildWaterUsageCard(deviceType),
                  _buildPumpStatusCard(deviceType),
                ],
              )
              : Column(
                children: [
                  _buildWaterUsageCard(deviceType),
                  const SizedBox(height: 12),
                  _buildPumpStatusCard(deviceType),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildWaterUsageCard(DeviceType deviceType) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<double>(
        future: ApiService.getTodayWaterUsage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: EdgeInsets.all(deviceType == DeviceType.small ? 12 : 16),
              child: Text(
                "Memuat...",
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(
                    deviceType,
                    TextSizeType.body,
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(deviceType == DeviceType.small ? 12 : 16),
              child: Text(
                "Gagal memuat data air hari ini",
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(
                    deviceType,
                    TextSizeType.body,
                  ),
                ),
              ),
            );
          }

          final usageMl = snapshot.data!;
          final usageLiter = usageMl / 1000;

          final formatter = NumberFormat("#,##0.000", "en_US");
          final formattedUsage = formatter.format(usageLiter);

          return Container(
            padding: EdgeInsets.all(deviceType == DeviceType.small ? 12 : 16),
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
                  size: _getResponsiveFontSize(deviceType, TextSizeType.title),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Penggunaan air",
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(
                            deviceType,
                            TextSizeType.subtitle,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$formattedUsage L",
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(
                            deviceType,
                            TextSizeType.body,
                          ),
                          color: Colors.black,
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

  Widget _buildPumpStatusCard(DeviceType deviceType) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getLatestPumpStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: EdgeInsets.all(deviceType == DeviceType.small ? 12 : 16),
              child: Text(
                "Memuat status pompa...",
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(
                    deviceType,
                    TextSizeType.body,
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(deviceType == DeviceType.small ? 12 : 16),
              child: Text(
                "Gagal ambil status pompa",
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(
                    deviceType,
                    TextSizeType.body,
                  ),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final statusRaw = data['status']?.toString().toLowerCase();
          final status = statusRaw == 'on' ? 'Hidup' : 'Mati';
          final mode = data['mode'] == 'auto' ? 'Otomatis' : 'Manual';
          final iconColor = status == 'Hidup' ? Colors.green : Colors.red;

          return Container(
            padding: EdgeInsets.all(deviceType == DeviceType.small ? 12 : 16),
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
                  size: _getResponsiveFontSize(deviceType, TextSizeType.title),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Status pompa: $status",
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(
                            deviceType,
                            TextSizeType.subtitle,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Mode: $mode",
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(
                            deviceType,
                            TextSizeType.body,
                          ),
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

  Widget buildMenuItem(
    BuildContext context, {
    required DeviceType deviceType,
    required IconData icon,
    required String title,
    required Color color,
    String? status,
    VoidCallback? onTap,
  }) {
    double containerHeight =
        deviceType == DeviceType.small
            ? 60
            : deviceType == DeviceType.medium
            ? 70
            : 80;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: containerHeight,
        padding: EdgeInsets.symmetric(
          horizontal: deviceType == DeviceType.small ? 12 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: _getResponsiveFontSize(deviceType, TextSizeType.title),
            ),
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
                      fontSize: _getResponsiveFontSize(
                        deviceType,
                        TextSizeType.body,
                      ),
                    ),
                  ),
                  if (status != null)
                    Text(
                      status,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(
                          deviceType,
                          TextSizeType.caption,
                        ),
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

// Enums untuk responsive design
enum DeviceType { small, medium, large, extraLarge }

enum TextSizeType { title, subtitle, body, caption }
