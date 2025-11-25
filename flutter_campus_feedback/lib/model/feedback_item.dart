class FeedbackItem {
  final String id;
  final String name;
  final String nim;
  final String faculty;
  final List<String> facilities;
  final double satisfaction;
  final String feedbackType;
  final String? additionalMessage;
  final bool agreedToTerms;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.name,
    required this.nim,
    required this.faculty,
    required this.facilities,
    required this.satisfaction,
    required this.feedbackType,
    this.additionalMessage,
    required this.agreedToTerms,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nim': nim,
      'faculty': faculty,
      'facilities': facilities,
      'satisfaction': satisfaction,
      'feedbackType': feedbackType,
      'additionalMessage': additionalMessage,
      'agreedToTerms': agreedToTerms,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedbackItem.fromMap(Map<String, dynamic> map) {
    return FeedbackItem(
      id: map['id'],
      name: map['name'],
      nim: map['nim'],
      faculty: map['faculty'],
      facilities: List<String>.from(map['facilities']),
      satisfaction: map['satisfaction'],
      feedbackType: map['feedbackType'],
      additionalMessage: map['additionalMessage'],
      agreedToTerms: map['agreedToTerms'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
