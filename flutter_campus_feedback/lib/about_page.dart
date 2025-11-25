import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo UIN STS Jambi (placeholder)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: const Icon(Icons.school, size: 60, color: Colors.blue),
            ),
            const SizedBox(height: 20),

            const Text(
              'UIN STS JAMBI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 30),

            // Informasi Aplikasi
            _buildInfoCard('Informasi Aplikasi', [
              _buildInfoItem('Nama Aplikasi', 'Flutter Campus Feedback'),
              _buildInfoItem('Versi', '1.0.0'),
              _buildInfoItem('Tahun Akademik', '2024/2025'),
            ]),
            const SizedBox(height: 20),

            // Informasi Dosen
            _buildInfoCard('Dosen Pengampu', [
              _buildInfoItem('Mata Kuliah', 'Pemrograman Mobile'),
              _buildInfoItem('Dosen', '[Ferdhian S.Kom., M.Kom]'),
            ]),
            const SizedBox(height: 20),

            // Informasi Pengembang
            _buildInfoCard('Pengembang', [
              _buildInfoItem('Nama', '[Nama Mahasiswa]'),
              _buildInfoItem('NIM', '[NIM Mahasiswa]'),
              _buildInfoItem('Program Studi', 'Teknik Informatika'),
            ]),

            const Spacer(),

            // Tombol Kembali
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Kembali ke Beranda'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
