import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/penjualan_model.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/theme_provider.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<Penjualan>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  void _loadEvents() {
    final penjualanList = ref.read(penjualanProvider);
    final events = <DateTime, List<Penjualan>>{};

    for (var penjualan in penjualanList) {
      final date = DateTime(
        penjualan.tanggal.year,
        penjualan.tanggal.month,
        penjualan.tanggal.day,
      );

      if (events.containsKey(date)) {
        events[date]!.add(penjualan);
      } else {
        events[date] = [penjualan];
      }
    }

    setState(() {
      _events = events;
    });
  }

  List<Penjualan> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  int _getTotalForDay(DateTime day) {
    final events = _getEventsForDay(day);
    return events.fold<int>(0, (sum, p) => sum + p.total);
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: themeState.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Kalender Penjualan'),
        backgroundColor: themeState.navbarColor,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDay = DateTime.now();
                _focusedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TableCalendar<Penjualan>(
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'id_ID',
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: themeState.navbarColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.white),
                  titleTextStyle: TextStyle(
                    color: themeState.navbarColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: themeState.navbarColor.withAlpha(64),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: themeState.navbarColor,
                    shape: BoxShape.circle,
                  ),
                  markersAlignment: Alignment.bottomCenter,
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: themeState.navbarColor,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: const TextStyle(color: Colors.red),
                  defaultTextStyle: const TextStyle(color: Colors.black),
                  outsideTextStyle: TextStyle(color: Colors.grey[600]),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final total = _getTotalForDay(day);
                    if (total > 0) {
                      return Stack(
                        children: [
                          Center(
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: isSameDay(day, DateTime.now())
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(100),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatCurrencyShort(total),
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return null;
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final total = _getTotalForDay(day);
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: themeState.navbarColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day.day.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (total > 0)
                              Text(
                                _formatCurrencyShort(total),
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final total = _getTotalForDay(day);
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: themeState.navbarColor.withAlpha(64),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day.day.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (total > 0)
                              Text(
                                _formatCurrencyShort(total),
                                style: TextStyle(
                                  fontSize: 8,
                                  color: themeState.navbarColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (_selectedDay != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: themeState.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM y', 'id_ID')
                                .format(_selectedDay!),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeState.navbarColor,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.go(
                                  '/daily-sales/${_selectedDay!.toIso8601String()}');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeState.navbarColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Lihat Detail'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDaySummary(_selectedDay!),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDaySummary(DateTime day) {
    final events = _getEventsForDay(day);
    final total = _getTotalForDay(day);
    final themeState = ref.read(themeProvider);

    if (events.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tidak ada penjualan hari ini',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Pendapatan',
                'Rp ${_formatCurrency(total)}',
                Icons.attach_money,
                Colors.green,
                themeState,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Jumlah Transaksi',
                events.length.toString(),
                Icons.receipt,
                themeState.navbarColor,
                themeState,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaksi Terbaru:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...events.take(3).map((penjualan) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.grey[50],
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor:
                        _getKategoriColor(penjualan.kategori).withAlpha(64),
                    child: Icon(
                      Icons.fastfood,
                      color: _getKategoriColor(penjualan.kategori),
                      size: 20,
                    ),
                  ),
                  title: Text(penjualan.nama),
                  subtitle: Text(
                      '${penjualan.jumlah} × Rp ${_formatCurrency(penjualan.harga)}'),
                  trailing: Text(
                    'Rp ${_formatCurrency(penjualan.total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            }),
            if (events.length > 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.go('/daily-sales/${day.toIso8601String()}');
                  },
                  child: Text(
                    'Lihat semua transaksi →',
                    style: TextStyle(color: themeState.navbarColor),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      ThemeState themeState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(64),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
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

  String _formatCurrencyShort(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toString();
  }
}
