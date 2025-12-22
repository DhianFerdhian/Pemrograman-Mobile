import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/penjualan_model.dart';
import '../../providers/penjualan_provider.dart';
import '../../providers/theme_provider.dart';

class PenjualanFormPage extends ConsumerStatefulWidget {
  final String? penjualanId;
  const PenjualanFormPage({super.key, this.penjualanId});

  @override
  ConsumerState<PenjualanFormPage> createState() => _PenjualanFormPageState();
}

class _PenjualanFormPageState extends ConsumerState<PenjualanFormPage> {
  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _jumlahController;
  late TextEditingController _keteranganController;
  late TextEditingController _alamatController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  DateTime? _tanggal;
  String _kategori = 'Makanan';
  bool _isPaid = false;
  String _paymentMethod = 'Cash';
  final _formKey = GlobalKey<FormState>();

  final List<String> _kategoriList = [
    'Makanan',
    'Minuman',
    'Camilan',
    'Kue',
    'Makanan Ringan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadPenjualanData();
    _tanggal = DateTime.now();
  }

  void _loadPenjualanData() {
    if (widget.penjualanId != null) {
      final penjualanList = ref.read(penjualanProvider);
      final penjualan = penjualanList.firstWhere(
        (p) => p.id == widget.penjualanId,
        orElse: () => Penjualan(
          id: widget.penjualanId!,
          nama: '',
          harga: 0,
          jumlah: 1,
          keterangan: '',
          tanggal: DateTime.now(),
          kategori: 'Makanan',
          isPaid: false,
          alamat: '',
          paymentMethod: 'Cash',
          customerName: '',
          customerPhone: '',
        ),
      );

      _namaController = TextEditingController(text: penjualan.nama);
      _hargaController =
          TextEditingController(text: penjualan.harga.toString());
      _jumlahController =
          TextEditingController(text: penjualan.jumlah.toString());
      _keteranganController = TextEditingController(text: penjualan.keterangan);
      _alamatController = TextEditingController(text: penjualan.alamat);
      _customerNameController =
          TextEditingController(text: penjualan.customerName);
      _customerPhoneController =
          TextEditingController(text: penjualan.customerPhone);
      _tanggal = penjualan.tanggal;
      _kategori = penjualan.kategori;
      _isPaid = penjualan.isPaid;
      _paymentMethod = penjualan.paymentMethod;
    } else {
      _namaController = TextEditingController();
      _hargaController = TextEditingController();
      _jumlahController = TextEditingController(text: '1');
      _keteranganController = TextEditingController();
      _alamatController = TextEditingController();
      _customerNameController = TextEditingController();
      _customerPhoneController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _jumlahController.dispose();
    _keteranganController.dispose();
    _alamatController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime.now(),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null && picked != _tanggal) {
      setState(() {
        _tanggal = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final harga = int.tryParse(_hargaController.text) ?? 0;
      final jumlah = int.tryParse(_jumlahController.text) ?? 1;

      if (harga <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harga harus lebih dari 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (jumlah <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah harus lebih dari 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final penjualan = Penjualan(
        id: widget.penjualanId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nama: _namaController.text,
        harga: harga,
        jumlah: jumlah,
        keterangan: _keteranganController.text,
        tanggal: _tanggal ?? DateTime.now(),
        kategori: _kategori,
        isPaid: _isPaid,
        alamat: _alamatController.text,
        paymentMethod: _paymentMethod,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
      );

      try {
        if (widget.penjualanId == null) {
          await ref.read(penjualanProvider.notifier).add(penjualan);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Penjualan berhasil ditambahkan'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          await ref.read(penjualanProvider.notifier).update(penjualan);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Penjualan berhasil diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        if (mounted) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deletePenjualan() {
    if (widget.penjualanId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Penjualan'),
        content: const Text('Apakah Anda yakin ingin menghapus penjualan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(penjualanProvider.notifier).delete(widget.penjualanId!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Penjualan berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
              context.go('/dashboard');
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.penjualanId != null;
    final total = _calculateTotal();
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: themeState.backgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Penjualan' : 'Tambah Penjualan'),
        backgroundColor: themeState.navbarColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deletePenjualan,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Tanggal'),
                  subtitle: Text(
                    _tanggal != null
                        ? '${_tanggal!.day}/${_tanggal!.month}/${_tanggal!.year}'
                        : 'Pilih tanggal',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _selectDate(context),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<String>(
                    value: _kategori,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: InputBorder.none,
                    ),
                    items: _kategoriList
                        .map((kategori) => DropdownMenuItem<String>(
                              value: kategori,
                              child: Text(kategori),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _kategori = value ?? 'Makanan';
                      });
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Makanan/Minuman',
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama produk tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextFormField(
                          controller: _hargaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga Satuan',
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Harga tidak boleh kosong';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Masukkan angka yang valid';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideX(
                        begin: -0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextFormField(
                          controller: _jumlahController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah Terjual',
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Jumlah tidak boleh kosong';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Masukkan angka yang valid';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideX(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pendapatan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Rp ${_formatCurrency(total)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _keteranganController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan (opsional)',
                      border: InputBorder.none,
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _alamatController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Pengiriman/Pengambilan (opsional)',
                      border: InputBorder.none,
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms, duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pelanggan (opsional)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 750.ms, duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextFormField(
                    controller: _customerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP Pelanggan (opsional)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: CheckboxListTile(
                  title: const Text('Sudah Dibayar'),
                  value: _isPaid,
                  onChanged: (value) {
                    setState(() {
                      _isPaid = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.green,
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Metode Pembayaran',
                      border: InputBorder.none,
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'Cash',
                        child: Text('Cash'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Transfer',
                        child: Text('Transfer'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value ?? 'Cash';
                      });
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 850.ms, duration: 500.ms).slideY(
                  begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save),
                  label: Text(
                    isEdit ? 'UPDATE PENJUALAN' : 'SIMPAN PENJUALAN',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeState.navbarColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 500.ms).slideY(
                  begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateTotal() {
    try {
      final harga = int.tryParse(_hargaController.text) ?? 0;
      final jumlah = int.tryParse(_jumlahController.text) ?? 1;
      return harga * jumlah;
    } catch (e) {
      return 0;
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
