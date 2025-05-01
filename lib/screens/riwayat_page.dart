import 'package:flutter/material.dart';
import 'home_page.dart';

class RiwayatPage extends StatefulWidget {
  RiwayatPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage>
    with TickerProviderStateMixin {
  final List<Map<String, String>> _riwayatData = [
    {"tanggal": "08 April 2025", "jumlah": "11,875 ml"},
    {"tanggal": "09 April 2025", "jumlah": "21,567 ml"},
    {"tanggal": "10 April 2025", "jumlah": "1,349 ml"},
    {"tanggal": "11 April 2025", "jumlah": "50,987 ml"},
  ];

  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_riwayatData.length, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + index * 100),
      )..forward();
    });

    _animations =
        _controllers.map((controller) {
          return Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
        }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100), // Mengatur tinggi AppBar
        child: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          leading: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => _handleBack(context),
            ),
          ),
          centerTitle: true,
          title: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "Riwayat Penggunaan Air",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: ListView.builder(
            itemCount: _riwayatData.length,
            itemBuilder: (context, index) {
              final item = _riwayatData[index];
              return SlideTransition(
                position: _animations[index],
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Tanggal: ${item["tanggal"]} - Jumlah: ${item["jumlah"]}",
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          item["tanggal"] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          item["jumlah"] ?? "",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
