import 'package:flutter/material.dart';

import '../data/content_bank.dart';
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
  String? _lesson;
  bool _loading = false;
  bool _localMode = false;
  String? _localModeMessage;

  @override
  void dispose() {
    _coach.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _questionController.text.trim();
    if (_loading) return;
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Əvvəlcə sualınızı yazın.')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _answer = null;
      _lesson = null;
      _localMode = false;
      _localModeMessage = null;
    });
    try {
      final result = await _coach.ask(subject: _subject, question: question);
      if (mounted) setState(() => _answer = result);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _localMode = true;
        _localModeMessage = _coach.isConfigured
            ? 'AI serverinə qoşulmaq mümkün olmadı. Hazırda yerli izahlardan '
                'istifadə olunur.'
            : 'Bu APK-də AI server ünvanı qurulmayıb. Hazırda yerli izahlardan '
                'istifadə olunur.';
        _answer = CoachAnswer(
          lessonTopic: _localTopic(question),
          answer: _localAnswer(question),
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startLesson() async {
    final topic = _answer?.lessonTopic ?? '';
    if (topic.isEmpty || _loading) return;
    setState(() => _loading = true);
    try {
      final lesson = await _coach.teach(subject: _subject, topic: topic);
      if (mounted) setState(() => _lesson = lesson);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _localMode = true;
        _localModeMessage = _coach.isConfigured
            ? 'AI serverinə qoşulmaq mümkün olmadı. Hazırda yerli dərs '
                'məzmunundan istifadə olunur.'
            : 'Bu APK-də AI server ünvanı qurulmayıb. Hazırda yerli dərs '
                'məzmunundan istifadə olunur.';
        _lesson = _localLesson(topic);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _localTopic(String question) {
    final lower = question.toLowerCase();
    if (_subject == StudySubject.mathematics) {
      if (lower.contains('kök')) return 'Kvadrat köklər';
      if (lower.contains('diskriminant') || lower.contains('tənlik')) {
        return 'Tənliklər və diskriminant';
      }
      if (lower.contains('sistem')) return 'Tənliklər sistemi';
      if (lower.contains('üçbucaq') || lower.contains('sahə')) {
        return 'Üçbucağın sahəsi';
      }
      if (lower.contains('çevrə') || lower.contains('dairə')) {
        return 'Həndəsə: bucaqlar və çevrə';
      }
      return 'Müxtəsər vurma düsturları';
    }
    if (lower.contains('tense') || lower.contains('zaman')) {
      return 'Tenses: əsas zamanlar';
    }
    if (lower.contains('passive')) return 'Passive Voice: məchul növ';
    if (lower.contains('modal') || lower.contains('should') || lower.contains('must')) {
      return 'Modal verbs';
    }
    if (lower.contains('pronoun') || lower.contains('əvəzlik')) {
      return 'Pronouns: əvəzliklər';
    }
    if (lower.contains('noun') || lower.contains('isim')) {
      return 'Nouns: cəm, sayılan və yiyəlik';
    }
    if (lower.contains('preposition') || lower.contains('sözönü')) {
      return 'Prepositions & conjunctions';
    }
    if (lower.contains('synonym') ||
        lower.contains('antonym') ||
        lower.contains('vocabulary') ||
        lower.contains('lüğət')) {
      return 'Vocabulary: sinonimlər və antonimlər';
    }
    if (lower.contains('reading') || lower.contains('mətn')) {
      return 'Reading comprehension';
    }
    if (lower.contains('listening') || lower.contains('dinləmə')) {
      return 'Listening simulation';
    }
    return 'Adjectives & adverbs: müqayisə';
  }

  String _localAnswer(String question) {
    final topic = _findTopic(_localTopic(question));
    if (topic == null) {
      return 'Sistem hazırda yerli köməkçi ilə işləyir. Sualını mövzu '
          'dərslərindəki izah və nümunələrlə yoxlaya bilərsən.\n\nSualın: $question';
    }
    return 'Sistem hazırda yerli köməkçi ilə işləyir.\n\n'
        '${topic.lesson}\n\nNümunə: ${topic.example}';
  }

  String _localLesson(String topic) {
    final localTopic = _findTopic(topic);
    if (localTopic == null) {
      return '$topic\n\nƏvvəl qaydanı müəyyən et, sonra nümunədə qaydanın '
          'hansı hissəsinin işlədiyini tap. Addımları bir-bir yaz və cavabı '
          'əvəzində yoxla.';
    }
    return '${localTopic.title}\n\n${localTopic.lesson}\n\n'
        'Nümunə: ${localTopic.example}';
  }

  StudyTopic? _findTopic(String title) {
    for (final topic in contentBank) {
      if (topic.title.toLowerCase() == title.toLowerCase()) return topic;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yapay Zeka müəllim')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Riyaziyyat və İngilis dili haqqında sualını yaz.',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yapay Zeka imtahan proqramına uyğun məşq və izah verir. '
            'Dəqiq imtahan sualını '
            'əvvəlcədən bilmək mümkün deyil; heç bir sualın çıxacağına zəmanət yoxdur.',
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
                icon: Icon(Icons.translate),
              ),
            ],
            selected: {_subject},
            onSelectionChanged: (selection) =>
                setState(() => _subject = selection.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _questionController,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Məsələn: Kvadrat tənliyi diskriminantla necə həll edim?',
              border: OutlineInputBorder(),
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
                : const Icon(Icons.send_rounded),
            label: Text(_loading ? 'Hazırlanır…' : 'Sual ver'),
          ),
          if (_answer != null) ...[
            const SizedBox(height: 16),
            _TutorCard(
              title: 'Yapay Zeka müəllimin cavabı',
              body: _answer!.answer,
            ),
            const SizedBox(height: 8),
            if (_answer!.lessonTopic.isNotEmpty)
              _TutorCard(
                title: 'Bu mövzuda sənə dərs keçim?',
                body: 'Mövzu: ${_answer!.lessonTopic}',
                footer: Row(
                  children: [
                    FilledButton(
                      onPressed: _loading ? null : _startLesson,
                      child: const Text('Bəli, dərs keç'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _answer = null),
                      child: const Text('İndi yox'),
                    ),
                  ],
                ),
              )
            else
              TextButton(
                onPressed: () => setState(() => _answer = null),
                child: const Text('Yeni sual ver'),
              ),
          ],
          if (_lesson != null) ...[
            const SizedBox(height: 8),
            _TutorCard(title: 'Qısa dərs', body: _lesson!),
          ],
          if (_localMode) ...[
            const SizedBox(height: 8),
            _TutorCard(
              title: 'Yerli köməkçi',
              body: _localModeMessage ??
                  'Hazırda yerli izahlardan istifadə olunur.',
            ),
          ],
        ],
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({
    required this.title,
    required this.body,
    this.footer,
  });

  final String title;
  final String body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(body),
              if (footer != null) ...[
                const SizedBox(height: 12),
                footer!,
              ],
            ],
          ),
        ),
      );
}
