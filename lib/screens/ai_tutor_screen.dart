import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../services/coach_service.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final CoachService _coach = CoachService();
  final TextEditingController _questionController = TextEditingController();
  StudySubject _subject = StudySubject.mathematics;
  CoachAnswer? _answer;
  CoachLesson? _lesson;
  String? _errorMessage;
  bool _loading = false;
  bool _keyLoading = true;
  bool _hasApiKey = false;
  bool _showPracticeAnswer = false;
  Future<void> Function()? _retryAction;

  static const _mathExamples = [
    'x² − 5x + 6 = 0 tənliyini addım-addım həll et.',
    '√72 ifadəsini sadələşdir və niyə belə olduğunu izah et.',
    'Üçbucağın sahəsi 24 sm², əsası 8 sm-dir. Hündürlüyü tap.',
  ];

  static const _englishExamples = [
    'I have went to school. Cümləni düzəlt və qaydanı izah et.',
    'Present Perfect və Past Simple fərqini iki nümunə ilə göstər.',
    '“They clean the room” cümləsini Passive Voice-a çevir.',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadApiKey());
  }

  @override
  void dispose() {
    _coach.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    try {
      final hasApiKey = await _coach.hasApiKey;
      if (mounted) setState(() => _hasApiKey = hasApiKey);
    } catch (error) {
      debugPrint('Gemini API key status could not be read: $error');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Açarı cihazın təhlükəsiz yaddaşından oxumaq olmadı. Tətbiqi yenidən açın.';
        });
      }
    } finally {
      if (mounted) setState(() => _keyLoading = false);
    }
  }

  Future<bool> _ensureApiKey() async {
    if (_hasApiKey) return true;
    await _configureApiKey();
    return _hasApiKey;
  }

  Future<void> _configureApiKey() async {
    final controller = TextEditingController();
    var showKey = false;
    var savingApiKey = false;
    String? validationError;
    try {
      final apiKey = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, updateDialog) => PopScope(
            canPop: !savingApiKey,
            child: AlertDialog(
              title: const Text('Gemini API açarını qoş'),
              content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google AI Studio-dan şəxsi API açarını yaradıb bura daxil et. '
                    'Açar şifrəli şəkildə bu cihazda saxlanır; tətbiqin serverinə göndərilmir. '
                    '“Yoxla və saxla” düyməsi Google Gemini-yə real test sorğusu göndərəcək. '
                    'Yoxlama bitənədək bu pəncərə açıq qalacaq; uğurlu olmasa açar saxlanmayacaq.',
                  ),
                  const SizedBox(height: 8),
                  const SelectableText(
                    'https://aistudio.google.com/app/apikey',
                    style: TextStyle(color: Colors.blue),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    readOnly: savingApiKey,
                    obscureText: !showKey,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (_) =>
                        updateDialog(() => validationError = null),
                    decoration: InputDecoration(
                      labelText: 'Gemini API açarı',
                      hintText: 'Açarı bura daxil et',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: showKey ? 'Açarı gizlət' : 'Açarı göstər',
                        onPressed: () =>
                            updateDialog(() => showKey = !showKey),
                        icon: Icon(
                          showKey ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  if (savingApiKey) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Gemini açarı yoxlanılır, bir az gözləyin…'),
                  ],
                  if (validationError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      validationError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Açarı başqaları ilə paylaşma. Google Gemini istifadəsi '
                    'Google hesabının limit və şərtlərinə tabedir.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
              actions: [
                TextButton(
                  onPressed: savingApiKey
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Bağla'),
                ),
                FilledButton(
                  onPressed: savingApiKey
                      ? null
                      : () async {
                          final value = controller.text.trim();
                          if (value.isEmpty) {
                            updateDialog(
                              () => validationError =
                                  'Əvvəlcə API açarını daxil edin.',
                            );
                            return;
                          }
                          updateDialog(() {
                            savingApiKey = true;
                            validationError = null;
                          });
                          try {
                            await _coach.saveApiKey(value);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, value);
                            }
                          } on CoachServiceException catch (error) {
                            updateDialog(
                              () => validationError = error.message,
                            );
                          } catch (error) {
                            debugPrint(
                              'Gemini API key validation failed: $error',
                            );
                            updateDialog(
                              () => validationError =
                                  'API açarını yoxlamaq alınmadı. İnterneti yoxlayıb yenidən sınayın.',
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              updateDialog(() => savingApiKey = false);
                            }
                          }
                        },
                  child:
                      Text(savingApiKey ? 'Yoxlanılır…' : 'Yoxla və saxla'),
                ),
              ],
            ),
          ),
        ),
      );
      if (apiKey == null || !mounted) return;
      setState(() {
        _hasApiKey = true;
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini açarı bu cihazda təhlükəsiz saxlandı.'),
        ),
      );
    } catch (error) {
      debugPrint('Gemini API key could not be saved: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Açarı təhlükəsiz yaddaşda saxlamaq mümkün olmadı.';
        });
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _removeApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Açarı silmək istəyirsən?'),
        content: const Text(
          'Saxlanmış Gemini API açarı bu cihazdan silinəcək.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ləğv et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _coach.removeApiKey();
      if (mounted) {
        setState(() {
          _hasApiKey = false;
          _answer = null;
          _lesson = null;
        });
      }
    } catch (error) {
      debugPrint('Gemini API key could not be removed: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Açarı cihazdan silmək mümkün olmadı.';
        });
      }
    }
  }

  Future<void> _ask() async {
    final question = _questionController.text.trim();
    if (_loading) return;
    if (question.isEmpty) {
      setState(() => _errorMessage = 'Əvvəlcə sualını yaz.');
      return;
    }
    if (!await _ensureApiKey() || !mounted) return;

    setState(() {
      _loading = true;
      _answer = null;
      _lesson = null;
      _errorMessage = null;
      _showPracticeAnswer = false;
      _retryAction = _ask;
    });
    try {
      final result = await _coach.ask(subject: _subject, question: question);
      if (mounted) setState(() => _answer = result);
    } on CoachServiceException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      debugPrint('Gemini tutor question failed: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Cavab alınmadı. İnterneti və Gemini API açarını yoxla.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startLesson() async {
    final topic = _answer?.lessonTopic.trim() ?? '';
    if (topic.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _lesson = null;
      _showPracticeAnswer = false;
      _retryAction = _startLesson;
    });
    try {
      final lesson = await _coach.teach(subject: _subject, topic: topic);
      if (mounted) setState(() => _lesson = lesson);
    } on CoachServiceException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      debugPrint('Gemini lesson generation failed: $error');
      if (mounted) {
        setState(
          () => _errorMessage = 'Dərs hazırlamaq mümkün olmadı. Yenidən sınayın.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectSubject(StudySubject subject) {
    setState(() {
      _subject = subject;
      _answer = null;
      _lesson = null;
      _errorMessage = null;
      _showPracticeAnswer = false;
    });
  }

  void _useExample(String example) {
    setState(() {
      _questionController
        ..text = example
        ..selection = TextSelection.collapsed(offset: example.length);
      _answer = null;
      _lesson = null;
      _errorMessage = null;
      _showPracticeAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final examples = _subject == StudySubject.mathematics
        ? _mathExamples
        : _englishExamples;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini müəllim'),
        actions: [
          IconButton(
            tooltip: 'API açarını idarə et',
            onPressed: _keyLoading ? null : _configureApiKey,
            icon: const Icon(Icons.key_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Text(
            'Sualını yaz, addım-addım öyrən.',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Riyaziyyat və İngilis dili üçün cavab, həll nümunələri və mini-dərs.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          _ApiKeyCard(
            loading: _keyLoading,
            configured: _hasApiKey,
            onConfigure: _configureApiKey,
            onRemove: _removeApiKey,
          ),
          const SizedBox(height: 16),
          SegmentedButton<StudySubject>(
            segments: const [
              ButtonSegment(
                value: StudySubject.mathematics,
                label: Text('Riyaziyyat'),
                icon: Icon(Icons.calculate_outlined),
              ),
              ButtonSegment(
                value: StudySubject.english,
                label: Text('İngilis dili'),
                icon: Icon(Icons.translate_rounded),
              ),
            ],
            selected: {_subject},
            onSelectionChanged: (selection) =>
                _selectSubject(selection.first),
          ),
          const SizedBox(height: 14),
          Text(
            'Nümunələrə toxun və ya öz sualını yaz',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in examples)
                ActionChip(
                  label: Text(example),
                  onPressed: _loading ? null : () => _useExample(example),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _questionController,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Sualın',
              hintText: _subject == StudySubject.mathematics
                  ? 'Məsələn: 2x + 5 = 13 tənliyini addım-addım həll et.'
                  : 'Məsələn: “She go to school” cümləsində səhv nədir?',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _loading ? null : _ask,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Gemini hazırlayır…' : 'Suala cavab al'),
          ),
          if (_answer != null) ...[
            const SizedBox(height: 18),
            _TutorCard(
              title: 'Sualına cavab',
              body: _answer!.answer,
              icon: Icons.lightbulb_outline,
            ),
            if (_answer!.lessonTopic.isNotEmpty) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: _loading ? null : _startLesson,
                icon: const Icon(Icons.menu_book_outlined),
                label: Text('“${_answer!.lessonTopic}” mövzusunu öyrən'),
              ),
            ],
          ],
          if (_lesson != null) ...[
            const SizedBox(height: 18),
            _TutorCard(
              title: _lesson!.title,
              body: _lesson!.explanation,
              icon: Icons.menu_book_outlined,
            ),
            for (var index = 0; index < _lesson!.examples.length; index++) ...[
              const SizedBox(height: 10),
              _TutorCard(
                title: 'Nümunə ${index + 1}',
                body: _lesson!.examples[index],
                icon: Icons.calculate_outlined,
              ),
            ],
            const SizedBox(height: 10),
            _TutorCard(
              title: 'Diqqət: yayğın səhv',
              body: _lesson!.commonMistake,
              icon: Icons.warning_amber_outlined,
            ),
            const SizedBox(height: 10),
            _TutorCard(
              title: 'Özünü yoxla',
              body: _lesson!.practiceQuestion,
              icon: Icons.quiz_outlined,
              footer: OutlinedButton(
                onPressed: () => setState(
                  () => _showPracticeAnswer = !_showPracticeAnswer,
                ),
                child: Text(
                  _showPracticeAnswer ? 'Cavabı gizlət' : 'Cavabı göstər',
                ),
              ),
            ),
            if (_showPracticeAnswer) ...[
              const SizedBox(height: 8),
              _TutorCard(
                title: 'Məşqin cavabı',
                body: _lesson!.practiceAnswer,
                icon: Icons.check_circle_outline,
              ),
            ],
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _TutorCard(
              title: 'Cavab alınmadı',
              body: _errorMessage!,
              icon: Icons.error_outline,
              footer: TextButton.icon(
                onPressed: _loading ? null : () => (_retryAction ?? _ask)(),
                icon: const Icon(Icons.refresh),
                label: const Text('Yenidən yoxla'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Sorğu birbaşa Google Gemini-yə göndərilir. Şəxsi məlumat və parol yazma.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ApiKeyCard extends StatelessWidget {
  const _ApiKeyCard({
    required this.loading,
    required this.configured,
    required this.onConfigure,
    required this.onRemove,
  });

  final bool loading;
  final bool configured;
  final VoidCallback onConfigure;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              configured ? Icons.verified_user_outlined : Icons.key_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loading
                        ? 'Açar yoxlanılır…'
                        : configured
                            ? 'Gemini açarı cihazda saxlanıb'
                            : 'Gemini açarı lazımdır',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    'Açar şifrəli cihaz yaddaşındadır',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (!configured)
              FilledButton.tonal(
                onPressed: onConfigure,
                child: const Text('Açarı daxil et'),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Açar parametrləri',
                onSelected: (value) =>
                    value == 'remove' ? onRemove() : onConfigure(),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'configure',
                    child: Text('Açarı dəyiş'),
                  ),
                  if (configured)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Açarı sil'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({
    required this.title,
    required this.body,
    required this.icon,
    this.footer,
  });

  final String title;
  final String body;
  final IconData icon;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(body),
              if (footer != null) ...[
                const SizedBox(height: 10),
                footer!,
              ],
            ],
          ),
        ),
      );
}
