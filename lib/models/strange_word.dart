/// كلمة غريبة في نص الحديث مع معناها.
class StrangeWord {
  final String word;
  final String meaning;

  const StrangeWord({
    required this.word,
    required this.meaning,
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'meaning': meaning,
    };
  }

  factory StrangeWord.fromMap(Map<String, dynamic> map) {
    return StrangeWord(
      word: map['word'] as String? ?? '',
      meaning: map['meaning'] as String? ?? '',
    );
  }
}
