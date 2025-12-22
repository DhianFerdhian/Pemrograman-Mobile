import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/penjualan_model.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/theme_provider.dart';

class PendapatanPage extends ConsumerStatefulWidget {
  const PendapatanPage({super.key});

  @override
  ConsumerState<PendapatanPage> createState() => _PendapatanPageState();
}

class _PendapatanPageState extends ConsumerState<PendapatanPage> {
  String _filterType = 'hari'; // 'hari', 'minggu', 'bulan'
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  void _loadChartData() {
    final penjualanList = ref.read(penjualanProvider);
    final data = <Map<String, dynamic>>[];

    if (_filterType == 'hari') {
      // Data per jam
      for (int i = 0; i < 24; i++) {
        final hourStart = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          i,
        );
        final hourEnd = hourStart.add(const Duration(hours: 1));

        final hourPenjualan = penjualanList.where((p) {
          return p.tanggal.isAfter(hourStart) && p.tanggal.isBefore(hourEnd);
        }).toList();

        final total = hourPenjualan.fold<int>(0, (sum, p) => sum + p.total);

        data.add({
          'label': '$i:00',
          'value': total,
          'jumlah': hourPenjualan.length,
        });
      }
    } else if (_filterType == 'minggu') {
      // Data per hari dalam seminggu
      final startOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );

      for (int i = 0; i < 7; i++) {
        final day = startOfWeek.add(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final dayPenjualan = penjualanList.where((p) {
          return p.tanggal.isAfter(dayStart) && p.tanggal.isBefore(dayEnd);
        }).toList();

        final total = dayPenjualan.fold<int>(0, (sum, p) => sum + p.total);

        data.add({
          'label': _formatDateShort(day),
          'value': total,
          'jumlah': dayPenjualan.length,
        });
      }
    } else {
      // Data per bulan
      final year = _selectedDate.year;
      for (int i = 1; i <= 12; i++) {
        final monthStart = DateTime(year, i, 1);
        final monthEnd = DateTime(year, i + 1, 1);

        final monthPenjualan = penjualanList.where((p) {
          return p.tanggal.isAfter(monthStart) && p.tanggal.isBefore(monthEnd);
        }).toList();

        final total = monthPenjualan.fold<int>(0, (sum, p) => sum + p.total);

        data.add({
          'label': _getMonthName(i),
          'value': total,
          'jumlah': monthPenjualan.length,
        });
      }
    }

    setState(() {
      _chartData = data;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadChartData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final penjualanList = ref.watch(penjualanProvider);
    final themeState = ref.watch(themeProvider);
    final totalPendapatan =
        penjualanList.fold<int>(0, (sum, p) => sum + p.total);
    final totalTransaksi = penjualanList.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Statistik Pendapatan'),
        backgroundColor: themeState.navbarColor,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Pilih Tanggal',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu statistik
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Pendapatan',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_formatCurrency(totalPendapatan)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Transaksi',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalTransaksi transaksi',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Rata-rata/Transaksi',
                          'Rp ${_formatCurrency(totalTransaksi > 0 ? totalPendapatan ~/ totalTransaksi : 0)}',
                          Icons.trending_up,
                          Theme.of(context).colorScheme.primary,
                        ),
                        _buildStatItem(
                          'Hari Ini',
                          'Rp ${_formatCurrency(_getTodayTotal(penjualanList))}',
                          Icons.today,
                          Theme.of(context).colorScheme.tertiary,
                        ),
                        _buildStatItem(
                          'Bulan Ini',
                          'Rp ${_formatCurrency(_getMonthTotal(penjualanList))}',
                          Icons.calendar_month,
                          Theme.of(context).colorScheme.primaryContainer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filter
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFilterButton('Hari', 'hari'),
                    _buildFilterButton('Minggu', 'minggu'),
                    _buildFilterButton('Bulan', 'bulan'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Grafik
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Pendapatan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildChart(),
                    ),
                    const SizedBox(height: 16),
                    _buildChartLegend(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Data detail
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Pendapatan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ..._chartData.map((data) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['label'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${data['jumlah']} transaksi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Rp ${_formatCurrency(data['value'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filterType == value;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _filterType = value;
          _loadChartData();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _buildChart() {
    if (_chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada data',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final maxValue = _chartData.fold<int>(
      0,
      (max, item) => item['value'] > max ? item['value'] : max,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _chartData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final height = maxValue > 0 ? (data['value'] / maxValue * 150) : 0;

        return Expanded(
          child: Column(
            children: [
              Container(
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _getChartColor(index),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: Center(
                  child: Text(
                    data['value'] > 0
                        ? _formatCurrencyShort(data['value'])
                        : '',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['label'],
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _chartData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;

        if (data['value'] == 0) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getChartColor(index),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${data['label']}: Rp ${_formatCurrency(data['value'])}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getChartColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.deepPurple,
    ];
    return colors[index % colors.length];
  }

  int _getTodayTotal(List<Penjualan> penjualanList) {
    final today = DateTime.now();
    return penjualanList
        .where((p) =>
            p.tanggal.year == today.year &&
            p.tanggal.month == today.month &&
            p.tanggal.day == today.day)
        .fold<int>(0, (sum, p) => sum + p.total);
  }

  int _getMonthTotal(List<Penjualan> penjualanList) {
    final now = DateTime.now();
    return penjualanList
        .where(
            (p) => p.tanggal.year == now.year && p.tanggal.month == now.month)
        .fold<int>(0, (sum, p) => sum + p.total);
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatCurrencyShort(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toString();
  }

  String _formatDateShort(DateTime date) {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }

  String _getMonthName(int month) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }
}
