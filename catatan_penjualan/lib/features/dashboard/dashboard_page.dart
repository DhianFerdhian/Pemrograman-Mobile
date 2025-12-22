import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/profile_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DateTime _selectedDate = DateTime.now();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final themeState = ref.read(themeProvider);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeState.navbarColor,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: themeState.navbarColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final themeState = ref.read(themeProvider);
        return Container(
          decoration: BoxDecoration(
            color: themeState.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Consumer(
                builder: (context, ref, child) {
                  final profileState = ref.watch(profileProvider);
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: themeState.navbarColor,
                      backgroundImage: profileState.profileImageUrl != null
                          ? NetworkImage(profileState.profileImageUrl!)
                          : null,
                      child: profileState.profileImageUrl == null
                          ? Text(
                              _currentUser?.displayName?.isNotEmpty == true
                                  ? _currentUser!.displayName![0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      _currentUser?.displayName ?? 'Pengguna',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_currentUser?.email ?? ''),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profil Saya'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Tema Aplikasi'),
                trailing: Consumer(
                  builder: (context, ref, child) {
                    final themeState = ref.watch(themeProvider);
                    return Switch(
                      value: themeState.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        final notifier = ref.read(themeProvider.notifier);
                        notifier.setTheme(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    );
                  },
                ),
              ),
              ListTile(
                leading: Icon(Icons.logout,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Keluar',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCardMini(
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
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  overflow: TextOverflow.ellipsis,
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
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final penjualanList = ref.watch(penjualanProvider);

    // Pastikan penjualanList tidak null
    final safePenjualanList = penjualanList;

    final total = safePenjualanList.fold<int>(0, (sum, e) => sum + e.total);

    final dailyTotal = safePenjualanList.where((p) {
      final pDate = p.tanggal;
      return pDate.year == _selectedDate.year &&
          pDate.month == _selectedDate.month &&
          pDate.day == _selectedDate.day;
    }).fold<int>(0, (sum, e) => sum + e.total);

    final penjualanHariIni = safePenjualanList.where((p) {
      final pDate = p.tanggal;
      return pDate.year == _selectedDate.year &&
          pDate.month == _selectedDate.month &&
          pDate.day == _selectedDate.day;
    }).toList();

    final totalItems =
        penjualanHariIni.fold<int>(0, (sum, p) => sum + p.jumlah);
    final totalTransaksi = safePenjualanList.length;
    final rataRataTransaksi = totalTransaksi > 0 ? total ~/ totalTransaksi : 0;

    return Scaffold(
      backgroundColor: themeState.backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: themeState.navbarColor,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.go('/pendapatan'),
            tooltip: 'Detail Pendapatan',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => context.go('/calendar'),
            tooltip: 'Kalender',
          ),
          Consumer(
            builder: (context, ref, child) {
              final profileState = ref.watch(profileProvider);
              return IconButton(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  backgroundImage: profileState.profileImageUrl != null
                      ? NetworkImage(profileState.profileImageUrl!)
                      : null,
                  child: profileState.profileImageUrl == null
                      ? Text(
                          _currentUser?.displayName?.isNotEmpty == true
                              ? _currentUser!.displayName![0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeState.navbarColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                onPressed: () => _showUserMenu(context),
                tooltip: 'Menu Pengguna',
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeState.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final profileState = ref.watch(profileProvider);
                            return CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  themeState.navbarColor.withAlpha(25),
                              backgroundImage: profileState.profileImageUrl !=
                                      null
                                  ? NetworkImage(profileState.profileImageUrl!)
                                  : null,
                              child: profileState.profileImageUrl == null
                                  ? Icon(
                                      Icons.restaurant_menu,
                                      size: 32,
                                      color: themeState.navbarColor,
                                    )
                                  : null,
                            );
                          },
                        ).animate().fadeIn(duration: 600.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            duration: 500.ms,
                            curve: Curves.elasticOut),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms, duration: 500.ms)
                                  .slideY(
                                      begin: 0.2,
                                      end: 0.0,
                                      duration: 400.ms,
                                      curve: Curves.easeOut),
                              const SizedBox(height: 4),
                              Text(
                                _currentUser?.displayName ?? 'Pengguna',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                                  .animate()
                                  .fadeIn(delay: 300.ms, duration: 500.ms)
                                  .slideY(
                                      begin: 0.3,
                                      end: 0.0,
                                      duration: 400.ms,
                                      curve: Curves.easeOut),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, d MMMM y', 'id_ID')
                                    .format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 400.ms, duration: 500.ms)
                                  .slideY(
                                      begin: 0.2,
                                      end: 0.0,
                                      duration: 400.ms,
                                      curve: Curves.easeOut),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 700.ms).slideY(
                  begin: 0.1,
                  end: 0.0,
                  duration: 600.ms,
                  curve: Curves.easeOut),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeState.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeState.navbarColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.calendar_today,
                          color: themeState.navbarColor),
                    ),
                    title: const Text('Laporan Tanggal'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(
                                const Duration(days: 1),
                              );
                            });
                          },
                        ),
                        TextButton(
                          onPressed: () => _selectDate(context),
                          child: const Text('Pilih'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(
                                const Duration(days: 1),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeState.cardColor,
                    borderRadius: BorderRadius.circular(16),
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
                              'Penjualan Hari Ini',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Chip(
                              label: Text('${penjualanHariIni.length} item'),
                              backgroundColor:
                                  themeState.navbarColor.withAlpha(25),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCardMini(
                                'Total Pendapatan',
                                'Rp ${_formatCurrency(dailyTotal)}',
                                Icons.attach_money,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCardMini(
                                'Jumlah Transaksi',
                                penjualanHariIni.length.toString(),
                                Icons.receipt,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCardMini(
                                'Total Item',
                                totalItems.toString(),
                                Icons.shopping_cart,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (penjualanHariIni.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum ada penjualan hari ini',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('dd MMMM y', 'id_ID')
                                      .format(_selectedDate),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...penjualanHariIni.take(3).map((penjualan) {
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getKategoriColor(penjualan.kategori)
                                      .withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.fastfood,
                                  color: _getKategoriColor(penjualan.kategori),
                                  size: 20,
                                ),
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    penjualan.nama,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (penjualan.customerName.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.person,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            penjualan.customerName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${penjualan.jumlah} × Rp ${_formatCurrency(penjualan.harga)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (penjualan.customerPhone.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.phone,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          penjualan.customerPhone,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (penjualan.alamat.isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            penjualan.alamat,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rp ${_formatCurrency(penjualan.total)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: themeState.navbarColor,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('HH:mm')
                                        .format(penjualan.tanggal),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    penjualan.paymentMethod,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: penjualan.paymentMethod == 'Cash'
                                          ? Colors.green
                                          : Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                context.go('/penjualan/edit/${penjualan.id}');
                              },
                            );
                          }).toList(),
                        if (penjualanHariIni.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.go('/penjualan'),
                                    icon: const Icon(Icons.list_alt),
                                    label: const Text('Lihat Semua'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeState.navbarColor,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        context.go('/penjualan/tambah'),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tambah Baru'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeState.navbarColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    title: 'Total Pendapatan',
                    value: 'Rp ${_formatCurrency(total)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    themeState: themeState,
                  ),
                  _buildStatCard(
                    title: 'Transaksi Hari Ini',
                    value: penjualanHariIni.length.toString(),
                    icon: Icons.receipt_long,
                    color: themeState.navbarColor,
                    themeState: themeState,
                  ),
                  _buildStatCard(
                    title: 'Rata-rata/Transaksi',
                    value: 'Rp ${_formatCurrency(rataRataTransaksi)}',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                    themeState: themeState,
                  ),
                  _buildStatCard(
                    title: 'Pendapatan Hari Ini',
                    value: 'Rp ${_formatCurrency(dailyTotal)}',
                    icon: Icons.today,
                    color: Colors.blue,
                    themeState: themeState,
                  ),
                ].animate(interval: 100.ms).fadeIn(duration: 600.ms).slideY(
                    begin: 0.2,
                    end: 0.0,
                    duration: 500.ms,
                    curve: Curves.easeOut),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/penjualan/tambah'),
        icon: const Icon(Icons.add),
        label: const Text('Penjualan Baru'),
        backgroundColor: themeState.navbarColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeState themeState,
  }) {
    return Card(
      elevation: 2,
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
}
