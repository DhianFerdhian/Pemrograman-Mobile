import 'package:flutter/material.dart';
import 'feedback_form_page.dart';
import 'feedback_list_page.dart';
import 'about_page.dart';
import 'model/feedback_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FeedbackItem> feedbackList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Campus Feedback'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Kampus - DITAMBAHKAN DI SINI
            Center(
              child: Image.asset(
                'assets/gambar/logo.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback jika logo tidak ditemukan
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(color: const Color.fromARGB(255, 2, 137, 247), width: 2),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 60,
                      color: Colors.blue,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Nama Aplikasi
            const Center(
              child: Text(
                "UIN Sulthan Thaha Saifuddin Jambi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Platform Kuesioner Kepuasan Mahasiswa',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),

            // Tombol Navigasi
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedbackFormPage(
                            onFeedbackSubmitted: (FeedbackItem feedback) {
                              setState(() {
                                feedbackList.add(feedback);
                              });
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.feedback),
                    label: const Text('Formulir Feedback Mahasiswa'),
                  ),
                ),
                const SizedBox(height: 10),
                if (feedbackList.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackListPage(
                              feedbackList: feedbackList,
                              onFeedbackDeleted: (String id) {
                                setState(() {
                                  feedbackList.removeWhere(
                                    (item) => item.id == id,
                                  );
                                });
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Daftar Feedback'),
                    ),
                  ),
                if (feedbackList.isNotEmpty) const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Profil Aplikasi / Tentang Kami'),
                  ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
