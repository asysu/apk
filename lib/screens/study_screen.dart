import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_models.dart';
import '../services/coach_service.dart';

typedef AttemptCallback = void Function({
  required bool correct,
  bool completed,
  bool weak,
});

class StudyScreen extends StatefulWidget {
  const StudyScreen({
    required this.topic,
    required this.onAttempt,
    super.key,
  });

  final StudyTopic topic;
  final AttemptCallback onAttempt;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  static const _questionLimit = Duration(seconds: 60);
  final CoachService _coach = CoachService();
  final TextEditingController _openAnswerController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = _questionLimit.inSeconds;
  int _normalQuestionIndex = 0;
  int _microIndex = 0;
  int _consecutiveCorrect = 0;
  bool _remediation = false;
  bool _finished = false;
  bool _loadingCoach = false;
  bool _localAssistant = false;
  String? _coachMessage;
  String? _feedback;
  int? _selectedIndex;

  StudyQuestion get _question => widget.topic.questions[
        _remediation ? _microIndex + 1 : _normalQuestionIndex
      ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _coach.dispose();
    _openAnswerController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _questionLimit.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _remediation || _finished) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _enterRemediation(wasSlow: true);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _enterRemediation({
    required bool wasSlow,
    bool recordAttempt = true,
    String? selectedAnswer,
  }) async {
    if (_remediation || _finished) return;
    _timer?.cancel();
    if (recordAttempt) widget.onAttempt(correct: false, weak: true);
    setState(() {
      _remediation = true;
      _microIndex = 0;
      _consecutiveCorrect = 0;
      _loadingCoach = true;
      _coachMessage = _localExplanation(wasSlow);
      _feedback = null;
      _selectedIndex = null;
    });
    try {
      final explanation = await _coach.explain(
        topic: widget.topic,
        wasSlow: wasSlow,
        question: _question.prompt,
        selectedAnswer: selectedAnswer,
      );
      if (mounted) setState(() => _coachMessage = explanation);
    } catch (_) {
      if (!mounted) return;
      setState(() => _localAssistant = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sistem hazırda yerli köməkçi ilə işləyir.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingCoach = false);
    }
  }

  String _localExplanation(bool wasSlow) {
    final prefix = wasSlow ? 'Vaxt apardığını gördüm. ' : 'Hatanı tapdım! ';
    return '$prefix${widget.topic.lesson}\n\n'
        'Nümunə: ${widget.topic.example}';
  }

  void _answer(int index) {
    if (_selectedIndex != null || _finished || _loadingCoach) return;
    final correct = index == _question.correctIndex;
    setState(() {
      _selectedIndex = index;
      _feedback = null;
    });
    widget.onAttempt(correct: correct, weak: !correct);

    if (!_remediation) {
      if (correct) {
        if (!_advanceReadingQuestion()) _completeTopic();
      } else {
        _enterRemediation(
          wasSlow: false,
          recordAttempt: false,
          selectedAnswer: _question.options[index],
        );
      }
      return;
    }

    if (!correct) {
      setState(() {
        _consecutiveCorrect = 0;
        _microIndex = 0;
        _selectedIndex = null;
        _feedback = _question.explanation;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hələ mövzunu buraxmırıq — gəlin yenidən cəhd edək.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _consecutiveCorrect++;
    if (_consecutiveCorrect == 3) {
      _completeTopic();
    } else {
      setState(() {
        _microIndex++;
        _selectedIndex = null;
      });
    }
  }

  void _submitOpenAnswer() {
    if (_selectedIndex != null || _finished || _loadingCoach || _remediation) {
      return;
    }
    final normalizedAnswer = _openAnswerController.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toSet();
    final correct = _question.openEndedKeywords.every(normalizedAnswer.contains);
    final answer = _openAnswerController.text.trim();
    widget.onAttempt(correct: correct, weak: !correct);

    if (!correct) {
      _enterRemediation(
        wasSlow: false,
        recordAttempt: false,
        selectedAnswer: answer,
      );
    } else if (!_advanceReadingQuestion()) {
      _completeTopic();
    }
  }

  bool _advanceReadingQuestion() {
    if (widget.topic.id != 'english-reading' ||
        _normalQuestionIndex >= widget.topic.questions.length - 1) {
      return false;
    }
    setState(() {
      _normalQuestionIndex++;
      _selectedIndex = null;
      _feedback = null;
    });
    _openAnswerController.clear();
    _startTimer();
    return true;
  }

  void _completeTopic() {
    _timer?.cancel();
    setState(() => _finished = true);
    widget.onAttempt(correct: false, completed: true);
  }

  @override
  Widget build(BuildContext context) {
    final subjectLabel = widget.topic.subject == StudySubject.mathematics
        ? 'Riyaziyyat'
        : 'İngilis dili';

    return Scaffold(
      appBar: AppBar(title: Text(subjectLabel)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(
              widget.topic.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _InfoCard(
              title: 'Qısa izah',
              body: '${widget.topic.lesson}\n\nNümunə: ${widget.topic.example}',
              icon: Icons.lightbulb_outline,
            ),
            if (widget.topic.id == 'english-reading' ||
                widget.topic.id == 'english-listening')
              _InfoCard(
                title: widget.topic.id == 'english-reading'
                    ? 'Mətn'
                    : 'Dinləmə simulyasiyası · mətni oxu və səsləndirildiyini təsəvvür et',
                body: widget.topic.example,
                icon: widget.topic.id == 'english-reading'
                    ? Icons.menu_book_outlined
                    : Icons.headphones_outlined,
              ),
            if (_remediation && _coachMessage != null)
              _InfoCard(
                title: _localAssistant ? 'Yerli köməkçi' : 'Müəllim izahı',
                body: _coachMessage!,
                icon: _loadingCoach ? Icons.sync : Icons.auto_awesome_outlined,
              ),
            const SizedBox(height: 10),
            if (_finished)
              _CompletionCard(topic: widget.topic)
            else ...[
              if (!_remediation)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Cavab üçün qalan vaxt: $_remainingSeconds san.',
                    style: TextStyle(
                      color: _remainingSeconds <= 10
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (_remediation)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Mikro sual ${_consecutiveCorrect + 1}/3 · ardıcıl düzgün cavablar: $_consecutiveCorrect',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                _remediation ? 'Mikro məşq' : 'Yoxlama sualı',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _question.prompt,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (_question.isOpenEnded) ...[
                TextField(
                  controller: _openAnswerController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Cavabınızı ingilis dilində yazın',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submitOpenAnswer,
                  child: const Text('Cavabı yoxla'),
                ),
              ] else
                ...List.generate(
                  _question.options.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AnswerButton(
                      label: _question.options[index],
                      index: index,
                      selectedIndex: _selectedIndex,
                      correctIndex: _question.correctIndex,
                      onTap: () => _answer(index),
                    ),
                  ),
                ),
              if (_selectedIndex != null)
                _InfoCard(
                  title: indexToLetter(_question.correctIndex) == indexToLetter(_selectedIndex!)
                      ? 'Düzgün cavab'
                      : 'İzah',
                  body: _question.explanation,
                  icon: Icons.check_circle_outline,
                ),
            if (_feedback != null)
              _InfoCard(
                title: 'Yenidən düşünək',
                body: _feedback!,
                icon: Icons.lightbulb_outline,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String indexToLetter(int index) => String.fromCharCode(65 + index);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(body),
            ],
          ),
        ),
      );
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.onTap,
  });

  final String label;
  final int index;
  final int? selectedIndex;
  final int correctIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == index;
    final reveal = selectedIndex != null && (selected || index == correctIndex);
    final color = reveal
        ? (index == correctIndex ? const Color(0xFFE2F4E9) : const Color(0xFFFCE8E6))
        : Colors.white;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: selectedIndex == null ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: reveal
                  ? (index == correctIndex ? Colors.green : Colors.red)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                child: Text(String.fromCharCode(65 + index)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.topic});

  final StudyTopic topic;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFFE2F4E9),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 44, color: Colors.green),
              const SizedBox(height: 10),
              Text(
                'Əla! Mövzunu tamamladın.',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'İndi növbəti mövzuya keçə bilərsən. İstənilən vaxt bu mövzunu yenidən öyrən.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Mövzulara qayıt'),
              ),
            ],
          ),
        ),
      );
}
