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
}
