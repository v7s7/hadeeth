import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_accessory.dart';
import '../../models/app_characters.dart';
import '../../models/hadith.dart';
import '../../models/quiz_question.dart';
import '../../services/hadith_repository.dart';
import '../../services/local_storage_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/completion_overlay.dart';
import '../../widgets/empty_state.dart';

/// شاشة الاختبار: ثلاثة أسئلة اختيار من متعدد لكل حديث، مع عرض الإجابة
/// الصحيحة وشرحها بعد كل سؤال، ومنح نقاط الخبرة عند الإنهاء.
class QuizScreen extends StatefulWidget {
  final String hadithId;

  const QuizScreen({super.key, required this.hadithId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _answered = false;
  int _correctCount = 0;
  bool _finished = false;
  int _xpGained = 0;
  bool _isSubmitting = false;

  void _selectOption(int index) {
    if (_answered) return;
    setState(() => _selectedOptionIndex = index);
  }

  void _confirmAnswer(QuizQuestion question) {
    if (_selectedOptionIndex == null) return;
    setState(() {
      _answered = true;
      if (_selectedOptionIndex == question.correctOptionIndex) {
        _correctCount++;
      }
    });
  }

  Future<void> _next(List<QuizQuestion> questions) async {
    if (_currentIndex < questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _answered = false;
      });
      return;
    }

    setState(() => _isSubmitting = true);
    final progressService = context.read<ProgressService>();
    final levelBefore = progressService.currentLevel.level;
    final xpGained = await progressService.completeQuiz(
      correct: _correctCount,
      total: questions.length,
    );

    if (!mounted) return;

    if (xpGained > 0) {
      final totalXpAfter = progressService.progress.totalXp;
      final levelAfter = progressService.currentLevel.level;
      final newStreak = progressService.progress.currentStreak;

      final charId = LocalStorageService.cachedCharacterId ??
          await LocalStorageService().loadCharacterId();
      final character = AppCharacters.findById(charId);

      final accessoryId = LocalStorageService.cachedActiveAccessoryId ??
          await LocalStorageService().loadActiveAccessoryId();
      final accessory = AppAccessories.findById(accessoryId);

      if (!mounted) return;

      final isPerfect = _correctCount == questions.length;
      await showCompletionOverlay(
        context: context,
        xpGained: xpGained,
        newStreak: newStreak,
        totalXpAfter: totalXpAfter,
        levelBefore: levelBefore,
        levelAfter: levelAfter,
        character: character,
        accessory: accessory,
        title: isPerfect ? 'إجابة كاملة!' : 'أحسنتَ!',
        subtitle: '$_correctCount من ${questions.length} إجابات صحيحة',
      );
    }

    if (!mounted) return;
    setState(() {
      _finished = true;
      _xpGained = xpGained;
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<HadithRepository>();
    final hadith = repository.getById(widget.hadithId);

    if (hadith == null || hadith.quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('الاختبار')),
        body: const EmptyState(
          icon: Icons.quiz_outlined,
          title: 'لا يوجد اختبار لهذا الحديث حاليًا',
        ),
      );
    }

    final questions = hadith.quizQuestions;

    if (_finished) {
      return _QuizResultView(
        hadith: hadith,
        correctCount: _correctCount,
        total: questions.length,
        xpGained: _xpGained,
      );
    }

    final question = questions[_currentIndex];
    final progressValue = (_currentIndex + (_answered ? 1 : 0)) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(hadith.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'السؤال ${_currentIndex + 1} من ${questions.length}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progressValue, minHeight: 6),
              ),
              const SizedBox(height: 20),
              Text(question.questionText, style: AppTextStyles.sectionTitle),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _OptionTile(
                    text: question.options[index],
                    isSelected: _selectedOptionIndex == index,
                    isCorrect: index == question.correctOptionIndex,
                    answered: _answered,
                    onTap: () => _selectOption(index),
                  ),
                ),
              ),
              if (_answered) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedOptionIndex == question.correctOptionIndex
                            ? 'إجابة صحيحة!'
                            : 'إجابة غير صحيحة',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: _selectedOptionIndex == question.correctOptionIndex
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(question.explanation, style: AppTextStyles.body),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : _answered
                          ? () => _next(questions)
                          : _selectedOptionIndex == null
                              ? null
                              : () => _confirmAnswer(question),
                  child: Text(
                    _answered
                        ? (_currentIndex == questions.length - 1 ? 'عرض النتيجة' : 'السؤال التالي')
                        : 'تأكيد الإجابة',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool answered;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.divider;
    Color? backgroundColor;
    IconData? trailingIcon;
    Color? trailingColor;

    if (answered) {
      if (isCorrect) {
        borderColor = AppColors.success;
        backgroundColor = AppColors.success.withOpacity(0.08);
        trailingIcon = Icons.check_circle;
        trailingColor = AppColors.success;
      } else if (isSelected) {
        borderColor = AppColors.error;
        backgroundColor = AppColors.error.withOpacity(0.08);
        trailingIcon = Icons.cancel;
        trailingColor = AppColors.error;
      }
    } else if (isSelected) {
      borderColor = AppColors.primary;
      backgroundColor = AppColors.primaryLight;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: (isSelected || (answered && isCorrect)) ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: AppTextStyles.body)),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: trailingColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  final Hadith hadith;
  final int correctCount;
  final int total;
  final int xpGained;

  const _QuizResultView({
    required this.hadith,
    required this.correctCount,
    required this.total,
    required this.xpGained,
  });

  @override
  Widget build(BuildContext context) {
    final isPerfect = total > 0 && correctCount == total;

    return Scaffold(
      appBar: AppBar(title: const Text('نتيجة الاختبار')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPerfect ? Icons.emoji_events : Icons.check_circle_outline,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '$correctCount من $total إجابات صحيحة',
                style: AppTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (xpGained > 0)
                Text(
                  '+$xpGained XP',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.accentDark),
                )
              else
                Text(
                  'لقد بلغت الحد اليومي من نقاط الخبرة',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              if (isPerfect) ...[
                const SizedBox(height: 8),
                Text(
                  'إجابة كاملة! أحسنت.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/hadith/${hadith.id}'),
                  child: const Text('العودة إلى الحديث'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('العودة إلى الرئيسية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
