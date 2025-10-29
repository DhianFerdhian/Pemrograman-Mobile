import 'package:flutter/material.dart';
import 'feedback_result.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _comment = '';
  int _rating = 3;

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackResultPage(
            name: _name,
            comment: _comment,
            rating: _rating,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan nama';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Komentar',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan komentar';
                  }
                  return null;
                },
                onSaved: (value) {
                  _comment = value!;
                },
              ),

              const SizedBox(height: 20),

              const Text('Rating:'),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  int rating = index + 1;
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = rating;
                      });
                    },
                    icon: Icon(
                      rating <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 40,
                    ),
                  );
                }),
              ),
              Text('$_rating/5'),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _submitFeedback,
                child: const Text('Submit Feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
