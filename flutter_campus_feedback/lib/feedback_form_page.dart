import 'package:flutter/material.dart';
import 'feedback_list_page.dart';
import 'model/feedback_item.dart';

class FeedbackFormPage extends StatefulWidget {
  final Function(FeedbackItem) onFeedbackSubmitted;

  const FeedbackFormPage({super.key, required this.onFeedbackSubmitted});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _selectedFaculty = 'Fakultas Sains dan Teknologi';
  final List<String> _selectedFacilities = [];
  double _satisfactionValue = 3.0;
  String _selectedFeedbackType = 'Saran';
  bool _agreedToTerms = false;

  final List<String> _faculties = [
    'Fakultas Sains dan Teknologi',
    'Fakultas Dakwah',
    'Fakultas Ekonomi dan Bisnis Islam',
    'Fakultas Tarbiyah dan Keguruan',
    'Fakultas Kedokteran',
    'Fakultas Syariah',
    'Fakultas Ushuluddin dan Studi Agama',
    'Fakultas Adab dan Humaniora',
  ];

  final List<String> _facilities = [
    'Perpustakaan',
    'Laboratorium',
    'Ruang Kelas',
    'Fasilitas Olahraga',
    'Kantin',
    'WiFi Kampus',
    'Parkir',
    'Layanan Administrasi',
  ];

  final List<String> _feedbackTypes = ['Saran', 'Keluhan', 'Apresiasi'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Feedback Mahasiswa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Mahasiswa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama mahasiswa wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nimController,
                decoration: const InputDecoration(
                  labelText: 'NIM',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NIM wajib diisi';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'NIM harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFaculty,
                decoration: const InputDecoration(
                  labelText: 'Fakultas',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                items: _faculties.map((String faculty) {
                  return DropdownMenuItem<String>(
                    value: faculty,
                    child: Text(faculty),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFaculty = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Fasilitas yang Dinilai:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._facilities.map((facility) {
                return CheckboxListTile(
                  title: Text(facility),
                  value: _selectedFacilities.contains(facility),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedFacilities.add(facility);
                      } else {
                        _selectedFacilities.remove(facility);
                      }
                    });
                  },
                );
              }),
              if (_selectedFacilities.isEmpty)
                const Text(
                  'Pilih minimal satu fasilitas',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 16),
              const Text(
                'Nilai Kepuasan:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('1'),
                  Expanded(
                    child: Slider(
                      value: _satisfactionValue,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _satisfactionValue.toStringAsFixed(1),
                      onChanged: (double value) {
                        setState(() {
                          _satisfactionValue = value;
                        });
                      },
                    ),
                  ),
                  const Text('5'),
                ],
              ),
              Center(
                child: Text(
                  'Nilai: ${_satisfactionValue.toStringAsFixed(1)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Jenis Feedback:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ..._feedbackTypes.map((type) {
                return RadioListTile<String>(
                  title: Text(type),
                  value: type,
                  groupValue: _selectedFeedbackType,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFeedbackType = value!;
                    });
                  },
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Pesan Tambahan (Opsional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Saya setuju dengan syarat & ketentuan'),
                value: _agreedToTerms,
                onChanged: (bool value) {
                  setState(() {
                    _agreedToTerms = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Simpan Feedback',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap perbaiki kesalahan pada form')),
      );
      return;
    }

    if (_selectedFacilities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu fasilitas')),
      );
      return;
    }

    if (!_agreedToTerms) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text(
                'Anda harus menyetujui syarat & ketentuan sebelum menyimpan feedback.'),
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
      return;
    }

    final feedback = FeedbackItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      nim: _nimController.text,
      faculty: _selectedFaculty,
      facilities: _selectedFacilities,
      satisfaction: _satisfactionValue,
      feedbackType: _selectedFeedbackType,
      additionalMessage:
          _messageController.text.isEmpty ? null : _messageController.text,
      agreedToTerms: _agreedToTerms,
      createdAt: DateTime.now(),
    );

    widget.onFeedbackSubmitted(feedback);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback berhasil disimpan!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackListPage(
          feedbackList: [feedback],
          onFeedbackDeleted: (String id) {},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
