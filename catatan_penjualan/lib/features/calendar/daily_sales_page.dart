import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/penjualan_model.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/theme_provider.dart';

class DailySalesPage extends ConsumerWidget {
  final DateTime selectedDate;

  const DailySalesPage({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final penjualanList = ref.watch(penjualanProvider);
    final dailyPenjualan = penjualanList.where((p) {
      return p.tanggal.year == selectedDate.year &&
          p.tanggal.month == selectedDate.month &&
          p.tanggal.day == selectedDate.day;
    }).toList();

    dailyPenjualan.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    final dailyTotal = dailyPenjualan.fold<int>(0, (sum, p) => sum + p.total);
    final totalItems = dailyPenjualan.fold<int>(0, (sum, p) => sum + p.jumlah);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: themeState.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Penjualan ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
        ),
        backgroundColor: themeState.navbarColor,
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/calendar'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/penjualan/tambah'),
          ),
        ],
      ),
      body: dailyPenjualan.isEmpty
          ? _buildEmptyState(context, themeState)
          : _buildContent(
              context, dailyPenjualan, dailyTotal, totalItems, themeState),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeState themeState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada penjualan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pada tanggal ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/penjualan/tambah'),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Penjualan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeState.navbarColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Penjualan> penjualanList,
    int dailyTotal,
    int totalItems,
    ThemeState themeState,
  ) {
    final Map<String, int> kategoriMap = {};
    for (var p in penjualanList) {
      kategoriMap[p.kategori] = (kategoriMap[p.kategori] ?? 0) + p.total;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeState.navbarColor.withAlpha(25),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'Total Pendapatan',
                      'Rp ${_formatCurrency(dailyTotal)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Jumlah Transaksi',
                      penjualanList.length.toString(),
                      Icons.receipt,
                      themeState.navbarColor,
                    ),
                    _buildStatItem(
                      'Total Item',
                      totalItems.toString(),
                      Icons.shopping_cart,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (kategoriMap.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan per Kategori:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kategoriMap.entries.map((entry) {
                          final percentage = dailyTotal > 0
                              ? (entry.value / dailyTotal * 100)
                                  .toStringAsFixed(1)
                              : '0.0';
                          return Chip(
                            backgroundColor:
                                _getKategoriColor(entry.key).withAlpha(64),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: _getKategoriColor(entry.key),
                                ),
                                const SizedBox(width: 4),
                                Text('${entry.key}: '),
                                Text(
                                  'Rp ${_formatCurrency(entry.value)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getKategoriColor(entry.key),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($percentage%)',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daftar Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeState.navbarColor,
                      ),
                    ),
                    Text(
                      '${penjualanList.length} transaksi',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...penjualanList.map((penjualan) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getKategoriColor(penjualan.kategori)
                              .withAlpha(64),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fastfood,
                          color: _getKategoriColor(penjualan.kategori),
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            penjualan.nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    penjualan.kategori,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('HH:mm')
                                        .format(penjualan.tanggal),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    penjualan.isPaid
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 12,
                                    color: penjualan.isPaid
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    penjualan.isPaid
                                        ? 'Dibayar'
                                        : 'Belum Dibayar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: penjualan.isPaid
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: penjualan.paymentMethod == 'Cash'
                                      ? Colors.green[100]
                                      : Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  penjualan.paymentMethod,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: penjualan.paymentMethod == 'Cash'
                                        ? Colors.green[800]
                                        : Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      subtitle: penjualan.keterangan.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                penjualan.keterangan,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rp ${_formatCurrency(penjualan.total)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${penjualan.jumlah} × Rp ${_formatCurrency(penjualan.harga)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        context.go('/penjualan/edit/${penjualan.id}');
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
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
            color: color.withAlpha(64),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
}
