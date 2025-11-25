import '../models/dosen_model.dart';

class DosenData {
  static List<Dosen> getDosenList() {
    return [
      Dosen(
        id: '1',
        nama: 'Dr. Ahmad Wijaya, S.T., M.T.',
        nip: '1980123423456789',
        email: 'ahmad.wijaya@university.ac.id',
        jabatan: 'Dosen Tetap',
        bidang: 'Teknik Informatika',
        foto: 'assets/dosen1.jpg',
        deskripsi:
            'Dr. Ahmad Wijaya adalah dosen dengan spesialisasi dalam bidang Artificial Intelligence dan Machine Learning. Beliau telah menulis lebih dari 20 paper internasional dan aktif dalam penelitian pengembangan sistem cerdas.',
        mataKuliah: [
          'Kecerdasan Buatan',
          'Machine Learning',
          'Data Mining',
          'Algoritma Pemrograman'
        ],
      ),
      Dosen(
        id: '2',
        nama: 'Prof. Dr. Siti Rahayu, M.Si.',
        nip: '1975123456789012',
        email: 'siti.rahayu@university.ac.id',
        jabatan: 'Guru Besar',
        bidang: 'Sistem Informasi',
        foto: 'assets/dosen2.jpg',
        deskripsi:
            'Prof. Dr. Siti Rahayu adalah guru besar dalam bidang Sistem Informasi dengan pengalaman mengajar lebih dari 25 tahun. Beliau merupakan pakar dalam analisis sistem dan perancangan database.',
        mataKuliah: [
          'Analisis Sistem Informasi',
          'Basis Data',
          'Sistem Enterprise',
          'Manajemen Proyek TI'
        ],
      ),
    ];
  }
}
