import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Tanggal', 'Penggunaan (ml)'],
              data:
                  data.map((item) {
                    final tanggal = item['date'] ?? '-';
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
