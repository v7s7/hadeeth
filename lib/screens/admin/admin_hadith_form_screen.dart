import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/hadith.dart';
import '../../models/quiz_question.dart';
import '../../models/strange_word.dart';
import '../../services/category_repository.dart';
import '../../services/hadith_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'admin_guard.dart';

/// شاشة إضافة/تعديل حديث: نموذج كامل لكل بيانات الحديث، الفوائد، الكلمات
/// الغريبة وأسئلة الاختبار.
class AdminHadithFormScreen extends StatefulWidget {
  final String? hadithId;

  const AdminHadithFormScreen({super.key, this.hadithId});

  @override
  State<AdminHadithFormScreen> createState() => _AdminHadithFormScreenState();
}

class _AdminHadithFormScreenState extends State<AdminHadithFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _hadithTextController;
  late final TextEditingController _narratorController;
  late final TextEditingController _sourceBookController;
  late final TextEditingController _sourceReferenceController;
  late final TextEditingController _shortExplanationController;
  late final TextEditingController _detailedExplanationController;
  late final TextEditingController _tagsController;

  String? _categoryId;
  DifficultyLevel _difficultyLevel = DifficultyLevel.easy;
  ContentStatus _status = ContentStatus.draft;
  bool _isAbandonedSunnah = false;
  bool _isSaving = false;

  late List<_TextItem> _benefits;
  late List<_StrangeWordItem> _strangeWords;
  late List<_QuizQuestionItem> _quizQuestions;

  @override
  void initState() {
    super.initState();

    final hadith = widget.hadithId != null
        ? context.read<HadithRepository>().getById(widget.hadithId!)
        : null;

    _titleController = TextEditingController(text: hadith?.title ?? '');
    _hadithTextController = TextEditingController(text: hadith?.hadithText ?? '');
    _narratorController = TextEditingController(text: hadith?.narrator ?? '');
    _sourceBookController = TextEditingController(text: hadith?.sourceBook ?? '');
    _sourceReferenceController = TextEditingController(text: hadith?.sourceReference ?? '');
    _shortExplanationController = TextEditingController(text: hadith?.shortExplanation ?? '');
    _detailedExplanationController = TextEditingController(text: hadith?.detailedExplanation ?? '');
    _tagsController = TextEditingController(text: hadith?.tags.join(', ') ?? '');

    _categoryId = hadith?.categoryId;
    _difficultyLevel = hadith?.difficultyLevel ?? DifficultyLevel.easy;
    _status = hadith?.status ?? ContentStatus.draft;
    _isAbandonedSunnah = hadith?.isAbandonedSunnah ?? false;

    _benefits = (hadith?.benefits ?? const []).map((b) => _TextItem(text: b)).toList();
    _strangeWords = (hadith?.strangeWords ?? const [])
        .map((w) => _StrangeWordItem(word: w.word, meaning: w.meaning))
        .toList();
    _quizQuestions = (hadith?.quizQuestions ?? const [])
        .map((q) => _QuizQuestionItem.fromQuestion(q))
        .toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hadithTextController.dispose();
    _narratorController.dispose();
    _sourceBookController.dispose();
    _sourceReferenceController.dispose();
    _shortExplanationController.dispose();
    _detailedExplanationController.dispose();
    _tagsController.dispose();
    for (final item in _benefits) {
      item.dispose();
    }
    for (final item in _strangeWords) {
      item.dispose();
    }
    for (final item in _quizQuestions) {
      item.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  void _addBenefit() => setState(() => _benefits.add(_TextItem()));

  void _removeBenefit(int index) {
    setState(() {
      _benefits[index].dispose();
      _benefits.removeAt(index);
    });
  }

  void _addStrangeWord() => setState(() => _strangeWords.add(_StrangeWordItem()));

  void _removeStrangeWord(int index) {
    setState(() {
      _strangeWords[index].dispose();
      _strangeWords.removeAt(index);
    });
  }

  void _addQuizQuestion() {
    setState(() {
      _quizQuestions.add(
        _QuizQuestionItem(id: 'q${DateTime.now().millisecondsSinceEpoch}_${_quizQuestions.length}'),
      );
    });
  }

  void _removeQuizQuestion(int index) {
    setState(() {
      _quizQuestions[index].dispose();
      _quizQuestions.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final repository = context.read<HadithRepository>();
    final now = DateTime.now();
    final existing = widget.hadithId != null ? repository.getById(widget.hadithId!) : null;

    final hadith = Hadith(
      id: widget.hadithId ?? '',
      title: _titleController.text.trim(),
      hadithText: _hadithTextController.text.trim(),
      narrator: _narratorController.text.trim(),
      sourceBook: _sourceBookController.text.trim(),
      sourceReference: _sourceReferenceController.text.trim(),
      authenticityGrade: AuthenticityGrade.sahih,
      shortExplanation: _shortExplanationController.text.trim(),
      detailedExplanation: _detailedExplanationController.text.trim(),
      benefits: _benefits
          .map((b) => b.controller.text.trim())
          .where((b) => b.isNotEmpty)
          .toList(),
      strangeWords: _strangeWords
          .map((w) => StrangeWord(
                word: w.wordController.text.trim(),
                meaning: w.meaningController.text.trim(),
              ))
          .where((w) => w.word.isNotEmpty && w.meaning.isNotEmpty)
          .toList(),
      categoryId: _categoryId!,
      tags: _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      isAbandonedSunnah: _isAbandonedSunnah,
      difficultyLevel: _difficultyLevel,
      quizQuestions: _quizQuestions.map((q) => q.toQuestion()).toList(),
      status: _status,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      publishedAt: _status == ContentStatus.published ? (existing?.publishedAt ?? now) : existing?.publishedAt,
    );

    try {
      if (widget.hadithId == null) {
        await repository.addHadith(hadith);
      } else {
        await repository.updateHadith(hadith);
      }
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الحفظ. تأكد من إعداد Firebase.')),
        );
      }
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: AppTextStyles.sectionTitle),
    );
  }

  Widget _buildBenefitField(int index, _TextItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: item.controller,
              decoration: InputDecoration(labelText: 'فائدة ${index + 1}'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: AppColors.error),
            onPressed: () => _removeBenefit(index),
          ),
        ],
      ),
    );
  }

  Widget _buildStrangeWordField(int index, _StrangeWordItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: item.wordController,
              decoration: const InputDecoration(labelText: 'الكلمة'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: item.meaningController,
              decoration: const InputDecoration(labelText: 'المعنى'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: AppColors.error),
            onPressed: () => _removeStrangeWord(index),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizQuestionCard(int index, _QuizQuestionItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('السؤال ${index + 1}', style: AppTextStyles.bodyBold)),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _removeQuizQuestion(index),
                ),
              ],
            ),
            DropdownButtonFormField<QuizQuestionType>(
              value: item.type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'نوع السؤال'),
              items: QuizQuestionType.values
                  .map((type) => DropdownMenuItem(value: type, child: Text(type.labelAr)))
                  .toList(),
              onChanged: (value) => setState(() => item.type = value ?? item.type),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: item.questionController,
              decoration: const InputDecoration(labelText: 'نص السؤال'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < 4; i++) ...[
              TextFormField(
                controller: item.optionControllers[i],
                decoration: InputDecoration(labelText: 'الخيار ${i + 1}'),
                validator: _required,
              ),
              const SizedBox(height: 10),
            ],
            DropdownButtonFormField<int>(
              value: item.correctOptionIndex,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'الإجابة الصحيحة'),
              items: List.generate(
                4,
                (i) => DropdownMenuItem(value: i, child: Text('الخيار ${i + 1}')),
              ),
              onChanged: (value) => setState(() => item.correctOptionIndex = value ?? 0),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: item.explanationController,
              decoration: const InputDecoration(labelText: 'شرح الإجابة'),
              maxLines: 2,
              validator: _required,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryRepository>().categories;
    final isEditing = widget.hadithId != null;
    final categoryIds = categories.map((c) => c.id).toSet();
    final categoryValue = categoryIds.contains(_categoryId) ? _categoryId : null;

    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'تعديل الحديث' : 'حديث جديد')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('المعلومات الأساسية'),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hadithTextController,
                  decoration: const InputDecoration(labelText: 'نص الحديث'),
                  maxLines: 4,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _narratorController,
                  decoration: const InputDecoration(labelText: 'الراوي'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sourceBookController,
                  decoration: const InputDecoration(labelText: 'الكتاب المصدر'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sourceReferenceController,
                  decoration: const InputDecoration(labelText: 'رقم/مرجع الحديث'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoryValue,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr)))
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) => value == null ? 'اختر تصنيفًا' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DifficultyLevel>(
                  value: _difficultyLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'مستوى الصعوبة'),
                  items: DifficultyLevel.values
                      .map((level) => DropdownMenuItem(value: level, child: Text(level.labelAr)))
                      .toList(),
                  onChanged: (value) => setState(() => _difficultyLevel = value ?? _difficultyLevel),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ContentStatus>(
                  value: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'حالة النشر'),
                  items: ContentStatus.values
                      .map((status) => DropdownMenuItem(value: status, child: Text(status.labelAr)))
                      .toList(),
                  onChanged: (value) => setState(() => _status = value ?? _status),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('من السنن المهجورة'),
                  value: _isAbandonedSunnah,
                  onChanged: (value) => setState(() => _isAbandonedSunnah = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'الوسوم',
                    helperText: 'مفصولة بفواصل، مثل: صلاة، أذكار',
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('الشرح'),
                TextFormField(
                  controller: _shortExplanationController,
                  decoration: const InputDecoration(labelText: 'شرح مختصر'),
                  maxLines: 2,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _detailedExplanationController,
                  decoration: const InputDecoration(labelText: 'شرح تفصيلي'),
                  maxLines: 5,
                  validator: _required,
                ),
                const SizedBox(height: 24),
                _sectionTitle('الفوائد'),
                ..._benefits.asMap().entries.map((entry) => _buildBenefitField(entry.key, entry.value)),
                TextButton.icon(
                  onPressed: _addBenefit,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة فائدة'),
                ),
                const SizedBox(height: 12),
                _sectionTitle('الكلمات الغريبة'),
                ..._strangeWords
                    .asMap()
                    .entries
                    .map((entry) => _buildStrangeWordField(entry.key, entry.value)),
                TextButton.icon(
                  onPressed: _addStrangeWord,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة كلمة'),
                ),
                const SizedBox(height: 12),
                _sectionTitle('أسئلة الاختبار'),
                ..._quizQuestions
                    .asMap()
                    .entries
                    .map((entry) => _buildQuizQuestionCard(entry.key, entry.value)),
                TextButton.icon(
                  onPressed: _addQuizQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة سؤال'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditing ? 'حفظ التعديلات' : 'إضافة الحديث'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextItem {
  final TextEditingController controller;

  _TextItem({String text = ''}) : controller = TextEditingController(text: text);

  void dispose() => controller.dispose();
}

class _StrangeWordItem {
  final TextEditingController wordController;
  final TextEditingController meaningController;

  _StrangeWordItem({String word = '', String meaning = ''})
      : wordController = TextEditingController(text: word),
        meaningController = TextEditingController(text: meaning);

  void dispose() {
    wordController.dispose();
    meaningController.dispose();
  }
}

class _QuizQuestionItem {
  String id;
  QuizQuestionType type;
  int correctOptionIndex;
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final TextEditingController explanationController;

  _QuizQuestionItem({
    String? id,
    this.type = QuizQuestionType.meaning,
    String questionText = '',
    List<String>? options,
    this.correctOptionIndex = 0,
    String explanation = '',
  })  : id = id ?? 'q${DateTime.now().microsecondsSinceEpoch}',
        questionController = TextEditingController(text: questionText),
        optionControllers = List.generate(
          4,
          (index) => TextEditingController(
            text: (options != null && index < options.length) ? options[index] : '',
          ),
        ),
        explanationController = TextEditingController(text: explanation);

  factory _QuizQuestionItem.fromQuestion(QuizQuestion question) {
    return _QuizQuestionItem(
      id: question.id,
      type: question.type,
      questionText: question.questionText,
      options: question.options,
      correctOptionIndex: question.correctOptionIndex,
      explanation: question.explanation,
    );
  }

  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
    explanationController.dispose();
  }

  QuizQuestion toQuestion() {
    return QuizQuestion(
      id: id,
      type: type,
      questionText: questionController.text.trim(),
      options: optionControllers.map((c) => c.text.trim()).toList(),
      correctOptionIndex: correctOptionIndex,
      explanation: explanationController.text.trim(),
    );
  }
}
