import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/study_models.dart';

abstract interface class GeminiApiKeyStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class DeviceGeminiApiKeyStore implements GeminiApiKeyStore {
  DeviceGeminiApiKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _keyName = 'gemini_api_key';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _keyName);

  @override
  Future<void> write(String value) =>
      _storage.write(key: _keyName, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _keyName);
}

class CoachServiceException implements Exception {
  const CoachServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CoachAnswer {
  const CoachAnswer({
    required this.answer,
    required this.lessonTopic,
  });

  final String answer;
  final String lessonTopic;
}

class CoachLesson {
  const CoachLesson({
    required this.title,
    required this.explanation,
    required this.examples,
    required this.commonMistake,
    required this.practiceQuestion,
    required this.practiceAnswer,
  });

  final String title;
  final String explanation;
  final List<String> examples;
  final String commonMistake;
  final String practiceQuestion;
  final String practiceAnswer;
}

class CoachService {
  CoachService({
    http.Client? client,
    GeminiApiKeyStore? keyStore,
  })  : _client = client ?? http.Client(),
        _keyStore = keyStore ?? DeviceGeminiApiKeyStore();

  static final _endpoint = Uri.https(
    'generativelanguage.googleapis.com',
    '/v1beta/models/gemini-2.5-flash:generateContent',
  );
  final http.Client _client;
  final GeminiApiKeyStore _keyStore;

  Future<bool> get hasApiKey async =>
      (await _keyStore.read())?.isNotEmpty == true;

  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      throw const CoachServiceException('API açarı boş ola bilməz.');
    }
    await _generateWithKey(
      'API açarını yoxlamaq üçün yalnız "OK" cavabı ver.',
      apiKey: trimmed,
      maxOutputTokens: 16,
    );
    await _keyStore.write(trimmed);
  }

  Future<void> removeApiKey() => _keyStore.delete();

  void dispose() => _client.close();

  Future<CoachAnswer> ask({
    required StudySubject subject,
    required String question,
  }) async {
    final subjectName =
        subject == StudySubject.mathematics ? 'Riyaziyyat' : 'İngilis dili';
    final subjectInstructions = subject == StudySubject.mathematics
        ? 'Riyazi ifadələri düzgün yaz. Həll tələb olunursa, düsturu göstər, '
            'rəqəmləri yerinə qoy və hesablamanı yoxla.'
        : 'Qrammatika sualında düzgün İngilis cümləsini yaz, qaydanı Azərbaycan '
            'dilində izah et və yanlış variantın niyə yanlış olduğunu göstər.';
    final prompt = [
      'Sən Azərbaycan 9-cu sinif buraxılış imtahanına hazırlaşdıran diqqətli müəllimsən.',
      'Yalnız seçilmiş fənn üzrə cavab ver. Əlaqəsiz mövzuya keçmə.',
      'Sual seçilmiş fəndən kənardırsa bunu açıq və nəzakətlə de, başqa fənnə aid cavab uydurma.',
      'Şagirdin sualını əvvəlcə diqqətlə oxu və cavabın birbaşa həmin sualı həll etdiyini yoxla.',
      'Məlumat çatışmırsa, konkretləşdirici sual ver; mövzu uydurma və sualı başqa mövzu kimi yozma.',
      'Cavabı Azərbaycan dilində, sadə və şagirdin səviyyəsinə uyğun yaz. İngilis dili nümunələri İngiliscə qala bilər.',
      subjectInstructions,
      'Lazım olduqda qısa addım-addım həll və ayrıca düzgün nümunə ver.',
      'Dəqiq imtahan sualı proqnozlaşdırma və nəticəyə zəmanət vermə.',
      'JSON qaytar: {"answer":"sualın dəqiq cavabı və izahı","lessonTopic":"yalnız uyğun dərs mövzusu; uyğun deyilsə boş sətir"}.',
      'FƏNN: $subjectName',
      'ŞAGİRDİN SUALI:\n$question',
    ].join('\n');

    final result = await _generateJson(prompt, maxOutputTokens: 1100);
    final answer = result['answer'];
    final topic = result['lessonTopic'];
    if (answer is! String || answer.trim().isEmpty || topic is! String) {
      throw const CoachServiceException(
        'Gemini cavabı oxunaqlı formatda qaytarmadı. Yenidən cəhd edin.',
      );
    }
    return CoachAnswer(answer: answer.trim(), lessonTopic: topic.trim());
  }

  Future<CoachLesson> teach({
    required StudySubject subject,
    required String topic,
  }) async {
    final subjectName =
        subject == StudySubject.mathematics ? 'Riyaziyyat' : 'İngilis dili';
    final instructions = subject == StudySubject.mathematics
        ? 'Riyaziyyatda ən azı bir düstur və iki müxtəlif, tam addımlarla həll edilmiş nümunə göstər. Hesablamaları cavabdan əvvəl yoxla.'
        : 'İngilis dilində qaydanı Azərbaycan dilində izah et. İki düzgün İngilis nümunəsi və bir səhv-düzəliş nümunəsi ver.';
    final prompt = [
      'Sən Azərbaycan 9-cu sinif buraxılış imtahanına hazırlaşdıran təcrübəli müəllimsən.',
      'Mövzudan kənara çıxmadan, şagirdin həqiqətən öyrənə biləcəyi qısa, dolğun mini-dərs yaz.',
      'Əvvəl sadə anlayış, sonra qayda, sonra həll addımları. Lazımsız ümumi məsləhət və uydurma fakt yazma.',
      instructions,
      'Sonda yayğın bir səhvi izah et və cavabı ayrıca verilən bir məşq sualı hazırla.',
      'Məzmun Azərbaycan dilində olsun; İngilis dili nümunə cümlələri İngiliscə yazılsın.',
      'JSON qaytar: {"title":"dərs başlığı","explanation":"anlayış və qayda","examples":["birinci addım-addım nümunə","ikinci nümunə"],"commonMistake":"yayğın səhv və düzəlişi","practiceQuestion":"şagird üçün sual","practiceAnswer":"qısa cavab və izah"}.',
      'FƏNN: $subjectName',
      'DƏRS MÖVZUSU: $topic',
    ].join('\n');

    final result = await _generateJson(prompt, maxOutputTokens: 1800);
    final title = result['title'];
    final explanation = result['explanation'];
    final examples = result['examples'];
    final commonMistake = result['commonMistake'];
    final practiceQuestion = result['practiceQuestion'];
    final practiceAnswer = result['practiceAnswer'];
    if (title is! String ||
        title.trim().isEmpty ||
        explanation is! String ||
        explanation.trim().isEmpty ||
        examples is! List ||
        examples.length < 2 ||
        examples.any(
          (example) => example is! String || example.trim().isEmpty,
        ) ||
        commonMistake is! String ||
        commonMistake.trim().isEmpty ||
        practiceQuestion is! String ||
        practiceQuestion.trim().isEmpty ||
        practiceAnswer is! String ||
        practiceAnswer.trim().isEmpty) {
      throw const CoachServiceException(
        'Gemini dərsi tam qaytarmadı. Yenidən cəhd edin.',
      );
    }
    return CoachLesson(
      title: title.trim(),
      explanation: explanation.trim(),
      examples:
          examples.cast<String>().map((example) => example.trim()).toList(),
      commonMistake: commonMistake.trim(),
      practiceQuestion: practiceQuestion.trim(),
      practiceAnswer: practiceAnswer.trim(),
    );
  }

  Future<String> explain({
    required StudyTopic topic,
    required bool wasSlow,
    required String question,
    String? selectedAnswer,
  }) async {
    final subjectName =
        topic.subject == StudySubject.mathematics ? 'Riyaziyyat' : 'İngilis dili';
    final prompt = [
      'Sən Azərbaycan 9-cu sinif şagirdinin səhvini düzəldən müəllimsən.',
      'Yalnız aşağıdakı konkret sualı və şagirdin cavabını izah et; başqa mövzuya keçmə.',
      'Sual: $question',
      if (selectedAnswer != null) 'Şagirdin seçimi: $selectedAnswer',
      'Mövzu qeydi: ${topic.lesson}',
      'Nümunə: ${topic.example}',
      wasSlow
          ? 'Şagird həll etməkdə çətinlik çəkdi; ilk addımdan başla.'
          : 'Cavab səhvdir; səhvin səbəbini mühakimə etmədən izah et.',
      topic.subject == StudySubject.mathematics
          ? 'Düzgün həlli addım-addım və yoxlama ilə göstər.'
          : 'Düzgün İngilis formasını yaz və qaydanı Azərbaycan dilində izah et.',
      'Cavabı Azərbaycan dilində, qısa, aydın və konkret yaz. Fənn: $subjectName.',
    ].join('\n');
    return _generateText(prompt, maxOutputTokens: 700);
  }

  Future<StudyQuestion> generateReviewQuestion(StudyTopic topic) async {
    final subjectName =
        topic.subject == StudySubject.mathematics ? 'Riyaziyyat' : 'İngilis dili';
    final languageInstruction = topic.subject == StudySubject.mathematics
        ? 'Sual və variantlar Azərbaycan dilində olsun.'
        : 'İngilis dili cümləsi/sualı İngiliscə, izah Azərbaycan dilində olsun.';
    final prompt = [
      'Yalnız aşağıdakı dərs qeydinə əsaslanan, 9-cu sinif səviyyəsində bir orijinal test sualı hazırla.',
      'Mövzu: ${topic.title}',
      'Qayda: ${topic.lesson}',
      'Nümunə: ${topic.example}',
      languageInstruction,
      'Düzgün cavab yalnız bir variant olmalıdır. İzah addım-addım və sualla əlaqəli olsun.',
      'JSON qaytar: {"prompt":"sual","options":["A","B","C","D"],"correctIndex":0,"explanation":"düzgün cavabın izahı"}.',
      'Fənn: $subjectName.',
    ].join('\n');
    final result = await _generateJson(prompt, maxOutputTokens: 800);
    final question = result['prompt'];
    final options = result['options'];
    final correctIndex = result['correctIndex'];
    final explanation = result['explanation'];
    if (question is! String ||
        question.trim().isEmpty ||
        options is! List ||
        options.length != 4 ||
        options.any((option) => option is! String) ||
        correctIndex is! int ||
        correctIndex < 0 ||
        correctIndex >= 4 ||
        explanation is! String ||
        explanation.trim().isEmpty) {
      throw const CoachServiceException(
        'Gemini etibarlı test sualı qaytarmadı. Yenidən cəhd edin.',
      );
    }
    return StudyQuestion(
      prompt: question.trim(),
      options: options.cast<String>(),
      correctIndex: correctIndex,
      explanation: explanation.trim(),
    );
  }

  Future<String> _generateText(
    String prompt, {
    required int maxOutputTokens,
    String? responseMimeType,
  }) async {
    final result = await _generate(
      prompt,
      maxOutputTokens: maxOutputTokens,
      responseMimeType: responseMimeType,
    );
    final candidates = result['candidates'];
    final content = candidates is List && candidates.isNotEmpty
        ? candidates.first
        : null;
    final nestedContent = content is Map ? content['content'] : null;
    final parts = nestedContent is Map ? nestedContent['parts'] : null;
    final text = parts is List
        ? parts
            .where((part) => part is Map && part['text'] is String)
            .map((part) => (part['text'] as String).trim())
            .join('\n')
            .trim()
        : null;
    if (text == null || text.isEmpty) {
      throw const CoachServiceException(
        'Gemini bu suala cavab yarada bilmədi. Sualı başqa cür yazıb yenidən sınayın.',
      );
    }
    return text;
  }

  Future<Map<String, dynamic>> _generateJson(
    String prompt, {
    required int maxOutputTokens,
  }) async {
    final text = await _generateText(
      prompt,
      maxOutputTokens: maxOutputTokens,
      responseMimeType: 'application/json',
    );
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw const CoachServiceException(
        'Gemini cavabı gözlənilən formatda deyil. Yenidən cəhd edin.',
      );
    }
    throw const CoachServiceException(
      'Gemini cavabı gözlənilən formatda deyil. Yenidən cəhd edin.',
    );
  }

  Future<Map<String, dynamic>> _generate(
    String prompt, {
    required int maxOutputTokens,
    String? responseMimeType,
  }) async {
    final apiKey = await _keyStore.read();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const CoachServiceException(
        'Gemini API açarı daxil edilməyib. Açarı tətbiqdə quraşdırın.',
      );
    }

    return _generateWithKey(
      prompt,
      apiKey: apiKey.trim(),
      maxOutputTokens: maxOutputTokens,
      responseMimeType: responseMimeType,
    );
  }

  Future<Map<String, dynamic>> _generateWithKey(
    String prompt, {
    required String apiKey,
    required int maxOutputTokens,
    String? responseMimeType,
  }) async {
    final generationConfig = <String, Object>{
      'temperature': 0.25,
      'maxOutputTokens': maxOutputTokens,
      if (responseMimeType != null) 'responseMimeType': responseMimeType,
    };
    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            headers: {
              'content-type': 'application/json',
              'x-goog-api-key': apiKey.trim(),
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': generationConfig,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const CoachServiceException(
        'Gemini 45 saniyə ərzində cavab vermədi. İnterneti yoxlayın və yenidən sınayın.',
      );
    } on SocketException catch (error) {
      debugPrint('Gemini network connection failed: $error');
      throw const CoachServiceException(
        'Gemini serverinə internet bağlantısı qurulmadı. Wi-Fi internetini yoxlayın və yenidən sınayın.',
      );
    } on HandshakeException catch (error) {
      debugPrint('Gemini TLS handshake failed: $error');
      throw const CoachServiceException(
        'Gemini ilə təhlükəsiz bağlantı qurulmadı. Tarix və saatı, sonra interneti yoxlayın.',
      );
    } on http.ClientException catch (error) {
      debugPrint('Gemini HTTP connection failed: $error');
      final details = error.message.toLowerCase();
      if (details.contains('socketexception') ||
          details.contains('failed host lookup') ||
          details.contains('network is unreachable') ||
          details.contains('no address associated with hostname') ||
          details.contains('connection refused')) {
        throw const CoachServiceException(
          'Gemini serverinə internet bağlantısı qurulmadı. Wi-Fi qoşulmasını deyil, internetə çıxışı yoxlayın və yenidən sınayın.',
        );
      }
      throw const CoachServiceException(
        'Gemini sorğusu göndərildi, lakin bağlantı cavab vermədi. İnternetə çıxışı yoxlayın və yenidən sınayın.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CoachServiceException(_httpErrorMessage(response.statusCode));
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final candidates = decoded['candidates'];
        final content = candidates is List && candidates.isNotEmpty
            ? candidates.first
            : null;
        final nestedContent = content is Map ? content['content'] : null;
        final parts =
            nestedContent is Map ? nestedContent['parts'] : null;
        final hasText = parts is List &&
            parts.any(
              (part) =>
                  part is Map &&
                  part['text'] is String &&
                  (part['text'] as String).trim().isNotEmpty,
            );
        if (hasText) return decoded;
        throw const CoachServiceException(
          'Google Gemini sorğunu qəbul etdi, amma cavab yarada bilmədi. API limitini və açar icazələrini yoxlayın.',
        );
      }
    } on FormatException {
      throw const CoachServiceException(
        'Gemini xidmətindən düzgün cavab alınmadı. Bir az sonra yenidən sınayın.',
      );
    }
    throw const CoachServiceException(
      'Gemini xidmətindən düzgün cavab alınmadı. Bir az sonra yenidən sınayın.',
    );
  }

  String _httpErrorMessage(int statusCode) => switch (statusCode) {
        400 || 401 || 403 =>
          'Gemini API açarı yanlışdır və ya istifadə icazəsi yoxdur. Açarı yoxlayın.',
        404 => 'Gemini modeli əlçatan deyil. Bir az sonra yenidən sınayın.',
        429 =>
          'Gemini sorğu limiti və ya kvotası dolub. Google AI Studio hesabınızı yoxlayın.',
        _ => 'Gemini xidmətində xəta baş verdi (HTTP $statusCode).',
      };
}
