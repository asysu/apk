import 'package:flutter/material.dart';

import '../models/study_models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.progress,
    required this.topics,
    required this.onOpenTopic,
    required this.onRename,
    required this.onOpenTutor,
    super.key,
  });

  final ProgressSnapshot progress;
  final List<StudyTopic> topics;
  final ValueChanged<StudyTopic> onOpenTopic;
  final Future<void> Function(String) onRename;
  final VoidCallback onOpenTutor;

  @override
  Widget build(BuildContext context) {
    final mathTopics =
        topics.where((topic) => topic.subject == StudySubject.mathematics).toList();
    final englishTopics =
        topics.where((topic) => topic.subject == StudySubject.english).toList();
    final completion = progress.completedTopicIds.length / topics.length;
    StudyTopic? lastTopic;
    for (final topic in topics) {
      if (topic.id == progress.lastTopicId) {
        lastTopic = topic;
        break;
      }
    }
    final resumeTopic = lastTopic;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İmtahan 90+'),
        actions: [
          IconButton(
            tooltip: 'Adı dəyiş',
            onPressed: () => _editName(context),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Text(
            'Xoş gəldiniz, ${progress.studentName}!',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'İmtahanda hədəfimiz 90+ baldır!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
              title: const Text('AI müəllimdən soruş'),
              subtitle: const Text('Sual ver, izah al və istəsən qısa dərs keç'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenTutor,
            ),
          ),
          if (resumeTopic != null) ...[
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Qaldığın yerdən davam et'),
                subtitle: Text(resumeTopic.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenTopic(resumeTopic),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ümumi hazırlıq',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text('${(completion * 100).round()}%'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: completion,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${progress.completedTopicIds.length}/${topics.length} mövzu tamamlanıb'
                    '  ·  ${progress.weakTopicIds.length} təkrar mövzu',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (progress.lastTopicId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Son mövzu: ${_topicName(progress.lastTopicId!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (progress.weakTopicIds.isNotEmpty) ...[
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'Təkrar etməli olduğun mövzular',
              icon: Icons.replay_circle_filled_outlined,
            ),
            ...topics
                .where((topic) => progress.weakTopicIds.contains(topic.id))
                .map((topic) => _TopicCard(
                      topic: topic,
                      completed: progress.completedTopicIds.contains(topic.id),
                      locked: _isLocked(topic),
                      onTap: () => onOpenTopic(topic),
                    )),
          ],
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Riyaziyyat · Azərbaycan dilində',
            icon: Icons.calculate_outlined,
          ),
          ...mathTopics.map((topic) => _TopicCard(
                topic: topic,
                completed: progress.completedTopicIds.contains(topic.id),
                locked: _isLocked(topic),
                onTap: () => onOpenTopic(topic),
              )),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'İngilis dili',
            icon: Icons.translate_rounded,
          ),
          ...englishTopics.map((topic) => _TopicCard(
                topic: topic,
                completed: progress.completedTopicIds.contains(topic.id),
                locked: _isLocked(topic),
                onTap: () => onOpenTopic(topic),
              )),
        ],
      ),
    );
  }

  String _topicName(String id) {
    for (final topic in topics) {
      if (topic.id == id) return topic.title;
    }
    return 'Davam edən mövzu';
  }

  bool _isLocked(StudyTopic topic) {
    final subjectTopics =
        topics.where((item) => item.subject == topic.subject).toList();
    final index = subjectTopics.indexWhere((item) => item.id == topic.id);
    if (index <= 0) return false;
    return subjectTopics
        .take(index)
        .any((item) => !progress.completedTopicIds.contains(item.id));
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: progress.studentName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adı dəyiş'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Adınız'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ləğv et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Yadda saxla'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) await onRename(name);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.completed,
    required this.locked,
    required this.onTap,
  });

  final StudyTopic topic;
  final bool completed;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: locked ? null : onTap,
          leading: CircleAvatar(
            backgroundColor: locked
                ? const Color(0xFFE9E9ED)
                : completed
                ? const Color(0xFFE0F3E9)
                : Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              locked
                  ? Icons.lock_outline
                  : completed
                      ? Icons.check_rounded
                      : Icons.menu_book_outlined,
              color: completed ? Colors.green.shade800 : null,
            ),
          ),
          title: Text(
            topic.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            locked
                ? 'Əvvəl əvvəlki mövzunu tamamla'
                : completed
                    ? 'Tamamlanıb · Yenidən öyrən'
                    : 'Dərs və məşq',
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}
