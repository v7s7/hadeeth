import 'enums.dart';

/// سؤال اختيار من متعدد مرتبط بحديث معيّن.
class QuizQuestion {
  final String id;
  final QuizQuestionType type;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.type,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as String? ?? '',
      type: QuizQuestionType.fromName(map['type'] as String?),
      questionText: map['questionText'] as String? ?? '',
      options: List<String>.from(map['options'] as List? ?? const []),
      correctOptionIndex: map['correctOptionIndex'] as int? ?? 0,
      explanation: map['explanation'] as String? ?? '',
    );
  }
}
