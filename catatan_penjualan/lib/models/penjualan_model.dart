import 'package:cloud_firestore/cloud_firestore.dart';

class Penjualan {
  final String id;
  final String nama;
  final int harga;
  final int jumlah;
  final String keterangan;
  final DateTime tanggal;
  final String kategori;
  final bool isPaid;
  final String alamat;
  final String paymentMethod;
  final String customerName;
  final String customerPhone;
  final String? userId;

  Penjualan({
    required this.id,
    required this.nama,
    required this.harga,
    this.jumlah = 1,
    this.keterangan = '',
    required this.tanggal,
    this.kategori = 'Makanan',
    this.isPaid = false,
    this.alamat = '',
    this.paymentMethod = 'Cash',
    this.customerName = '',
    this.customerPhone = '',
    this.userId,
  });

  int get total => harga * jumlah;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'tanggal': Timestamp.fromDate(tanggal),
      'kategori': kategori,
      'isPaid': isPaid,
      'alamat': alamat,
      'paymentMethod': paymentMethod,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'total': total,
      'userId': userId,
      'createdAt': Timestamp.now(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'tanggal': tanggal.toIso8601String(),
      'kategori': kategori,
      'isPaid': isPaid,
      'alamat': alamat,
      'paymentMethod': paymentMethod,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'userId': userId,
    };
  }

  factory Penjualan.fromFirestore(Map<String, dynamic> map, String documentId) {
    return Penjualan(
      id: documentId,
      nama: map['nama'] as String,
      harga: (map['harga'] as num).toInt(),
      jumlah: (map['jumlah'] as num?)?.toInt() ?? 1,
      keterangan: (map['keterangan'] as String?) ?? '',
      tanggal: (map['tanggal'] as Timestamp).toDate(),
      kategori: (map['kategori'] as String?) ?? 'Makanan',
      isPaid: (map['isPaid'] as bool?) ?? false,
      alamat: (map['alamat'] as String?) ?? '',
      paymentMethod: (map['paymentMethod'] as String?) ?? 'Cash',
      customerName: (map['customerName'] as String?) ?? '',
      customerPhone: (map['customerPhone'] as String?) ?? '',
      userId: map['userId'] as String?,
    );
  }

  factory Penjualan.fromMap(Map<String, dynamic> map) {
    return Penjualan(
      id: map['id'] as String,
      nama: map['nama'] as String,
      harga: map['harga'] as int,
      jumlah: (map['jumlah'] as int?) ?? 1,
      keterangan: (map['keterangan'] as String?) ?? '',
      tanggal: DateTime.parse(map['tanggal'] as String),
      kategori: (map['kategori'] as String?) ?? 'Makanan',
      isPaid: (map['isPaid'] as bool?) ?? false,
      alamat: (map['alamat'] as String?) ?? '',
      paymentMethod: (map['paymentMethod'] as String?) ?? 'Cash',
      customerName: (map['customerName'] as String?) ?? '',
      customerPhone: (map['customerPhone'] as String?) ?? '',
      userId: map['userId'] as String?,
    );
  }

  Penjualan copyWith({
    String? id,
    String? nama,
    int? harga,
    int? jumlah,
    String? keterangan,
    DateTime? tanggal,
    String? kategori,
    bool? isPaid,
    String? alamat,
    String? paymentMethod,
    String? customerName,
    String? customerPhone,
    String? userId,
  }) {
    return Penjualan(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      jumlah: jumlah ?? this.jumlah,
      keterangan: keterangan ?? this.keterangan,
      tanggal: tanggal ?? this.tanggal,
      kategori: kategori ?? this.kategori,
      isPaid: isPaid ?? this.isPaid,
      alamat: alamat ?? this.alamat,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      userId: userId ?? this.userId,
    );
  }
}
