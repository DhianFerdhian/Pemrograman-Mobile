import 'package:flutter/material.dart';
import 'feedback_detail_page.dart';
import 'model/feedback_item.dart';

class FeedbackListPage extends StatefulWidget {
  final List<FeedbackItem> feedbackList;
  final Function(String) onFeedbackDeleted;

  const FeedbackListPage({
    super.key,
    required this.feedbackList,
    required this.onFeedbackDeleted,
  });

  @override
  State<FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<FeedbackListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Feedback'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: widget.feedbackList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feedback, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada feedback',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: widget.feedbackList.length,
              itemBuilder: (context, index) {
                final feedback = widget.feedbackList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: _getFeedbackIcon(feedback.feedbackType),
                    title: Text(feedback.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(feedback.faculty),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('${feedback.satisfaction.toStringAsFixed(1)}'),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedbackDetailPage(
                            feedback: feedback,
                            onDelete: () {
                              widget.onFeedbackDeleted(feedback.id);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _getFeedbackIcon(String feedbackType) {
    switch (feedbackType) {
      case 'Apresiasi':
        return const Icon(Icons.thumb_up, color: Colors.green);
      case 'Keluhan':
        return const Icon(Icons.thumb_down, color: Colors.red);
      case 'Saran':
        return const Icon(Icons.lightbulb, color: Colors.orange);
      default:
        return const Icon(Icons.feedback, color: Colors.blue);
    }
  }
}
