/// يمثل تقدّم المستخدم (ضيفًا أو مسجّلاً) ويُخزَّن محليًا أو في السحابة.
class UserProgress {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final Set<String> readHadithIds;
  final Set<String> learnedHadithIds;
  final Set<String> savedHadithIds;
  final int quizzesCompleted;
  final int quizCorrectAnswers;
  final int quizTotalAnswers;
  final int dailyXpEarned;
  final DateTime? lastXpDate;

  /// نشاط آخر 7 أيام: مفتاحه تاريخ بصيغة yyyy-MM-dd وقيمته نقاط الخبرة المكتسبة في ذلك اليوم.
  final Map<String, int> dailyActivityXp;

  const UserProgress({
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.readHadithIds,
    required this.learnedHadithIds,
    required this.savedHadithIds,
    required this.quizzesCompleted,
    required this.quizCorrectAnswers,
    required this.quizTotalAnswers,
    required this.dailyXpEarned,
    required this.lastXpDate,
    required this.dailyActivityXp,
  });

  factory UserProgress.initial() => UserProgress(
        totalXp: 0,
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
        readHadithIds: <String>{},
        learnedHadithIds: <String>{},
        savedHadithIds: <String>{},
        quizzesCompleted: 0,
        quizCorrectAnswers: 0,
        quizTotalAnswers: 0,
        dailyXpEarned: 0,
        lastXpDate: null,
        dailyActivityXp: <String, int>{},
      );

  double get quizAccuracy =>
      quizTotalAnswers == 0 ? 0 : quizCorrectAnswers / quizTotalAnswers;

  UserProgress copyWith({
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    Set<String>? readHadithIds,
    Set<String>? learnedHadithIds,
    Set<String>? savedHadithIds,
    int? quizzesCompleted,
    int? quizCorrectAnswers,
    int? quizTotalAnswers,
    int? dailyXpEarned,
    DateTime? lastXpDate,
    Map<String, int>? dailyActivityXp,
  }) {
    return UserProgress(
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      readHadithIds: readHadithIds ?? this.readHadithIds,
      learnedHadithIds: learnedHadithIds ?? this.learnedHadithIds,
      savedHadithIds: savedHadithIds ?? this.savedHadithIds,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      quizCorrectAnswers: quizCorrectAnswers ?? this.quizCorrectAnswers,
      quizTotalAnswers: quizTotalAnswers ?? this.quizTotalAnswers,
      dailyXpEarned: dailyXpEarned ?? this.dailyXpEarned,
      lastXpDate: lastXpDate ?? this.lastXpDate,
      dailyActivityXp: dailyActivityXp ?? this.dailyActivityXp,
    );
  }

  /// يدمج تقدّمَين معًا بأخذ الأعلى في كل حقل رقمي، واتحاد القوائم.
  /// مفيد عند تسجيل دخول مستخدم لدمج بياناته المحلية مع ما في السحابة.
  UserProgress merge(UserProgress other) {
    return UserProgress(
      totalXp: totalXp > other.totalXp ? totalXp : other.totalXp,
      currentStreak:
          currentStreak > other.currentStreak ? currentStreak : other.currentStreak,
      longestStreak:
          longestStreak > other.longestStreak ? longestStreak : other.longestStreak,
      lastActivityDate:
          (lastActivityDate != null && other.lastActivityDate != null)
              ? (lastActivityDate!.isAfter(other.lastActivityDate!)
                  ? lastActivityDate
                  : other.lastActivityDate)
              : (lastActivityDate ?? other.lastActivityDate),
      readHadithIds: {...readHadithIds, ...other.readHadithIds},
      learnedHadithIds: {...learnedHadithIds, ...other.learnedHadithIds},
      savedHadithIds: {...savedHadithIds, ...other.savedHadithIds},
      quizzesCompleted: quizzesCompleted > other.quizzesCompleted
          ? quizzesCompleted
          : other.quizzesCompleted,
      quizCorrectAnswers: quizCorrectAnswers > other.quizCorrectAnswers
          ? quizCorrectAnswers
          : other.quizCorrectAnswers,
      quizTotalAnswers: quizTotalAnswers > other.quizTotalAnswers
          ? quizTotalAnswers
          : other.quizTotalAnswers,
      // نحتفظ بقيم الجهاز الحالي لليوم الحالي.
      dailyXpEarned: dailyXpEarned,
      lastXpDate: lastXpDate,
      dailyActivityXp: {
        ...other.dailyActivityXp,
        ...dailyActivityXp, // يُقدَّم الجهاز الحالي في حالة تداخل التواريخ.
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActivityDate': lastActivityDate?.toIso8601String(),
        'readHadithIds': readHadithIds.toList(),
        'learnedHadithIds': learnedHadithIds.toList(),
        'savedHadithIds': savedHadithIds.toList(),
        'quizzesCompleted': quizzesCompleted,
        'quizCorrectAnswers': quizCorrectAnswers,
        'quizTotalAnswers': quizTotalAnswers,
        'dailyXpEarned': dailyXpEarned,
        'lastXpDate': lastXpDate?.toIso8601String(),
        'dailyActivityXp': dailyActivityXp,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        totalXp: json['totalXp'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastActivityDate: json['lastActivityDate'] == null
            ? null
            : DateTime.parse(json['lastActivityDate'] as String),
        readHadithIds: ((json['readHadithIds'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        learnedHadithIds: ((json['learnedHadithIds'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        savedHadithIds: ((json['savedHadithIds'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        quizzesCompleted: json['quizzesCompleted'] as int? ?? 0,
        quizCorrectAnswers: json['quizCorrectAnswers'] as int? ?? 0,
        quizTotalAnswers: json['quizTotalAnswers'] as int? ?? 0,
        dailyXpEarned: json['dailyXpEarned'] as int? ?? 0,
        lastXpDate: json['lastXpDate'] == null
            ? null
            : DateTime.parse(json['lastXpDate'] as String),
        dailyActivityXp: ((json['dailyActivityXp'] as Map?) ?? const {}).map(
          (key, value) => MapEntry(key as String, value as int),
        ),
      );
}
