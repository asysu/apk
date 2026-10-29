import 'dart:math';

import 'package:flutter/material.dart';

import 'data/content_bank.dart';
import 'models/study_models.dart';
import 'screens/home_screen.dart';
import 'screens/ai_tutor_screen.dart';
import 'screens/review_gate_screen.dart';
import 'screens/study_screen.dart';
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
  ProgressSnapshot? _progress;

  @override
  void initState() {
    super.initState();
    _loadProgress();
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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4169E1),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'İmtahan 90+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      scaffoldMessengerKey: _messengerKey,
      home: _progress == null
          ? const _LoadingScreen()
          : _progress!.studentName.isEmpty
              ? _WelcomeScreen(
                  onSave: (name) async {
                    setState(() => _progress!.studentName = name.trim());
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
      if (passed == true && mounted) _pushStudy(context, topic);
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

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _WelcomeScreen extends StatefulWidget {
  const _WelcomeScreen({required this.onSave});

  final Future<void> Function(String) onSave;

  @override
  State<_WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<_WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();

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
                          fontWeight: FontWeight.w800,
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
                    decoration: const InputDecoration(
                      labelText: 'Adınız',
                      hintText: 'Məsələn, Aysel',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _continue(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _continue,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
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
    if (name.isEmpty) return;
    await widget.onSave(name);
  }
}
