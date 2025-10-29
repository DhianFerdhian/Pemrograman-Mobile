import 'package:flutter/material.dart';

class FeedbackResultPage extends StatelessWidget {
  final String name;
  final String comment;
  final int rating;

  const FeedbackResultPage({
    super.key,
    required this.name,
    required this.comment,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Terima Kasih atas Feedback!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Nama: $name'),
                    const SizedBox(height: 10),
                    Text('Rating: $rating/5'),
                    const SizedBox(height: 10),
                    Text('Komentar: $comment'),
                  ],
                ),
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Kembali ke Form'),
            ),
          ],
        ),
      ),
    );
  }
}
