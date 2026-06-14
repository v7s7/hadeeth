import 'enums.dart';
import 'quiz_question.dart';
import 'strange_word.dart';

/// النموذج الأساسي للحديث كما يُدخله المشرف من لوحة التحكم.
class Hadith {
  final String id;
  final String title;
  final String hadithText;
  final String narrator;
  final String sourceBook;
  final String sourceReference;
  final AuthenticityGrade authenticityGrade;
  final String shortExplanation;
  final String detailedExplanation;
  final List<String> benefits;
  final List<StrangeWord> strangeWords;
  final String categoryId;
  final List<String> tags;
  final bool isAbandonedSunnah;
  final DifficultyLevel difficultyLevel;
  final List<QuizQuestion> quizQuestions;
  final ContentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const Hadith({
    required this.id,
    required this.title,
    required this.hadithText,
    required this.narrator,
    required this.sourceBook,
    required this.sourceReference,
    required this.authenticityGrade,
    required this.shortExplanation,
    required this.detailedExplanation,
    required this.benefits,
    required this.categoryId,
    required this.tags,
    required this.isAbandonedSunnah,
    required this.difficultyLevel,
    required this.quizQuestions,
    required this.createdAt,
    required this.updatedAt,
    this.strangeWords = const [],
    this.status = ContentStatus.published,
    this.publishedAt,
  });

  /// المصدر كاملاً بصيغة "الكتاب، المرجع".
  String get fullSource => '$sourceBook، $sourceReference';
}
