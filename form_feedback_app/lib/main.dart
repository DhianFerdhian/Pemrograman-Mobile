import 'package:flutter/material.dart';
import 'feedback_form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Feedback App',
      home: const FeedbackFormPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
