import 'dart:math';

import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../services/coach_service.dart';
import 'study_screen.dart';

class ReviewGateScreen extends StatefulWidget {
  const ReviewGateScreen({
    required this.topic,
    required this.onAttempt,
    super.key,
  });

  final StudyTopic topic;
  final AttemptCallback onAttempt;

  @override
  State<ReviewGateScreen> createState() => _ReviewGateScreenState();
}

class _ReviewGateScreenState extends State<ReviewGateScreen> {
  final CoachService _coach = CoachService();
  late StudyQuestion _activeQuestion;
  int? _selectedIndex;
  bool _localAssistant = false;
  String? _assistantMessage;

  @override
  void initState() {
    super.initState();
    final pool = widget.topic.questions;
    _activeQuestion = pool[1 + Random().nextInt(pool.length - 1)];
    _loadGeneratedQuestion();
  }

  @override
  void dispose() {
    _coach.dispose();
    super.dispose();
  }

  Future<void> _loadGeneratedQuestion() async {
    try {
      final question = await _coach.generateReviewQuestion(widget.topic);
      if (mounted && _selectedIndex == null) {
        setState(() => _activeQuestion = question);
      }
    } on CoachServiceException catch (error) {
      if (mounted) {
        setState(() {
          _localAssistant = true;
          _assistantMessage =
              'Gemini sualı yarada bilmədi: ${error.message} Yerli sual göstərilir.';
        });
      }
    } catch (error) {
      debugPrint('Gemini review question generation failed: $error');
      if (mounted) {
        setState(() {
          _localAssistant = true;
          _assistantMessage =
              'Gemini-yə qoşulmaq olmadı. Yerli sual göstərilir.';
        });
      }
    }
  }

  void _answer(int index) {
    if (_selectedIndex != null) return;
    final correct = index == _activeQuestion.correctIndex;
    widget.onAttempt(correct: correct, weak: !correct);
    setState(() => _selectedIndex = index);
    if (correct) {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Təsadüfi təkrar')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Yeni mövzuya keçməzdən əvvəl gəl keçənləri təkrar edək',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('Təkrar mövzusu: ${widget.topic.title}'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(widget.topic.lesson),
            ),
          ),
          const SizedBox(height: 12),
          Text(_activeQuestion.prompt, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...List.generate(
            _activeQuestion.options.length,
            (index) {
              final isCorrect = index == _activeQuestion.correctIndex;
              final selected = index == _selectedIndex;
              final showCorrect = _selectedIndex != null && isCorrect;
              return Card(
                color: showCorrect
                    ? const Color(0xFFE2F4E9)
                    : selected
                        ? const Color(0xFFFCE8E6)
                        : null,
                child: ListTile(
                  enabled: _selectedIndex == null,
                  onTap: () => _answer(index),
                  title: Text(_activeQuestion.options[index]),
                  leading: CircleAvatar(child: Text(String.fromCharCode(65 + index))),
                ),
              );
            },
          ),
          if (_selectedIndex != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _selectedIndex == _activeQuestion.correctIndex
                      ? 'Düzgün cavab! Növbəti mövzu açılır.'
                      : 'Hələ hazır deyilik. İzahı oxu və yenidən cəhd et: ${_activeQuestion.explanation}',
                ),
              ),
            ),
            if (_selectedIndex != _activeQuestion.correctIndex)
              FilledButton.tonal(
                onPressed: () => setState(() => _selectedIndex = null),
                child: const Text('Yenidən cəhd et'),
              ),
          ],
          if (_localAssistant)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_assistantMessage ?? 'Yerli sual bankından istifadə olunur.'),
              ),
            ),
        ],
      ),
    );
  }
}
