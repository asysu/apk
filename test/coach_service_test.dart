import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:imtahan_hazirligi/models/study_models.dart';
import 'package:imtahan_hazirligi/services/coach_service.dart';

class _MemoryApiKeyStore implements GeminiApiKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}

http.Response _geminiResponse(String text, {int statusCode = 200}) {
  return http.Response(
    jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    }),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sends the exact question and key directly to Gemini', () async {
    final keyStore = _MemoryApiKeyStore()..value = 'test-gemini-key';
    http.Request? sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return _geminiResponse(
        '{"answer":"2x + 5 = 13; 2x = 8; x = 4.","lessonTopic":"Tənliklər"}',
      );
    });
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    final result = await service.ask(
      subject: StudySubject.mathematics,
      question: '2x + 5 = 13 tənliyini addım-addım həll et.',
    );

    expect(result.answer, contains('x = 4'));
    expect(result.lessonTopic, 'Tənliklər');
    expect(sentRequest!.url.host, 'generativelanguage.googleapis.com');
    expect(sentRequest!.url.query, isEmpty);
    expect(sentRequest!.headers['x-goog-api-key'], 'test-gemini-key');
    expect(
      sentRequest!.body,
      contains('2x + 5 = 13 tənliyini addım-addım həll et.'),
    );
    expect(sentRequest!.body, isNot(contains('test-gemini-key')));
  });

  test('does not call Gemini when no device key is configured', () async {
    final keyStore = _MemoryApiKeyStore();
    var requestCount = 0;
    final client = MockClient((_) async {
      requestCount++;
      return _geminiResponse('{}');
    });
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    await expectLater(
      service.ask(
        subject: StudySubject.english,
        question: 'Correct this sentence.',
      ),
      throwsA(
        isA<CoachServiceException>().having(
          (error) => error.message,
          'message',
          contains('API açarı'),
        ),
      ),
    );
    expect(requestCount, 0);
  });

  test('validates the key with Gemini before storing it', () async {
    final keyStore = _MemoryApiKeyStore();
    http.Request? sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return _geminiResponse('OK');
    });
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    await service.saveApiKey('test-gemini-key');

    expect(keyStore.value, 'test-gemini-key');
    expect(sentRequest!.url.host, 'generativelanguage.googleapis.com');
    expect(sentRequest!.headers['x-goog-api-key'], 'test-gemini-key');
    expect(sentRequest!.body, contains('API açarını yoxlamaq'));
  });

  test('does not store an API key rejected by Gemini', () async {
    final keyStore = _MemoryApiKeyStore();
    final client = MockClient((_) async => http.Response('{}', 403));
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    await expectLater(
      service.saveApiKey('rejected-key'),
      throwsA(
        isA<CoachServiceException>().having(
          (error) => error.message,
          'message',
          contains('API açarı yanlışdır'),
        ),
      ),
    );
    expect(keyStore.value, isNull);
  });

  test('does not store a key when Gemini does not generate a test response', () async {
    final keyStore = _MemoryApiKeyStore();
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'candidates': []}),
        200,
        headers: const {'content-type': 'application/json'},
      ),
    );
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    await expectLater(
      service.saveApiKey('no-response-key'),
      throwsA(
        isA<CoachServiceException>().having(
          (error) => error.message,
          'message',
          contains('cavab yarada bilmədi'),
        ),
      ),
    );
    expect(keyStore.value, isNull);
  });

  test('reports socket failures as an internet connection problem', () async {
    final keyStore = _MemoryApiKeyStore()..value = 'test-gemini-key';
    final client = MockClient(
      (_) async => throw const SocketException('No route to host'),
    );
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    await expectLater(
      service.ask(
        subject: StudySubject.english,
        question: 'Correct this sentence.',
      ),
      throwsA(
        isA<CoachServiceException>().having(
          (error) => error.message,
          'message',
          contains('internet bağlantısı'),
        ),
      ),
    );
  });

  test('recognizes DNS errors wrapped in an HTTP client exception', () async {
    final keyStore = _MemoryApiKeyStore()..value = 'test-gemini-key';
    final client = MockClient(
      (_) async => throw http.ClientException(
        'Failed to connect: SocketException: Failed host lookup',
      ),
    );
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    await expectLater(
      service.ask(
        subject: StudySubject.english,
        question: 'Correct this sentence.',
      ),
      throwsA(
        isA<CoachServiceException>().having(
          (error) => error.message,
          'message',
          contains('internet bağlantısı'),
        ),
      ),
    );
  });

  test('returns two worked examples and a self-check lesson', () async {
    final keyStore = _MemoryApiKeyStore()..value = 'test-gemini-key';
    final client = MockClient((_) async {
      return _geminiResponse(
        jsonEncode({
          'title': 'Kvadrat tənlik',
          'explanation': 'Diskriminantı hesabla.',
          'examples': ['D = 1; x = 2 və 3.', 'D = 0; x = -2.'],
          'commonMistake': '2a-ya bölməyi unutma.',
          'practiceQuestion': 'x² - 4 = 0 tənliyini həll et.',
          'practiceAnswer': 'x = -2 və ya x = 2.',
        }),
      );
    });
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    final lesson = await service.teach(
      subject: StudySubject.mathematics,
      topic: 'Kvadrat tənliklər',
    );

    expect(lesson.examples, hasLength(2));
    expect(lesson.commonMistake, contains('2a'));
    expect(lesson.practiceQuestion, contains('x²'));
    expect(lesson.practiceAnswer, contains('x ='));
  });

  test('sends the exact missed question to the explanation request', () async {
    final keyStore = _MemoryApiKeyStore()..value = 'test-gemini-key';
    http.Request? sentRequest;
    final client = MockClient((request) async {
      sentRequest = request;
      return _geminiResponse('Addım-addım: x = 4.');
    });
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    await service.explain(
      topic: const StudyTopic(
        id: 'math-equations',
        subject: StudySubject.mathematics,
        title: 'Tənliklər',
        lesson: 'Tənliyi həll et.',
        example: '2x = 8, x = 4.',
        questions: [],
      ),
      wasSlow: false,
      question: '2x + 5 = 13',
      selectedAnswer: 'x = 9',
    );

    expect(sentRequest!.body, contains('Sual: 2x + 5 = 13'));
    expect(sentRequest!.body, contains('Şagirdin seçimi: x = 9'));
  });

  test('explains Gemini API permission errors without leaking the key', () async {
    final keyStore = _MemoryApiKeyStore()..value = 'test-gemini-key';
    final client = MockClient((_) async => http.Response('{}', 403));
    final service = CoachService(client: client, keyStore: keyStore);
    addTearDown(service.dispose);

    await expectLater(
      service.ask(subject: StudySubject.mathematics, question: '1 + 1 nədir?'),
      throwsA(
        isA<CoachServiceException>()
            .having((error) => error.message, 'message', contains('açarı'))
            .having(
              (error) => error.message,
              'message',
              isNot(contains('test-gemini-key')),
            ),
      ),
    );
  });
}
