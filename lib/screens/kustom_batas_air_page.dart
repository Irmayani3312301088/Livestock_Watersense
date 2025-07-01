import 'package:flutter/material.dart';
import '../services/api_service.dart';

class KustomBatasAirPage extends StatefulWidget {
  final int deviceId;
  const KustomBatasAirPage({super.key, required this.deviceId});

  @override
  _KustomBatasAirPageState createState() => _KustomBatasAirPageState();
}

class _KustomBatasAirPageState extends State<KustomBatasAirPage> {
  int batasAtas = 10;
  int batasBawah = 10;
  bool isLoading = false;

  final int rekomendasiAtas = 20;
  final int rekomendasiBawah = 100;

  // Generate list of values from 0 to 200
  List<int> get valueList => List.generate(201, (index) => index);

  @override
  void initState() {
    super.initState();
    _loadBatasAir();
  }

  Future<void> _loadBatasAir() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.fetchBatasAir(widget.deviceId);
      if (data != null) {
        setState(() {
          batasAtas = (data['batas_atas'] as num).toInt();
          batasBawah = (data['batas_bawah'] as num).toInt();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Gagal memuat data batas air')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _konfirmasi() async {
    if (batasAtas <= batasBawah) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Batas ketinggian harus lebih tinggi dari batas kerendahan!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final success = await ApiService.updateBatasAir(
        deviceId: widget.deviceId,
        batasAtas: batasAtas.toDouble(),
        batasBawah: batasBawah.toDouble(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    success
                        ? 'Batas air berhasil diperbarui!'
                        : 'Gagal memperbarui batas air',
                  ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
          ),
        );

        if (success) {
          // Auto close after successful update
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Terjadi kesalahan saat memperbarui data'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Function to show input dialog for manual entry
  Future<void> _showInputDialog(
    String title,
    int currentValue,
    Function(int) onChanged,
  ) async {
    TextEditingController controller = TextEditingController(
      text: currentValue.toString(),
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Masukkan nilai (0-200)',
                  suffixText: 'cm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF0C1A3E), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                autofocus: true,
              ),
              SizedBox(height: 12),
              Text(
                'Nilai harus antara 0-200 cm',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Simpan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0C1A3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                int? newValue = int.tryParse(controller.text);
                if (newValue != null && newValue >= 0 && newValue <= 200) {
                  onChanged(newValue);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nilai harus antara 0-200'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Custom dropdown widget
  Widget _buildCustomDropdown({
    required String label,
    required int value,
    required Function(int) onChanged,
    required bool isUpperLimit,
  }) {
    Color getIndicatorColor() {
      if (isUpperLimit) {
        return value >= rekomendasiAtas ? Colors.green : Colors.orange;
      } else {
        return value <= rekomendasiBawah ? Colors.green : Colors.orange;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: getIndicatorColor(),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showInputDialog(label, value, onChanged),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isUpperLimit ? Icons.arrow_upward : Icons.arrow_downward,
                      color: getIndicatorColor(),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$value cm',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    PopupMenuButton<int>(
                      icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                      onSelected: (int newValue) {
                        onChanged(newValue);
                      },
                      itemBuilder: (BuildContext context) {
                        return valueList.map((int value) {
                          return PopupMenuItem<int>(
                            value: value,
                            child: Text('$value cm'),
                          );
                        }).toList();
                      },
                      offset: Offset(0, 50),
                      constraints: BoxConstraints(
                        maxHeight: 300,
                        minWidth: 100,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${value}cm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kustom Batas Air',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0C1A3E),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat data...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 20,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 600 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status indicator
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    batasAtas > batasBawah
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      batasAtas > batasBawah
                                          ? Colors.green[200]!
                                          : Colors.orange[200]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    batasAtas > batasBawah
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color:
                                        batasAtas > batasBawah
                                            ? Colors.green
                                            : Colors.orange,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      batasAtas > batasBawah
                                          ? 'Konfigurasi valid'
                                          : 'Batas ketinggian harus lebih tinggi dari batas kerendahan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            batasAtas > batasBawah
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24),

                            // Batas Ketinggian Air
                            _buildCustomDropdown(
                              label: 'Batas Ketinggian Air',
                              value: batasAtas,
                              isUpperLimit: true,
                              onChanged: (int newValue) {
                                setState(() {
                                  batasAtas = newValue;
                                });
                              },
                            ),

                            SizedBox(height: 24),

                            // Batas Kerendahan Air
                            _buildCustomDropdown(
                              label: 'Batas Kerendahan Air',
                              value: batasBawah,
                              isUpperLimit: false,
                              onChanged: (int newValue) {
                                setState(() {
                                  batasBawah = newValue;
                                });
                              },
                            ),

                            SizedBox(height: 32),

                            // Recommendations Section
                            Text(
                              'Rekomendasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),

                            _buildRecommendationCard(
                              title: 'Batas Ketinggian Ideal',
                              value: rekomendasiAtas,
                              icon: Icons.arrow_upward,
                              color: Colors.blue,
                            ),

                            SizedBox(height: 12),

                            _buildRecommendationCard(
                              title: 'Batas Kerendahan Ideal',
                              value: rekomendasiBawah,
                              icon: Icons.arrow_downward,
                              color: Colors.indigo,
                            ),

                            SizedBox(height: 24),

                            // Quick action buttons
                            Text(
                              'Aksi Cepat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        batasAtas = rekomendasiAtas;
                                        batasBawah = rekomendasiBawah;
                                      });
                                    },
                                    icon: Icon(Icons.auto_fix_high, size: 16),
                                    label: Text('Gunakan Rekomendasi'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Color(0xFF0C1A3E),
                                      side: BorderSide(
                                        color: Color(0xFF0C1A3E),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Button Area
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 400 : double.infinity,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _konfirmasi,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C1A3E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child:
                                isLoading
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Simpan Perubahan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
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
