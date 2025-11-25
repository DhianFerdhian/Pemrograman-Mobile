import 'package:flutter/material.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  _FeedbackFormPageState createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  // Focus node untuk mengatur fokus keyboard
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _feedbackFocusNode = FocusNode();

  // List untuk menyimpan history feedback
  List<Map<String, String>> feedbackHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Form'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Tombol untuk melihat history
          if (feedbackHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showFeedbackHistory,
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header dengan Logo dan Nama Perusahaan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  margin: const EdgeInsets.only(bottom: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      // Logo Perusahaan
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Nama Perusahaan
                      const Text(
                        'PT. INOVASI TEKNOLOGI INDONESIA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Solusi Teknologi Masa Depan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form Input Nama
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Masukkan nama lengkap Anda',
                  ),
                  textInputAction: TextInputAction.next,
                  onTap: () {
                    _nameFocusNode.requestFocus();
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_emailFocusNode);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan nama Anda';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Form Input Email
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    hintText: 'contoh@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onTap: () {
                    _emailFocusNode.requestFocus();
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_feedbackFocusNode);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan email Anda';
                    }
                    if (!value.contains('@')) {
                      return 'Harap masukkan email yang valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Form Input Feedback
                TextFormField(
                  controller: _feedbackController,
                  focusNode: _feedbackFocusNode,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Feedback',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    hintText: 'Tuliskan feedback Anda di sini...',
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  onTap: () {
                    _feedbackFocusNode.requestFocus();
                  },
                  onFieldSubmitted: (_) {
                    _submitForm();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan feedback Anda';
                    }
                    if (value.length < 10) {
                      return 'Feedback minimal 10 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Tombol Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Kirim Feedback',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                // Tombol Lihat Data yang Sudah Diinput
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _showCurrentInput,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Lihat Data yang Sudah Diinput',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                // Tampilkan data terakhir yang diinput (jika ada)
                if (feedbackHistory.isNotEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Data Feedback Terakhir:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama: ${feedbackHistory.last['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Email: ${feedbackHistory.last['email']}'),
                            const SizedBox(height: 8),
                            Text(
                              'Feedback: ${feedbackHistory.last['feedback']}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Waktu: ${feedbackHistory.last['time']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Sembunyikan keyboard saat submit
      FocusScope.of(context).unfocus();

      // Simpan data ke history
      final newFeedback = {
        'name': _nameController.text,
        'email': _emailController.text,
        'feedback': _feedbackController.text,
        'time': '${DateTime.now().hour}:${DateTime.now().minute}',
      };

      setState(() {
        feedbackHistory.add(newFeedback);
      });

      _showSuccessDialog(newFeedback);
    }
  }

  void _showSuccessDialog(Map<String, String> feedback) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Feedback Berhasil Dikirim!'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Data yang Anda kirim:'),
                const SizedBox(height: 16),
                Text('Nama: ${feedback['name']}'),
                Text('Email: ${feedback['email']}'),
                Text('Feedback: ${feedback['feedback']}'),
                const SizedBox(height: 16),
                const Text(
                  'Terima kasih atas feedback Anda!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearForm();
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Tetap tampilkan data di form
              },
              child: const Text('Lihat Detail'),
            ),
          ],
        );
      },
    );
  }

  void _showCurrentInput() {
    if (_nameController.text.isEmpty &&
        _emailController.text.isEmpty &&
        _feedbackController.text.isEmpty) {
      _showNoDataDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Data yang Sudah Diinput'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nama: ${_nameController.text.isEmpty ? "(Belum diisi)" : _nameController.text}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${_emailController.text.isEmpty ? "(Belum diisi)" : _emailController.text}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Feedback: ${_feedbackController.text.isEmpty ? "(Belum diisi)" : _feedbackController.text}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackHistory() {
    if (feedbackHistory.isEmpty) {
      _showNoDataDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('History Feedback'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: feedbackHistory.length,
              itemBuilder: (context, index) {
                final feedback = feedbackHistory.reversed.toList()[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback ${feedbackHistory.length - index}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Nama: ${feedback['name']}'),
                      Text('Email: ${feedback['email']}'),
                      Text('Waktu: ${feedback['time']}'),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showNoDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tidak Ada Data'),
          content: const Text('Belum ada data yang diinput.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _feedbackController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _feedbackFocusNode.dispose();
    super.dispose();
  }
}
