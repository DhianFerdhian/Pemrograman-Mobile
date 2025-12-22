import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class LocalPdfService {
  // Generate weekly report PDF locally
  Future<String?> generateWeeklyReportPDF(
    List<Map<String, dynamic>> penjualanData,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final pdf = pw.Document();

      // Calculate summary
      final summary = _calculateSummary(penjualanData);

      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader('Laporan Penjualan Mingguan',
                  '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}'),
              pw.SizedBox(height: 20),
              _buildSummary(summary),
              pw.SizedBox(height: 20),
              _buildSalesTable(penjualanData),
              pw.SizedBox(height: 20),
              _buildCategorySummary(summary),
            ];
          },
        ),
      );

      // Save PDF to device
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'laporan_penjualan_mingguan_${DateFormat('yyyy-MM-dd').format(startDate)}_to_${DateFormat('yyyy-MM-dd').format(endDate)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Error generating weekly report PDF: $e');
    }
  }

  // Generate monthly report PDF locally
  Future<String?> generateMonthlyReportPDF(
    List<Map<String, dynamic>> penjualanData,
    int year,
    int month,
  ) async {
    try {
      final pdf = pw.Document();

      // Calculate summary with weekly breakdown
      final summary = _calculateMonthlySummary(penjualanData, year, month);

      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(
                  'Laporan Penjualan Bulanan',
                  DateFormat('MMMM yyyy', 'id_ID')
                      .format(DateTime(year, month))),
              pw.SizedBox(height: 20),
              _buildSummary(summary),
              pw.SizedBox(height: 20),
              _buildWeeklyBreakdown(summary),
              pw.SizedBox(height: 20),
              _buildSalesTable(penjualanData),
              pw.SizedBox(height: 20),
              _buildCategorySummary(summary),
            ];
          },
        ),
      );

      // Save PDF to device
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'laporan_penjualan_bulanan_${year}_${month.toString().padLeft(2, '0')}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Error generating monthly report PDF: $e');
    }
  }

  // Generate daily report PDF locally
  Future<String?> generateDailyReportPDF(
    List<Map<String, dynamic>> penjualanData,
    DateTime date,
  ) async {
    try {
      final pdf = pw.Document();

      // Calculate summary
      final summary = _calculateSummary(penjualanData);

      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader('Laporan Penjualan Harian',
                  DateFormat('dd/MM/yyyy').format(date)),
              pw.SizedBox(height: 20),
              _buildSummary(summary),
              pw.SizedBox(height: 20),
              _buildSalesTable(penjualanData),
              pw.SizedBox(height: 20),
              _buildCategorySummary(summary),
            ];
          },
        ),
      );

      // Save PDF to device
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'laporan_penjualan_harian_${DateFormat('yyyy-MM-dd').format(date)}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Error generating daily report PDF: $e');
    }
  }

  // Generate Excel/CSV content for reports
  Future<String?> generateReportExcel(
    List<Map<String, dynamic>> penjualanData,
    String reportType,
    DateTime startDate,
    DateTime? endDate,
  ) async {
    try {
      // Create CSV content
      final csvContent =
          _generateCSVContent(penjualanData, reportType, startDate, endDate);

      // Save CSV to device
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'laporan_penjualan_${reportType}_${DateFormat('yyyy-MM-dd').format(startDate)}${endDate != null ? '_to_${DateFormat('yyyy-MM-dd').format(endDate)}' : ''}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvContent);

      return file.path;
    } catch (e) {
      throw Exception('Error generating Excel report: $e');
    }
  }

  pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(subtitle,
            style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
      ],
    );
  }

  pw.Widget _buildSummary(Map<String, dynamic> summary) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(currencyFormat.format(summary['totalPendapatan']),
              'Total Pendapatan'),
          _buildSummaryItem(
              summary['totalTransaksi'].toString(), 'Jumlah Transaksi'),
          _buildSummaryItem(
              summary['totalItem'].toString(), 'Total Item Terjual'),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String value, String label) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800)),
        pw.Text(label,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
      ],
    );
  }

  pw.Widget _buildSalesTable(List<Map<String, dynamic>> penjualanData) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Tanggal', isHeader: true),
            _buildTableCell('Nama Produk', isHeader: true),
            _buildTableCell('Kategori', isHeader: true),
            _buildTableCell('Jumlah', isHeader: true),
            _buildTableCell('Harga Satuan', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        ...penjualanData.map((item) {
          final tanggal = DateTime.parse(item['tanggal']);
          return pw.TableRow(
            children: [
              _buildTableCell(DateFormat('dd/MM/yyyy').format(tanggal)),
              _buildTableCell(item['nama']),
              _buildTableCell(item['kategori']),
              _buildTableCell(item['jumlah'].toString()),
              _buildTableCell(currencyFormat.format(item['harga'])),
              _buildTableCell(currencyFormat.format(item['total'])),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  pw.Widget _buildCategorySummary(Map<String, dynamic> summary) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final kategoriSummary = summary['kategoriSummary'] as Map<String, dynamic>;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Ringkasan per Kategori',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...kategoriSummary.entries.map((entry) {
          final percentage = summary['totalPendapatan'] > 0
              ? (entry.value / summary['totalPendapatan'] * 100)
                  .toStringAsFixed(1)
              : '0.0';
          return pw.Container(
            margin: pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(entry.key),
                pw.Text(
                    '${currencyFormat.format(entry.value)} (${percentage}%)'),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildWeeklyBreakdown(Map<String, dynamic> summary) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final weeklySummary = summary['weeklySummary'] as Map<String, dynamic>;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Ringkasan Mingguan',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ...weeklySummary.entries.map((entry) {
          return pw.Container(
            margin: pw.EdgeInsets.only(bottom: 8),
            padding: pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(entry.key,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    'Pendapatan: ${currencyFormat.format(entry.value['pendapatan'])} | Transaksi: ${entry.value['transaksi']} | Item: ${entry.value['item']}'),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _generateCSVContent(
    List<Map<String, dynamic>> penjualanData,
    String reportType,
    DateTime startDate,
    DateTime? endDate,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Laporan Penjualan $reportType');
    buffer.writeln(
        'Periode: ${DateFormat('dd/MM/yyyy').format(startDate)}${endDate != null ? ' - ${DateFormat('dd/MM/yyyy').format(endDate)}' : ''}');
    buffer.writeln('');

    // Column headers
    buffer.writeln('Tanggal,Nama Produk,Kategori,Jumlah,Harga Satuan,Total');

    // Data rows
    for (var item in penjualanData) {
      final tanggal = DateTime.parse(item['tanggal']);
      final dateStr = DateFormat('dd/MM/yyyy').format(tanggal);
      final nama = item['nama'].toString().replaceAll(',', ';');
      final kategori = item['kategori'].toString().replaceAll(',', ';');
      final jumlah = item['jumlah'];
      final harga = item['harga'];
      final total = item['total'];

      buffer.writeln('$dateStr,"$nama","$kategori",$jumlah,$harga,$total');
    }

    return buffer.toString();
  }

  // Open file with default app
  Future<void> openFile(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      throw Exception('Failed to open file: ${result.message}');
    }
  }

  // Calculate summary statistics
  Map<String, dynamic> _calculateSummary(
      List<Map<String, dynamic>> penjualanData) {
    final totalPendapatan =
        penjualanData.fold<int>(0, (sum, item) => sum + (item['total'] as int));
    final totalTransaksi = penjualanData.length;
    final totalItem = penjualanData.fold<int>(
        0, (sum, item) => sum + (item['jumlah'] as int));

    final kategoriMap = <String, int>{};
    for (var item in penjualanData) {
      final kategori = item['kategori'] as String;
      final total = item['total'] as int;
      kategoriMap[kategori] = (kategoriMap[kategori] ?? 0) + total;
    }

    return {
      'totalPendapatan': totalPendapatan,
      'totalTransaksi': totalTransaksi,
      'totalItem': totalItem,
      'kategoriSummary': kategoriMap,
    };
  }

  // Calculate monthly summary with weekly breakdown
  Map<String, dynamic> _calculateMonthlySummary(
      List<Map<String, dynamic>> penjualanData, int year, int month) {
    final summary = _calculateSummary(penjualanData);

    // Calculate weekly breakdown
    final weeklySummary = <String, Map<String, dynamic>>{};
    for (var item in penjualanData) {
      final tanggal = DateTime.parse(item['tanggal']);
      final weekOfMonth = ((tanggal.day - 1) ~/ 7) + 1;
      final weekKey = 'Minggu $weekOfMonth';

      if (!weeklySummary.containsKey(weekKey)) {
        weeklySummary[weekKey] = {'pendapatan': 0, 'transaksi': 0, 'item': 0};
      }

      weeklySummary[weekKey]!['pendapatan'] += item['total'] as int;
      weeklySummary[weekKey]!['transaksi'] += 1;
      weeklySummary[weekKey]!['item'] += item['jumlah'] as int;
    }

    summary['weeklySummary'] = weeklySummary;
    return summary;
  }
}
