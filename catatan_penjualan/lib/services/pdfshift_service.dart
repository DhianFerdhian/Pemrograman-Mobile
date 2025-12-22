import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class PdfShiftService {
  static const String _apiKey = 'sk_61b708af8e39a78aa7c7af0c672c117d153168da';
  static const String _baseUrl = 'https://api.pdfshift.io/v3/convert/pdf';

  // Generate HTML content for weekly report
  String _generateWeeklyReportHTML(
    List<Map<String, dynamic>> penjualanData,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic> summary,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Laporan Penjualan Mingguan</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .summary { background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .summary-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; }
        .summary-item { text-align: center; }
        .summary-value { font-size: 24px; font-weight: bold; color: #2e7d32; }
        .summary-label { color: #666; font-size: 14px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; font-weight: bold; }
        .category-section { margin: 30px 0; }
        .category-header { background: #e3f2fd; padding: 10px; margin: 20px 0 10px 0; border-radius: 4px; }
        .total-row { background: #fff3e0; font-weight: bold; }
        .date-range { color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Laporan Penjualan Mingguan</h1>
        <p class="date-range">${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}</p>
    </div>

    <div class="summary">
        <div class="summary-grid">
            <div class="summary-item">
                <div class="summary-value">${currencyFormat.format(summary['totalPendapatan'])}</div>
                <div class="summary-label">Total Pendapatan</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">${summary['totalTransaksi']}</div>
                <div class="summary-label">Jumlah Transaksi</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">${summary['totalItem']}</div>
                <div class="summary-label">Total Item Terjual</div>
            </div>
        </div>
    </div>

    <h2>Detail Penjualan</h2>
    <table>
        <thead>
            <tr>
                <th>Tanggal</th>
                <th>Nama Produk</th>
                <th>Kategori</th>
                <th>Jumlah</th>
                <th>Harga Satuan</th>
                <th>Total</th>
            </tr>
        </thead>
        <tbody>
''';

    for (var item in penjualanData) {
      final tanggal = DateTime.parse(item['tanggal']);
      html += '''
            <tr>
                <td>${dateFormat.format(tanggal)}</td>
                <td>${item['nama']}</td>
                <td>${item['kategori']}</td>
                <td>${item['jumlah']}</td>
                <td>${currencyFormat.format(item['harga'])}</td>
                <td>${currencyFormat.format(item['total'])}</td>
            </tr>
''';
    }

    html += '''
        </tbody>
    </table>

    <div class="summary">
        <h3>Ringkasan per Kategori</h3>
''';

    final kategoriSummary = summary['kategoriSummary'] as Map<String, dynamic>;
    for (var entry in kategoriSummary.entries) {
      final percentage = summary['totalPendapatan'] > 0
          ? (entry.value / summary['totalPendapatan'] * 100).toStringAsFixed(1)
          : '0.0';
      html += '''
        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee;">
            <span>${entry.key}</span>
            <span>${currencyFormat.format(entry.value)} (${percentage}%)</span>
        </div>
''';
    }

    html += '''
    </div>
</body>
</html>''';

    return html;
  }

  // Generate HTML content for monthly report
  String _generateMonthlyReportHTML(
    List<Map<String, dynamic>> penjualanData,
    int year,
    int month,
    Map<String, dynamic> summary,
  ) {
    final monthName =
        DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month));
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Laporan Penjualan Bulanan - $monthName</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .summary { background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .summary-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; }
        .summary-item { text-align: center; }
        .summary-value { font-size: 24px; font-weight: bold; color: #2e7d32; }
        .summary-label { color: #666; font-size: 14px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; font-weight: bold; }
        .category-section { margin: 30px 0; }
        .category-header { background: #e3f2fd; padding: 10px; margin: 20px 0 10px 0; border-radius: 4px; }
        .total-row { background: #fff3e0; font-weight: bold; }
        .weekly-breakdown { margin: 30px 0; }
        .week-header { background: #f5f5f5; padding: 10px; margin: 15px 0 5px 0; border-radius: 4px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Laporan Penjualan Bulanan</h1>
        <h2>$monthName</h2>
    </div>

    <div class="summary">
        <div class="summary-grid">
            <div class="summary-item">
                <div class="summary-value">${currencyFormat.format(summary['totalPendapatan'])}</div>
                <div class="summary-label">Total Pendapatan</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">${summary['totalTransaksi']}</div>
                <div class="summary-label">Jumlah Transaksi</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">${summary['totalItem']}</div>
                <div class="summary-label">Total Item Terjual</div>
            </div>
        </div>
    </div>

    <div class="weekly-breakdown">
        <h2>Ringkasan Mingguan</h2>
''';

    final weeklySummary = summary['weeklySummary'] as Map<String, dynamic>;
    for (var entry in weeklySummary.entries) {
      html += '''
        <div class="week-header">${entry.key}</div>
        <div style="margin-left: 20px; margin-bottom: 15px;">
            Pendapatan: ${currencyFormat.format(entry.value['pendapatan'])} |
            Transaksi: ${entry.value['transaksi']} |
            Item: ${entry.value['item']}
        </div>
''';
    }

    html += '''
    </div>

    <h2>Detail Penjualan</h2>
    <table>
        <thead>
            <tr>
                <th>Tanggal</th>
                <th>Nama Produk</th>
                <th>Kategori</th>
                <th>Jumlah</th>
                <th>Harga Satuan</th>
                <th>Total</th>
            </tr>
        </thead>
        <tbody>
''';

    for (var item in penjualanData) {
      final tanggal = DateTime.parse(item['tanggal']);
      final dateFormat = DateFormat('dd/MM/yyyy');
      html += '''
            <tr>
                <td>${dateFormat.format(tanggal)}</td>
                <td>${item['nama']}</td>
                <td>${item['kategori']}</td>
                <td>${item['jumlah']}</td>
                <td>${currencyFormat.format(item['harga'])}</td>
                <td>${currencyFormat.format(item['total'])}</td>
            </tr>
''';
    }

    html += '''
        </tbody>
    </table>

    <div class="summary">
        <h3>Ringkasan per Kategori</h3>
''';

    final kategoriSummary = summary['kategoriSummary'] as Map<String, dynamic>;
    for (var entry in kategoriSummary.entries) {
      final percentage = summary['totalPendapatan'] > 0
          ? (entry.value / summary['totalPendapatan'] * 100).toStringAsFixed(1)
          : '0.0';
      html += '''
        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee;">
            <span>${entry.key}</span>
            <span>${currencyFormat.format(entry.value)} (${percentage}%)</span>
        </div>
''';
    }

    html += '''
    </div>
</body>
</html>''';

    return html;
  }

  // Generate HTML content for daily report
  String _generateDailyReportHTML(
    List<Map<String, dynamic>> penjualanData,
    DateTime date,
    Map<String, dynamic> summary,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Laporan Penjualan Harian - ${dateFormat.format(date)}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .summary { background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .summary-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; }
        .summary-item { text-align: center; }
        .summary-value { font-size: 24px; font-weight: bold; color: #2e7d32; }
        .summary-label { color: #666; font-size: 14px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; font-weight: bold; }
        .category-section { margin: 30px 0; }
        .category-header { background: #e3f2fd; padding: 10px; margin: 20px 0 10px 0; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Laporan Penjualan Harian</h1>
        <h2>${dateFormat.format(date)}</h2>
    </div>

    <div class="summary">
        <div class="summary-grid">
            <div class="summary-item">
                <div class="summary-value">${currencyFormat.format(summary['totalPendapatan'])}</div>
                <div class="summary-label">Total Pendapatan</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">${summary['totalTransaksi']}</div>
                <div class="summary-label">Jumlah Transaksi</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">${summary['totalItem']}</div>
                <div class="summary-label">Total Item Terjual</div>
            </div>
        </div>
    </div>

    <h2>Detail Penjualan</h2>
    <table>
        <thead>
            <tr>
                <th>Nama Produk</th>
                <th>Kategori</th>
                <th>Jumlah</th>
                <th>Harga Satuan</th>
                <th>Total</th>
            </tr>
        </thead>
        <tbody>
''';

    for (var item in penjualanData) {
      html += '''
            <tr>
                <td>${item['nama']}</td>
                <td>${item['kategori']}</td>
                <td>${item['jumlah']}</td>
                <td>${currencyFormat.format(item['harga'])}</td>
                <td>${currencyFormat.format(item['total'])}</td>
            </tr>
''';
    }

    html += '''
        </tbody>
    </table>

    <div class="category-section">
        <h3>Ringkasan per Kategori</h3>
''';

    final kategoriSummary = summary['kategoriSummary'] as Map<String, dynamic>;
    for (var entry in kategoriSummary.entries) {
      final percentage = summary['totalPendapatan'] > 0
          ? (entry.value / summary['totalPendapatan'] * 100).toStringAsFixed(1)
          : '0.0';
      html += '''
        <div style="display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee;">
            <span>${entry.key}</span>
            <span>${currencyFormat.format(entry.value)} (${percentage}%)</span>
        </div>
''';
    }

    html += '''
    </div>
</body>
</html>''';

    return html;
  }

  // Generate weekly report PDF
  Future<String?> generateWeeklyReportPDF(
    List<Map<String, dynamic>> penjualanData,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Calculate summary
      final summary = _calculateSummary(penjualanData);

      // Generate HTML content
      final htmlContent =
          _generateWeeklyReportHTML(penjualanData, startDate, endDate, summary);

      // Convert to PDF using PDFShift API
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'source': htmlContent,
          'format': 'A4',
          'margin': '1cm',
          'filename':
              'laporan_penjualan_mingguan_${DateFormat('yyyy-MM-dd').format(startDate)}_to_${DateFormat('yyyy-MM-dd').format(endDate)}.pdf',
        }),
      );

      if (response.statusCode == 200) {
        // Save PDF to device
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'laporan_penjualan_mingguan_${DateFormat('yyyy-MM-dd').format(startDate)}_to_${DateFormat('yyyy-MM-dd').format(endDate)}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      } else {
        throw Exception(
            'Failed to generate PDF: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating weekly report PDF: $e');
    }
  }

  // Generate monthly report PDF
  Future<String?> generateMonthlyReportPDF(
    List<Map<String, dynamic>> penjualanData,
    int year,
    int month,
  ) async {
    try {
      // Calculate summary with weekly breakdown
      final summary = _calculateMonthlySummary(penjualanData, year, month);

      // Generate HTML content
      final htmlContent =
          _generateMonthlyReportHTML(penjualanData, year, month, summary);

      // Convert to PDF using PDFShift API
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'source': htmlContent,
          'format': 'A4',
          'margin': '1cm',
          'filename':
              'laporan_penjualan_bulanan_${year}_${month.toString().padLeft(2, '0')}.pdf',
        }),
      );

      if (response.statusCode == 200) {
        // Save PDF to device
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'laporan_penjualan_bulanan_${year}_${month.toString().padLeft(2, '0')}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      } else {
        throw Exception(
            'Failed to generate PDF: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating monthly report PDF: $e');
    }
  }

  // Generate daily report PDF
  Future<String?> generateDailyReportPDF(
    List<Map<String, dynamic>> penjualanData,
    DateTime date,
  ) async {
    try {
      // Calculate summary
      final summary = _calculateSummary(penjualanData);

      // Generate HTML content
      final htmlContent =
          _generateDailyReportHTML(penjualanData, date, summary);

      // Convert to PDF using PDFShift API
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'source': htmlContent,
          'format': 'A4',
          'margin': '1cm',
          'filename':
              'laporan_penjualan_harian_${DateFormat('yyyy-MM-dd').format(date)}.pdf',
        }),
      );

      if (response.statusCode == 200) {
        // Save PDF to device
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'laporan_penjualan_harian_${DateFormat('yyyy-MM-dd').format(date)}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
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
