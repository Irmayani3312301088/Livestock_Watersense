import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../helpers/role_navigation_helper.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<Map<String, dynamic>> _riwayatData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiwayatData();
  }

  Future<void> _fetchRiwayatData() async {
    try {
      final data = await ApiService.getWaterUsageHistory();
      setState(() {
        _riwayatData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> exportRiwayatToPdf(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Riwayat Penggunaan Air',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ['Tanggal', 'Penggunaan (L)'],
                  data:
                      data.map((item) {
                        final tanggal = _formatTanggal(item['date'] ?? '-');
                        final usageMl = item['total_usage'] ?? 0;
                        final usageLiter = usageMl / 1000;
                        final total = usageLiter.toStringAsFixed(3);
                        return [tanggal, total];
                      }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String _formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);
      return "${date.day.toString().padLeft(2, '0')} ${_namaBulan(date.month)} ${date.year}";
    } catch (_) {
      return tanggal;
    }
  }

  String _namaBulan(int bulan) {
    const namaBulan = [
      "",
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    return namaBulan[bulan];
  }

  // Helper method untuk menentukan breakpoint
  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  bool _isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Method untuk mendapatkan padding responsif
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = _isTablet(context);

    if (isTablet) {
      return EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: 24);
    } else {
      return EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 20);
    }
  }

  // Method untuk mendapatkan ukuran font responsif
  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = _isTablet(context);

    if (isTablet) {
      return baseFontSize * 1.2;
    } else if (screenWidth < 350) {
      return baseFontSize * 0.9;
    }
    return baseFontSize;
  }

  // Method untuk mendapatkan spacing responsif
  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final isTablet = _isTablet(context);
    return isTablet ? baseSpacing * 1.5 : baseSpacing;
  }

  // Method untuk mendapatkan grid count untuk layout tablet
  int _getCrossAxisCount(BuildContext context) {
    final isLandscape = _isLandscape(context);

    if (_isTablet(context)) {
      return isLandscape ? 3 : 2;
    }
    return 1; // Selalu 1 column untuk phone
  }

  Widget _buildRiwayatItem(BuildContext context, Map<String, dynamic> item) {
    final tanggal = item["date"] ?? "-";
    final usageMl = double.tryParse(item["total_usage"].toString()) ?? 0.0;
    final usageLiter = usageMl / 1000;
    final jumlah = NumberFormat("#,##0.000", "en_US").format(usageLiter);

    final isTablet = _isTablet(context);

    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_getResponsiveSpacing(context, 16)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          vertical: _getResponsiveSpacing(context, 12),
          horizontal: _getResponsiveSpacing(context, 16),
        ),
        leading: Container(
          padding: EdgeInsets.all(_getResponsiveSpacing(context, 8)),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(
              _getResponsiveSpacing(context, 12),
            ),
          ),
          child: Icon(
            Icons.calendar_today,
            color: Colors.white,
            size: isTablet ? 28 : 24,
          ),
        ),
        title: Text(
          _formatTanggal(tanggal),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: _getResponsiveFontSize(context, 16),
          ),
        ),
        subtitle: Text(
          "$jumlah L",
          style: TextStyle(
            color: Colors.black87,
            fontSize: _getResponsiveFontSize(context, 14),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_riwayatData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: _isTablet(context) ? 80 : 60,
              color: Colors.grey[400],
            ),
            SizedBox(height: _getResponsiveSpacing(context, 16)),
            Text(
              "Tidak ada data riwayat.",
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = _getCrossAxisCount(context);

    if (crossAxisCount > 1) {
      // Grid layout untuk tablet
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: _getResponsiveSpacing(context, 16),
          mainAxisSpacing: _getResponsiveSpacing(context, 16),
          childAspectRatio: 2.5,
        ),
        itemCount: _riwayatData.length,
        itemBuilder: (context, index) {
          return _buildRiwayatItem(context, _riwayatData[index]);
        },
      );
    } else {
      // List layout untuk phone
      return ListView.builder(
        itemCount: _riwayatData.length,
        itemBuilder: (context, index) {
          return _buildRiwayatItem(context, _riwayatData[index]);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = _isTablet(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Riwayat Penggunaan Air',
          style: TextStyle(
            color: Colors.black,
            fontSize: _getResponsiveFontSize(context, 20),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
          onPressed: () {
            RoleNavigationHelper.goToDashboard(context);
          },
        ),

        // Tambahkan action untuk refresh di tablet
        actions:
            isTablet
                ? [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _fetchRiwayatData();
                    },
                  ),
                  const SizedBox(width: 8),
                ]
                : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: _getResponsivePadding(context),
          child: _buildContent(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _riwayatData.isNotEmpty
                ? () => exportRiwayatToPdf(_riwayatData)
                : null,
        label: Text(
          'Ekspor PDF',
          style: TextStyle(fontSize: _getResponsiveFontSize(context, 14)),
        ),
        icon: Icon(Icons.picture_as_pdf, size: isTablet ? 24 : 20),
        backgroundColor: _riwayatData.isNotEmpty ? null : Colors.grey,
      ),
    );
  }
}
