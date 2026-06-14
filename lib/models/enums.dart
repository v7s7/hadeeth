/// درجة صحة الحديث. في النسخة الأولى نعرض الأحاديث الصحيحة فقط.
enum AuthenticityGrade {
  sahih;

  String get labelAr {
    switch (this) {
      case AuthenticityGrade.sahih:
        return 'صحيح';
    }
  }

  static AuthenticityGrade fromName(String? name) {
    return AuthenticityGrade.values.firstWhere(
      (value) => value.name == name,
      orElse: () => AuthenticityGrade.sahih,
    );
  }
}

/// مستوى صعوبة الحديث (يُستخدم في الفلترة وفي اختيار الأسئلة).
enum DifficultyLevel {
  easy,
  medium,
  advanced;

  String get labelAr {
    switch (this) {
      case DifficultyLevel.easy:
        return 'سهل';
      case DifficultyLevel.medium:
        return 'متوسط';
      case DifficultyLevel.advanced:
        return 'متقدم';
    }
  }

  static DifficultyLevel fromName(String? name) {
    return DifficultyLevel.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DifficultyLevel.easy,
    );
  }
}

/// حالة نشر المحتوى من لوحة التحكم.
enum ContentStatus {
  draft,
  published,
  hidden;

  String get labelAr {
    switch (this) {
      case ContentStatus.draft:
        return 'مسودة';
      case ContentStatus.published:
        return 'منشور';
      case ContentStatus.hidden:
        return 'مخفي';
    }
  }

  static ContentStatus fromName(String? name) {
    return ContentStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ContentStatus.published,
    );
  }
}

/// نوع سؤال الاختبار.
enum QuizQuestionType {
  meaning,
  narrator,
  benefit,
  source,
  application;

  String get labelAr {
    switch (this) {
      case QuizQuestionType.meaning:
        return 'معنى الحديث';
      case QuizQuestionType.narrator:
        return 'الراوي';
      case QuizQuestionType.benefit:
        return 'الفائدة المستفادة';
      case QuizQuestionType.source:
        return 'مصدر الحديث';
      case QuizQuestionType.application:
        return 'تطبيق عملي';
    }
  }

  static QuizQuestionType fromName(String? name) {
    return QuizQuestionType.values.firstWhere(
      (value) => value.name == name,
      orElse: () => QuizQuestionType.meaning,
    );
  }
}
