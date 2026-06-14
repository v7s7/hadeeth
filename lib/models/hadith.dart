import 'package:cloud_firestore/cloud_firestore.dart';

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

  Hadith copyWith({
    String? title,
    String? hadithText,
    String? narrator,
    String? sourceBook,
    String? sourceReference,
    AuthenticityGrade? authenticityGrade,
    String? shortExplanation,
    String? detailedExplanation,
    List<String>? benefits,
    List<StrangeWord>? strangeWords,
    String? categoryId,
    List<String>? tags,
    bool? isAbandonedSunnah,
    DifficultyLevel? difficultyLevel,
    List<QuizQuestion>? quizQuestions,
    ContentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return Hadith(
      id: id,
      title: title ?? this.title,
      hadithText: hadithText ?? this.hadithText,
      narrator: narrator ?? this.narrator,
      sourceBook: sourceBook ?? this.sourceBook,
      sourceReference: sourceReference ?? this.sourceReference,
      authenticityGrade: authenticityGrade ?? this.authenticityGrade,
      shortExplanation: shortExplanation ?? this.shortExplanation,
      detailedExplanation: detailedExplanation ?? this.detailedExplanation,
      benefits: benefits ?? this.benefits,
      strangeWords: strangeWords ?? this.strangeWords,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      isAbandonedSunnah: isAbandonedSunnah ?? this.isAbandonedSunnah,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      quizQuestions: quizQuestions ?? this.quizQuestions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  /// تحويل الحديث إلى صيغة قابلة للتخزين في Firestore.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'hadithText': hadithText,
      'narrator': narrator,
      'sourceBook': sourceBook,
      'sourceReference': sourceReference,
      'authenticityGrade': authenticityGrade.name,
      'shortExplanation': shortExplanation,
      'detailedExplanation': detailedExplanation,
      'benefits': benefits,
      'strangeWords': strangeWords.map((word) => word.toMap()).toList(),
      'categoryId': categoryId,
      'tags': tags,
      'isAbandonedSunnah': isAbandonedSunnah,
      'difficultyLevel': difficultyLevel.name,
      'quizQuestions': quizQuestions.map((question) => question.toMap()).toList(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
    };
  }

  /// إنشاء حديث من مستند Firestore.
  factory Hadith.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic value) {
      if (value == null) return null;
      return parseDate(value);
    }

    return Hadith(
      id: id,
      title: map['title'] as String? ?? '',
      hadithText: map['hadithText'] as String? ?? '',
      narrator: map['narrator'] as String? ?? '',
      sourceBook: map['sourceBook'] as String? ?? '',
      sourceReference: map['sourceReference'] as String? ?? '',
      authenticityGrade: AuthenticityGrade.fromName(map['authenticityGrade'] as String?),
      shortExplanation: map['shortExplanation'] as String? ?? '',
      detailedExplanation: map['detailedExplanation'] as String? ?? '',
      benefits: List<String>.from(map['benefits'] as List? ?? const []),
      strangeWords: (map['strangeWords'] as List? ?? const [])
          .map((item) => StrangeWord.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      categoryId: map['categoryId'] as String? ?? '',
      tags: List<String>.from(map['tags'] as List? ?? const []),
      isAbandonedSunnah: map['isAbandonedSunnah'] as bool? ?? false,
      difficultyLevel: DifficultyLevel.fromName(map['difficultyLevel'] as String?),
      quizQuestions: (map['quizQuestions'] as List? ?? const [])
          .map((item) => QuizQuestion.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      status: ContentStatus.fromName(map['status'] as String?),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      publishedAt: parseOptionalDate(map['publishedAt']),
    );
  }
}
