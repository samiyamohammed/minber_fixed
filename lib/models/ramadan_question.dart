// lib/models/ramadan_question.dart

class RamadanQuestion {
  final String id;
  final String questionDate;
  final String text;
  final List<RamadanOption> options;
  final bool hasAnswered;
  final DateTime? answeredAt;

  RamadanQuestion({
    required this.id,
    required this.questionDate,
    required this.text,
    required this.options,
    required this.hasAnswered,
    this.answeredAt,
  });

  factory RamadanQuestion.fromJson(Map<String, dynamic> json) {
    return RamadanQuestion(
      id: json['id'] ?? '',
      questionDate: json['questionDate'] ?? '',
      text: json['text'] ?? '',
      options: (json['options'] as List? ?? [])
          .map((o) => RamadanOption.fromJson(o))
          .toList(),
      hasAnswered: json['hasAnswered'] ?? false,
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'])
          : null,
    );
  }
}

class RamadanOption {
  final String id;
  final String text;

  RamadanOption({required this.id, required this.text});

  factory RamadanOption.fromJson(Map<String, dynamic> json) {
    return RamadanOption(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
    );
  }
}
