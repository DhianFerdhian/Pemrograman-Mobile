import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/theme_provider.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTime? _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedYear;
  int? _selectedMonth;
  String _reportType = 'daily'; // 'daily', 'weekly', 'monthly'
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectMonthYear(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime(_selectedYear ?? now.year, _selectedMonth ?? now.month),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Bulan dan Tahun',
      fieldHintText: 'MM/YYYY',
    );

    if (picked != null) {
      setState(() {
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
      });
    }
  }

  Future<void> _downloadReport(String format) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final pdfShiftService = ref.read(pdfShiftServiceProvider);
      final penjualanNotifier = ref.read(penjualanProvider.notifier);
      String? filePath;

      switch (_reportType) {
        case 'daily':
          if (_selectedDate == null) {
            _showError('Pilih tanggal terlebih dahulu');
            return;
          }
          final dailyData =
              penjualanNotifier.getPenjualanByDate(_selectedDate!);
          if (dailyData.isEmpty) {
            _showError('Tidak ada data penjualan untuk tanggal tersebut');
            return;
          }

          if (format == 'pdf') {
            // Convert Penjualan objects to Map format for PDFShift
            final penjualanData = dailyData
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
                penjualanData, _selectedDate!);
          } else {
            // Convert Penjualan objects to Map format for Excel
            final penjualanData = dailyData
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
              _selectedDate!,
              null,
            );
          }
          break;

        case 'weekly':
          if (_startDate == null || _endDate == null) {
            _showError('Pilih rentang tanggal terlebih dahulu');
            return;
          }
          final weeklyData =
              penjualanNotifier.getPenjualanByDateRange(_startDate!, _endDate!);
          if (weeklyData.isEmpty) {
            _showError(
                'Tidak ada data penjualan untuk rentang tanggal tersebut');
            return;
          }

          if (format == 'pdf') {
            // Convert Penjualan objects to Map format for PDFShift
            final penjualanData = weeklyData
                .map((p) => {
                      'tanggal': p.tanggal.toIso8601String(),
                      'nama': p.nama,
                      'kategori': p.kategori,
                      'jumlah': p.jumlah,
                      'harga': p.harga,
                      'total': p.total,
                    })
                .toList();
            filePath = await pdfShiftService.generateWeeklyReportPDF(
                penjualanData, _startDate!, _endDate!);
          } else {
            // Convert Penjualan objects to Map format for Excel
            final penjualanData = weeklyData
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
              'mingguan',
              _startDate!,
              _endDate,
            );
          }
          break;

        case 'monthly':
          if (_selectedYear == null || _selectedMonth == null) {
            _showError('Pilih bulan dan tahun terlebih dahulu');
            return;
          }
          final monthlyData = penjualanNotifier
              .getAll()
              .where((p) =>
                  p.tanggal.year == _selectedYear &&
                  p.tanggal.month == _selectedMonth)
              .toList();
          if (monthlyData.isEmpty) {
            _showError('Tidak ada data penjualan untuk bulan tersebut');
            return;
          }

          if (format == 'pdf') {
            // Convert Penjualan objects to Map format for PDFShift
            final penjualanData = monthlyData
                .map((p) => {
                      'tanggal': p.tanggal.toIso8601String(),
                      'nama': p.nama,
                      'kategori': p.kategori,
                      'jumlah': p.jumlah,
                      'harga': p.harga,
                      'total': p.total,
                    })
                .toList();
            filePath = await pdfShiftService.generateMonthlyReportPDF(
                penjualanData, _selectedYear!, _selectedMonth!);
          } else {
            final startDate = DateTime(_selectedYear!, _selectedMonth!);
            final endDate = DateTime(_selectedYear!, _selectedMonth! + 1, 0);
            // Convert Penjualan objects to Map format for Excel
            final penjualanData = monthlyData
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
              'bulanan',
              startDate,
              endDate,
            );
          }
          break;
      }

      if (filePath != null) {
        await pdfShiftService.openFile(filePath);
        _showSuccess('Laporan berhasil diunduh dan dibuka');
      } else {
        _showError('Gagal mengunduh laporan');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Download Laporan'),
        backgroundColor: themeState.navbarColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selection
            Text(
              'Jenis Laporan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Harian')),
                ButtonSegment(value: 'weekly', label: Text('Mingguan')),
                ButtonSegment(value: 'monthly', label: Text('Bulanan')),
              ],
              selected: {_reportType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _reportType = newSelection.first;
                });
              },
            ),

            const SizedBox(height: 24),

            // Date Selection based on report type
            Text(
              'Pilih Periode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            if (_reportType == 'daily') ...[
              _buildDateSelector(
                label: 'Tanggal',
                value: _selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                    : 'Pilih tanggal',
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ] else if (_reportType == 'weekly') ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Dari Tanggal',
                      value: _startDate != null
                          ? DateFormat('dd/MM/yyyy').format(_startDate!)
                          : 'Pilih tanggal',
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateSelector(
                      label: 'Sampai Tanggal',
                      value: _endDate != null
                          ? DateFormat('dd/MM/yyyy').format(_endDate!)
                          : 'Pilih tanggal',
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
            ] else if (_reportType == 'monthly') ...[
              _buildDateSelector(
                label: 'Bulan dan Tahun',
                value: _selectedYear != null && _selectedMonth != null
                    ? DateFormat('MMMM yyyy', 'id_ID')
                        .format(DateTime(_selectedYear!, _selectedMonth!))
                    : 'Pilih bulan dan tahun',
                onTap: () => _selectMonthYear(context),
              ),
            ],

            const SizedBox(height: 32),

            // Download Buttons
            Text(
              'Format Download',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isDownloading ? null : () => _downloadReport('pdf'),
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isDownloading ? null : () => _downloadReport('excel'),
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.table_chart, size: 18),
                    label: const Text('Download Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Informasi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• PDF: Laporan profesional dengan format yang rapi\n'
                      '• Excel: Data dalam format CSV yang dapat dibuka dengan Excel\n'
                      '• File akan otomatis disimpan dan dibuka setelah download',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color:
                          value.contains('Pilih') ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
