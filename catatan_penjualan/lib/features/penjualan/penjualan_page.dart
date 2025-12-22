import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/penjualan_model.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/theme_provider.dart';

class PenjualanPage extends ConsumerStatefulWidget {
  const PenjualanPage({super.key});

  @override
  ConsumerState<PenjualanPage> createState() => _PenjualanPageState();
}

class _PenjualanPageState extends ConsumerState<PenjualanPage> {
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  String _periodFilter = 'daily'; // 'daily', 'weekly', 'monthly'

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  List<Penjualan> _filterPenjualan(List<Penjualan> allPenjualan) {
    var filtered = allPenjualan;

    // Apply period filter first
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_periodFilter) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        // Start of week (Monday)
        final monday = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(monday.year, monday.month, monday.day);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
    }

    filtered = filtered
        .where((p) =>
            p.tanggal.isAtSameMomentAs(startDate) ||
            p.tanggal.isAfter(startDate) && p.tanggal.isBefore(endDate))
        .toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.keterangan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.kategori.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.customerName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              p.customerPhone
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_dateRange != null) {
      filtered = filtered
          .where((p) =>
              p.tanggal.isAfter(
                  _dateRange!.start.subtract(const Duration(days: 1))) &&
              p.tanggal.isBefore(_dateRange!.end.add(const Duration(days: 1))))
          .toList();
    }

    filtered.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final allPenjualan = ref.watch(penjualanProvider);
    final filteredPenjualan = _filterPenjualan(allPenjualan);
    final total = filteredPenjualan.fold<int>(0, (sum, e) => sum + e.total);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: themeState.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Daftar Penjualan'),
        backgroundColor: themeState.navbarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: () => context.go('/reports'),
            tooltip: 'Laporan',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filter Tanggal',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/penjualan/tambah');
        },
        backgroundColor: themeState.navbarColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: themeState.navbarColor.withAlpha(25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Penjualan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(178),
                      ),
                    ),
                    Text(
                      'Rp ${_formatCurrency(total)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: themeState.navbarColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Jumlah Transaksi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${filteredPenjualan.length} item',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeState.navbarColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari penjualan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'daily',
                  label: Text('Harian'),
                  icon: Icon(Icons.today),
                ),
                ButtonSegment<String>(
                  value: 'weekly',
                  label: Text('Mingguan'),
                  icon: Icon(Icons.calendar_view_week),
                ),
                ButtonSegment<String>(
                  value: 'monthly',
                  label: Text('Bulanan'),
                  icon: Icon(Icons.calendar_month),
                ),
              ],
              selected: {_periodFilter},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _periodFilter = newSelection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return themeState.navbarColor;
                    }
                    return Colors.white;
                  },
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white;
                    }
                    return themeState.navbarColor;
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      '${_formatDate(_dateRange!.start, 'dd/MM')} - ${_formatDate(_dateRange!.end, 'dd/MM/yyyy')}',
                    ),
                    backgroundColor: themeState.navbarColor.withAlpha(25),
                    onDeleted: () {
                      setState(() {
                        _dateRange = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${filteredPenjualan.length} transaksi)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredPenjualan.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _dateRange != null
                              ? 'Tidak ada penjualan yang sesuai'
                              : 'Belum ada penjualan',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _dateRange != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _dateRange = null;
                              });
                            },
                            child: const Text('Reset Filter'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredPenjualan.length,
                    itemBuilder: (context, index) {
                      final p = filteredPenjualan[index];
                      final dateFormatted =
                          _formatDate(p.tanggal, 'dd/MM/yyyy HH:mm');

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        color: Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor:
                                _getKategoriColor(p.kategori).withAlpha(50),
                            child: Icon(
                              _getKategoriIcon(p.kategori),
                              color: _getKategoriColor(p.kategori),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            p.nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${p.jumlah} × Rp ${_formatCurrency(p.harga)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (p.keterangan.isNotEmpty)
                                Text(
                                  p.keterangan,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                '$dateFormatted • ${p.kategori}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rp ${_formatCurrency(p.total)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: themeState.navbarColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () {
                                      context.push('/penjualan/edit/${p.id}');
                                    },
                                    padding: EdgeInsets.zero,
                                    color: Colors.blue,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () {
                                      _showDeleteDialog(context, p);
                                    },
                                    padding: EdgeInsets.zero,
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            context.push('/penjualan/edit/${p.id}');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getKategoriIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'makanan':
        return Icons.restaurant;
      case 'minuman':
        return Icons.local_drink;
      case 'camilan':
        return Icons.cookie;
      case 'kue':
        return Icons.cake;
      default:
        return Icons.fastfood;
    }
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

  void _showDeleteDialog(BuildContext context, Penjualan penjualan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Penjualan'),
        content: Text('Yakin ingin menghapus penjualan "${penjualan.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(penjualanProvider.notifier).delete(penjualan.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Penjualan berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Hapus',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDate(DateTime date, String format) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (format == 'dd/MM') {
      return '$day/$month';
    } else if (format == 'dd/MM/yyyy') {
      return '$day/$month/$year';
    } else if (format == 'dd/MM/yyyy HH:mm') {
      return '$day/$month/$year $hour:$minute';
    }

    return '$day/$month/$year';
  }
}
