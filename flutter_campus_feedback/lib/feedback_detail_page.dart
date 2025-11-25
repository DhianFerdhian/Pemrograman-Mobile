import 'package:flutter/material.dart';
import 'model/feedback_item.dart';

class FeedbackDetailPage extends StatelessWidget {
  final FeedbackItem feedback;
  final VoidCallback onDelete;

  const FeedbackDetailPage({
    super.key,
    required this.feedback,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Feedback'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailItem('Nama Mahasiswa', feedback.name),
            _buildDetailItem('NIM', feedback.nim),
            _buildDetailItem('Fakultas', feedback.faculty),
            const SizedBox(height: 16),
            const Text(
              'Fasilitas yang Dinilai:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ...feedback.facilities.map(
              (facility) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• $facility'),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem('Nilai Kepuasan',
                '${feedback.satisfaction.toStringAsFixed(1)}/5.0'),
            _buildDetailItem('Jenis Feedback', feedback.feedbackType),
            if (feedback.additionalMessage != null) ...[
              const SizedBox(height: 16),
              _buildDetailItem('Pesan Tambahan', feedback.additionalMessage!),
            ],
            const SizedBox(height: 16),
            _buildDetailItem('Status Persetujuan',
                feedback.agreedToTerms ? 'Disetujui' : 'Tidak Disetujui'),
            _buildDetailItem('Tanggal Submit',
                '${feedback.createdAt.day}/${feedback.createdAt.month}/${feedback.createdAt.year}'),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Kembali'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _showDeleteConfirmation(context);
                },
                child: const Text('Hapus'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content:
              const Text('Apakah Anda yakin ingin menghapus feedback ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback berhasil dihapus')),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
