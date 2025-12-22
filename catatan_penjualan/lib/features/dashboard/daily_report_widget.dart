import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/penjualan_provider.dart';

class DailyReportWidget extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const DailyReportWidget({
    super.key,
    required this.selectedDate,
  });

  @override
  ConsumerState<DailyReportWidget> createState() => _DailyReportWidgetState();
}

class _DailyReportWidgetState extends ConsumerState<DailyReportWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final penjualanList = ref.watch(penjualanProvider);
    final dailyPenjualan = penjualanList.where((p) {
      return p.tanggal.year == widget.selectedDate.year &&
          p.tanggal.month == widget.selectedDate.month &&
          p.tanggal.day == widget.selectedDate.day;
    }).toList();

    final dailyTotal = dailyPenjualan.fold<int>(0, (sum, p) => sum + p.total);
    final totalItems = dailyPenjualan.fold<int>(0, (sum, p) => sum + p.jumlah);

    // Group by kategori
    final Map<String, int> kategoriMap = {};
    for (var p in dailyPenjualan) {
      kategoriMap[p.kategori] = (kategoriMap[p.kategori] ?? 0) + p.total;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Laporan Harian',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Chip(
                  label: Text(
                    DateFormat('dd/MM/yyyy').format(widget.selectedDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statistik
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Pendapatan',
                    'Rp ${_formatCurrency(dailyTotal)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Jumlah Transaksi',
                    dailyPenjualan.length.toString(),
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Item Terjual',
                    totalItems.toString(),
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            // Lihat Detail Button
            if (dailyPenjualan.isNotEmpty || kategoriMap.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  label:
                      Text(_isExpanded ? 'Sembunyikan Detail' : 'Lihat Detail'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],

            // Expanded Details
            if (_isExpanded) ...[
              const SizedBox(height: 16),

              // Kategori Breakdown
              if (kategoriMap.isNotEmpty) ...[
                Text(
                  'Pendapatan per Kategori:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...kategoriMap.entries.map((entry) {
                  final percentage = dailyTotal > 0
                      ? (entry.value / dailyTotal * 100).toStringAsFixed(1)
                      : '0.0';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(entry.key),
                        ),
                        Text(
                          'Rp ${_formatCurrency(entry.value)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($percentage%)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // List Penjualan
              if (dailyPenjualan.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Detail Penjualan:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...dailyPenjualan.map((p) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          _getKategoriColor(p.kategori).withAlpha(25),
                      child: Icon(
                        Icons.fastfood,
                        color: _getKategoriColor(p.kategori),
                        size: 20,
                      ),
                    ),
                    title: Text(p.nama),
                    subtitle:
                        Text('${p.jumlah} × Rp ${_formatCurrency(p.harga)}'),
                    trailing: Text(
                      'Rp ${_formatCurrency(p.total)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                }),
              ],

              // Download Buttons
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Download Laporan:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadReport('pdf'),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadReport('excel'),
                      icon: const Icon(Icons.table_chart, size: 18),
                      label: const Text('Download Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (dailyPenjualan.isEmpty) ...[
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tidak ada penjualan hari ini',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Color _getKategoriColor(String kategori) {
    final colors = {
      'Makanan': Colors.green,
      'Minuman': Colors.blue,
      'Camilan': Colors.orange,
      'Kue': Colors.purple,
      'Makanan Ringan': Colors.red,
      'Lainnya': Colors.grey,
    };
    return colors[kategori] ?? Colors.grey;
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Future<void> _downloadReport(String format) async {
    final penjualanList = ref.read(penjualanProvider);
    final dailyPenjualan = penjualanList.where((p) {
      return p.tanggal.year == widget.selectedDate.year &&
          p.tanggal.month == widget.selectedDate.month &&
          p.tanggal.day == widget.selectedDate.day;
    }).toList();

    if (dailyPenjualan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data penjualan untuk didownload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final pdfShiftService = ref.read(pdfShiftServiceProvider);
      String? filePath;

      if (format == 'pdf') {
        // Convert Penjualan objects to Map format for PDFShift
        final penjualanData = dailyPenjualan
            .map((p) => {
                  'tanggal': p.tanggal.toIso8601String(),
                  'nama': p.nama,
                  'kategori': p.kategori,
                  'jumlah': p.jumlah,
                  'harga': p.harga,
                  'total': p.total,
                })
            .toList();

        filePath = await pdfShiftService.generateDailyReportPDF(
            penjualanData, widget.selectedDate);
      } else {
        // Convert Penjualan objects to Map format for Excel
        final penjualanData = dailyPenjualan
            .map((p) => {
                  'tanggal': p.tanggal.toIso8601String(),
                  'nama': p.nama,
                  'kategori': p.kategori,
                  'jumlah': p.jumlah,
                  'harga': p.harga,
                  'total': p.total,
                })
            .toList();

        filePath = await pdfShiftService.generateReportExcel(
          penjualanData,
          'harian',
          widget.selectedDate,
          null,
        );
      }

      if (filePath != null) {
        await pdfShiftService.openFile(filePath);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan berhasil diunduh dan dibuka'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunduh laporan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
