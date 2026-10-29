enum StudySubject { mathematics, english }

class StudyQuestion {
  const StudyQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.openEndedKeywords = const [],
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final List<String> openEndedKeywords;

  bool get isOpenEnded => options.isEmpty;
}

class StudyTopic {
  const StudyTopic({
    required this.id,
    required this.subject,
    required this.title,
    required this.lesson,
    required this.example,
    required this.questions,
  });

  final String id;
  final StudySubject subject;
  final String title;
  final String lesson;
  final String example;
  final List<StudyQuestion> questions;
}

class ProgressSnapshot {
  ProgressSnapshot({
    this.studentName = '',
    this.legalConsentAccepted = false,
    this.lastTopicId,
    this.darkModeEnabled = false,
    this.totalAnswered = 0,
    this.totalCorrect = 0,
    Set<String>? completedTopicIds,
    Set<String>? weakTopicIds,
  })  : completedTopicIds = completedTopicIds ?? <String>{},
        weakTopicIds = weakTopicIds ?? <String>{};

  String studentName;
  bool legalConsentAccepted;
  String? lastTopicId;
  bool darkModeEnabled;
  int totalAnswered;
  int totalCorrect;
  final Set<String> completedTopicIds;
  final Set<String> weakTopicIds;

  Map<String, Object?> toJson() => {
        'studentName': studentName,
        'legalConsentAccepted': legalConsentAccepted,
        'lastTopicId': lastTopicId,
        'darkModeEnabled': darkModeEnabled,
        'totalAnswered': totalAnswered,
        'totalCorrect': totalCorrect,
        'completedTopicIds': completedTopicIds.toList(),
        'weakTopicIds': weakTopicIds.toList(),
      };

  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) {
    return ProgressSnapshot(
      studentName: json['studentName'] as String? ?? '',
      legalConsentAccepted: json['legalConsentAccepted'] as bool? ?? false,
      lastTopicId: json['lastTopicId'] as String?,
      darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
      totalAnswered: json['totalAnswered'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      completedTopicIds:
          (json['completedTopicIds'] as List<dynamic>? ?? []).cast<String>().toSet(),
      weakTopicIds:
          (json['weakTopicIds'] as List<dynamic>? ?? []).cast<String>().toSet(),
    );
  }
}
