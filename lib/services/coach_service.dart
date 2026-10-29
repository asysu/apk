import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/study_models.dart';

class CoachAnswer {
  const CoachAnswer({
    required this.answer,
    required this.lessonTopic,
  });

  final String answer;
  final String lessonTopic;
}

class CoachService {
  CoachService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment('COACH_API_BASE_URL');
  final http.Client _client;

  Uri _endpoint(String path) {
    final baseUri = Uri.parse(_baseUrl);
    final basePath = baseUri.path.replaceFirst(RegExp(r'/$'), '');
    return baseUri.replace(path: '$basePath/$path');
  }

  void dispose() => _client.close();

  Future<CoachAnswer> ask({
    required StudySubject subject,
    required String question,
  }) async {
    if (_baseUrl.isEmpty) {
      throw StateError('AI coach endpoint is not configured.');
    }

    final uri = _endpoint('ask');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'subject': subject == StudySubject.mathematics ? 'mathematics' : 'english',
            'question': question,
          }),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'AI tutor returned ${response.statusCode}.',
        uri,
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> ||
        payload['answer'] is! String ||
        payload['lessonTopic'] is! String) {
      throw const FormatException('AI tutor response has an invalid shape.');
    }
    return CoachAnswer(
      answer: payload['answer'] as String,
      lessonTopic: payload['lessonTopic'] as String,
    );
  }

  Future<String> teach({
    required StudySubject subject,
    required String topic,
  }) async {
    if (_baseUrl.isEmpty) {
      throw StateError('AI coach endpoint is not configured.');
    }

    final uri = _endpoint('teach');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'subject': subject == StudySubject.mathematics ? 'mathematics' : 'english',
            'topic': topic,
          }),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'AI lesson returned ${response.statusCode}.',
        uri,
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> ||
        payload['title'] is! String ||
        payload['summary'] is! String ||
        payload['example'] is! String ||
        payload['practiceTip'] is! String) {
      throw const FormatException('AI lesson response has an invalid shape.');
    }
    return [
      payload['title'],
      payload['summary'],
      'Nümunə: ${payload['example']}',
      'Yadda saxla: ${payload['practiceTip']}',
    ].join('\n\n');
  }

  Future<String> explain({
    required StudyTopic topic,
    required bool wasSlow,
    required String question,
    String? selectedAnswer,
  }) async {
    if (_baseUrl.isEmpty) {
      throw StateError('AI coach endpoint is not configured.');
    }

    final uri = _endpoint('coach');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'topicId': topic.id,
            'topicTitle': topic.title,
            'lesson': topic.lesson,
            'example': topic.example,
            'reason': wasSlow ? 'slow_answer' : 'incorrect_answer',
            'question': question,
            'selectedAnswer': selectedAnswer,
          }),
        )
        .timeout(const Duration(seconds: 18));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Coach service returned ${response.statusCode}.',
        uri,
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> || payload['text'] is! String) {
      throw const FormatException('Coach response has an invalid shape.');
    }
    return payload['text'] as String;
  }

  Future<StudyQuestion> generateReviewQuestion(StudyTopic topic) async {
    if (_baseUrl.isEmpty) {
      throw StateError('AI coach endpoint is not configured.');
    }

    final uri = _endpoint('review-question');
    final response = await _client
        .post(
          uri,
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'topicTitle': topic.title,
            'lesson': topic.lesson,
            'example': topic.example,
            'subject': topic.subject == StudySubject.mathematics
                ? 'mathematics'
                : 'english',
          }),
        )
        .timeout(const Duration(seconds: 18));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Review service returned ${response.statusCode}.',
        uri,
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> ||
        payload['prompt'] is! String ||
        payload['explanation'] is! String ||
        payload['options'] is! List ||
        payload['correctIndex'] is! int) {
      throw const FormatException('Review response has an invalid shape.');
    }
    final options = (payload['options'] as List).whereType<String>().toList();
    final correctIndex = payload['correctIndex'] as int;
    if (options.length != 4 || correctIndex < 0 || correctIndex >= options.length) {
      throw const FormatException('Review response has invalid answer choices.');
    }
    return StudyQuestion(
      prompt: payload['prompt'] as String,
      options: options,
      correctIndex: correctIndex,
      explanation: payload['explanation'] as String,
    );
  }
}
