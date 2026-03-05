// lib/models/ramadan_question.dart

class RamadanQuestion {
  final String id;
  final String questionDate;
  final String text;
  final List<RamadanOption> options;
  final bool hasAnswered;
  final DateTime? answeredAt;

  // History specific fields from Swagger
  final String? correctOptionId;
  final String? selectedOptionId;
  final bool? isCorrect;
  final bool expired;

  RamadanQuestion({
    required this.id,
    required this.questionDate,
    required this.text,
    required this.options,
    required this.hasAnswered,
    this.answeredAt,
    this.correctOptionId,
    this.selectedOptionId,
    this.isCorrect,
    this.expired = false,
  });

  factory RamadanQuestion.fromJson(Map<String, dynamic> json) {
    return RamadanQuestion(
      id: json['id']?.toString() ?? '',
      questionDate: json['questionDate']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      options: (json['options'] as List? ?? [])
          .map((o) => RamadanOption.fromJson(o))
          .toList(),
      hasAnswered: json['hasAnswered'] ?? false,
      answeredAt: json['answeredAt'] != null
          ? DateTime.tryParse(json['answeredAt'])
          : null,
      correctOptionId: json['correctOptionId']?.toString(),
      selectedOptionId: json['selectedOptionId']?.toString(),
      isCorrect: json['isCorrect'] as bool?,
      expired: json['expired'] ?? false,
    );
  }
}

class RamadanOption {
  final String id;
  final String text;

  RamadanOption({required this.id, required this.text});

  factory RamadanOption.fromJson(Map<String, dynamic> json) {
    return RamadanOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String username;
  final int totalAnswered;
  final int correctAnswers;
  final double accuracy;
  final DateTime? lastAnsweredAt;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.totalAnswered,
    required this.correctAnswers,
    required this.accuracy,
    this.lastAnsweredAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      username: json['username'] ?? 'Anonymous',
      totalAnswered: json['totalAnswered'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      lastAnsweredAt: json['lastAnsweredAt'] != null
          ? DateTime.tryParse(json['lastAnsweredAt'])
          : null,
    );
  }
}
