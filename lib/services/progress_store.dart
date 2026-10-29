import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_models.dart';

class ProgressStore {
  static const _progressKey = 'exam_prep_progress_v1';

  Future<ProgressSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_progressKey);
    if (encoded == null) return ProgressSnapshot();
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return ProgressSnapshot.fromJson(decoded);
      }
    } on FormatException {
      await preferences.remove(_progressKey);
    }
    return ProgressSnapshot();
  }

  Future<void> save(ProgressSnapshot progress) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _progressKey,
      jsonEncode(progress.toJson()),
    );
    if (!saved) throw StateError('İrəliləyişi cihazda saxlamaq mümkün olmadı.');
  }
}
