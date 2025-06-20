import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:Livestock_Watersense/screens/home_page.dart';
import '../services/api_service.dart';

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
          return pw.Column(
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
                headers: ['Tanggal', 'Penggunaan (ml)'],
                data:
                    data.map((item) {
                      final tanggal = _formatTanggal(item['date'] ?? '-');
                      final total =
                          item['total_usage']?.toStringAsFixed(0) ?? '0';
                      return [tanggal, total];
                    }).toList(),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Riwayat Penggunaan Air',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ), // ⬅️ warna ikon back
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _riwayatData.isEmpty
                  ? const Center(child: Text("Tidak ada data riwayat."))
                  : ListView.builder(
                    itemCount: _riwayatData.length,
                    itemBuilder: (context, index) {
                      final item = _riwayatData[index];
                      final tanggal = item["date"] ?? "-";
                      final jumlah =
                          item["total_usage"]?.toStringAsFixed(0) ?? "0";

                      return Container(
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
                            _formatTanggal(tanggal),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            "$jumlah ml",
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => exportRiwayatToPdf(_riwayatData),
        label: const Text('Ekspor PDF'),
        icon: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
