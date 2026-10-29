import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'data/content_bank.dart';
import 'models/study_models.dart';
import 'screens/ai_tutor_screen.dart';
import 'screens/home_screen.dart';
import 'screens/legal_document_screen.dart';
import 'screens/review_gate_screen.dart';
import 'screens/study_screen.dart';
import 'services/internet_connection_monitor.dart';
import 'services/progress_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExamPrepApp());
}

class ExamPrepApp extends StatefulWidget {
  const ExamPrepApp({super.key});

  @override
  State<ExamPrepApp> createState() => _ExamPrepAppState();
}

class _ExamPrepAppState extends State<ExamPrepApp> {
  final ProgressStore _store = ProgressStore();
  final InternetConnectionMonitor _internet = InternetConnectionMonitor();
  ProgressSnapshot? _progress;

  @override
  void initState() {
    super.initState();
    unawaited(_internet.start());
    _loadProgress();
  }

  @override
  void dispose() {
    _internet.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final progress = await _store.load();
    if (mounted) setState(() => _progress = progress);
  }

  void _recordAttempt({
    required String topicId,
    required bool correct,
    bool completed = false,
    bool weak = false,
  }) {
    final progress = _progress!;
    progress.lastTopicId = topicId;
    if (completed) {
      progress.completedTopicIds.add(topicId);
      progress.weakTopicIds.remove(topicId);
    } else {
      progress.totalAnswered++;
      if (correct) progress.totalCorrect++;
      if (weak) progress.weakTopicIds.add(topicId);
    }
    if (mounted) setState(() {});
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İmtahan 90+',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _progress?.darkModeEnabled == true
          ? ThemeMode.dark
          : ThemeMode.light,
      scaffoldMessengerKey: _messengerKey,
      builder: (context, child) => ValueListenableBuilder<bool?>(
        valueListenable: _internet.isOnline,
        builder: (context, isOnline, _) => Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            if (isOnline == false)
              Positioned.fill(
                child: _OfflineScreen(onRetry: _internet.check),
              ),
          ],
        ),
      ),
      home: _progress == null
          ? const _LoadingScreen()
          : _progress!.studentName.isEmpty ||
                  !_progress!.legalConsentAccepted
              ? _WelcomeScreen(
                  initialName: _progress!.studentName,
                  onSave: (name) async {
                    setState(() {
                      _progress!
                        ..studentName = name.trim()
                        ..legalConsentAccepted = true;
                    });
                    await _saveProgress();
                  },
                )
              : HomeScreen(
                  progress: _progress!,
                  topics: contentBank,
                  onRename: (name) async {
                    setState(() => _progress!.studentName = name.trim());
                    await _saveProgress();
                  },
                  onToggleTheme: _toggleTheme,
                  onOpenTutor: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AiTutorScreen(),
                      ),
                    );
                  },
                  onOpenTopic: (topic) => _openTopic(context, topic),
                ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4169E1),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF6F7FB)
          : const Color(0xFF111318),
    );
  }

  void _toggleTheme() {
    setState(() => _progress!.darkModeEnabled = !_progress!.darkModeEnabled);
    unawaited(_saveProgress());
  }

  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void _openTopic(BuildContext context, StudyTopic topic) {
    final reviewTopics = contentBank
        .where(
          (item) =>
              _progress!.weakTopicIds.contains(item.id) && item.id != topic.id,
        )
        .toList();
    if (reviewTopics.isEmpty) {
      _pushStudy(context, topic);
      return;
    }

    final previousTopic = reviewTopics[Random().nextInt(reviewTopics.length)];
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReviewGateScreen(
          topic: previousTopic,
          onAttempt: ({
            required bool correct,
            bool completed = false,
            bool weak = false,
          }) =>
              _recordAttempt(
            topicId: previousTopic.id,
            correct: correct,
            completed: completed,
            weak: weak,
          ),
        ),
      ),
    )
        .then((passed) {
      if (passed == true && mounted && context.mounted) {
        _pushStudy(context, topic);
      }
    });
  }

  void _pushStudy(BuildContext context, StudyTopic topic) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyScreen(
          topic: topic,
          onAttempt: ({
            required bool correct,
            bool completed = false,
            bool weak = false,
          }) =>
              _recordAttempt(
            topicId: topic.id,
            correct: correct,
            completed: completed,
            weak: weak,
          ),
        ),
      ),
    );
  }

  Future<void> _saveProgress() async {
    try {
      await _store.save(_progress!);
    } catch (error) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('İrəliləyişi cihazda saxlamaq mümkün olmadı.'),
        ),
      );
      debugPrint('Progress save failed: $error');
    }
  }
}

class _OfflineScreen extends StatelessWidget {
  const _OfflineScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: max(0.0, constraints.maxHeight - 40),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'İnternet bağlantısı yoxdur',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Wi-Fi və ya mobil interneti yoxlayın. Bağlantı '
                        'bərpa olunanda tətbiq avtomatik açılacaq.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Yenidən yoxla'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _WelcomeScreen extends StatefulWidget {
  const _WelcomeScreen({
    required this.initialName,
    required this.onSave,
  });

  final String initialName;
  final Future<void> Function(String) onSave;

  @override
  State<_WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<_WelcomeScreen> {
  late final TextEditingController _nameController;
  bool _acceptedLegalDocuments = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.school_rounded, size: 72, color: Color(0xFF4169E1)),
                  const SizedBox(height: 24),
                  Text(
                    'İmtahana inamla hazırlaş',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '9-cu sinif buraxılış imtahanı · Riyaziyyat və İngilis dili',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Adınız',
                      hintText: 'Məsələn, Aysel',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _continue(),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _acceptedLegalDocuments,
                    onChanged: (value) => setState(
                      () => _acceptedLegalDocuments = value ?? false,
                    ),
                    title: const Text(
                      'Məxfilik siyasətini və istifadə şərtlərini oxudum, qəbul edirəm.',
                    ),
                    subtitle: const Text(
                      '18 yaşdan kiçiksinizsə, valideyninizlə birlikdə oxuyun.',
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => showLegalDocuments(context),
                        child: const Text(
                          'Məxfilik siyasəti · İstifadə şərtləri',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _acceptedLegalDocuments &&
                            _nameController.text.trim().isNotEmpty
                        ? _continue
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Text('Başla'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || !_acceptedLegalDocuments) return;
    await widget.onSave(name);
  }

}
