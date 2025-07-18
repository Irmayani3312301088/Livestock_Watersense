import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/api_service.dart';
import '../../services/mqtt_service.dart';

class PompaManualPage extends StatefulWidget {
  @override
  _PompaManualPageState createState() => _PompaManualPageState();
}

class _PompaManualPageState extends State<PompaManualPage> {
  final MQTTService mqtt = MQTTService();
  bool isPompaOn = false;
  String levelAir = '...';
  bool isLoadingLevel = false;

  final String batasAtas = '20cm';
  final String batasBawah = '100cm';

  @override
  void initState() {
    super.initState();
    _loadStatusPompa();
    _loadWaterLevel();
  }

  void _loadStatusPompa() async {
    try {
      final status = await ApiService().getStatusPompa();
      setState(() {
        isPompaOn = status == 'on';
      });
    } catch (e) {
      print('Gagal ambil status pompa: $e');
    }
  }

  void _togglePompa() async {
    final newStatus = isPompaOn ? 'off' : 'on';
    final success = await ApiService().ubahStatusPompa(newStatus);
    if (success) {
      setState(() {
        isPompaOn = !isPompaOn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pompa ${newStatus == 'on' ? 'dinyalakan' : 'dimatikan'}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah status pompa')));
    }
  }

  void _konfirmasiPompa() async {
    final success = await ApiService().kirimKonfirmasi(
      levelAir: levelAir,
      batasKetinggian: batasAtas,
      batasRendah: batasBawah,
      statusPompa: isPompaOn ? 'on' : 'off',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Konfirmasi berhasil' : 'Gagal konfirmasi'),
      ),
    );
  }

  void _loadWaterLevel() async {
    setState(() {
      isLoadingLevel = true;
    });

    try {
      final data = await ApiService.getLatestWaterLevel();
      setState(() {
        levelAir =
            '${data['level']} cm'; // Sesuaikan dengan struktur response API Anda
      });
    } catch (e) {
      print('Gagal ambil level air: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat level air terbaru')));
    } finally {
      setState(() {
        isLoadingLevel = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // Background putih
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Pompa Manual',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, // 5% dari lebar layar
          vertical: 20,
        ),
        child: Column(
          children: [
            // Tombol Power
            GestureDetector(
              onTap: _togglePompa,
              child: Container(
                width: screenWidth * 0.3, // 30% dari lebar layar
                height: screenWidth * 0.3, // Persegi
                decoration: BoxDecoration(
                  color: isPompaOn ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isPompaOn ? Colors.green : Colors.red)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.power_settings_new,
                  color: Colors.white,
                  size: screenWidth * 0.12, // 12% dari lebar layar
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.03), // 3% dari tinggi layar
            // Status Pompa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isPompaOn ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPompaOn ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPompaOn ? Icons.check_circle : Icons.cancel,
                    color: isPompaOn ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pompa ${isPompaOn ? 'Menyala' : 'Mati'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPompaOn ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.04), // 4% dari tinggi layar
            // Kartu Peringatan - Responsif
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: screenWidth * 0.08, // 8% dari lebar layar
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Perhatian!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.042, // Responsif
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Pastikan batas air sesuai sebelum menyalakan pompa.",
                            style: TextStyle(
                              fontSize: screenWidth * 0.035, // Responsif
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Data Monitoring - Tanpa Text Field
            buildDataTile(
              'Level Air Sekarang',
              isLoadingLevel ? 'Memuat...' : levelAir,
              icon: Icons.water_drop,
              color: const Color(0xFFF4B740),
            ),
            const SizedBox(height: 12),
            buildDataTile(
              'Batas Ketinggian',
              batasAtas,
              icon: Icons.height,
              color: Colors.blue.shade50,
            ),
            const SizedBox(height: 12),
            buildDataTile(
              'Batas Rendah',
              batasBawah,
              icon: Icons.low_priority,
              color: Colors.red.shade50,
            ),

            SizedBox(height: screenHeight * 0.04),

            // Tombol Konfirmasi - Responsif
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _konfirmasiPompa,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002F6C),
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02, // 2% dari tinggi layar
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  'Konfirmasi',
                  style: TextStyle(
                    fontSize: screenWidth * 0.042, // Responsif
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget buildDataTile(
    String label,
    String value, {
    Color color = Colors.white,
    IconData? icon,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: screenWidth * 0.05, color: Colors.grey.shade600),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: screenWidth * 0.04,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.04,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
