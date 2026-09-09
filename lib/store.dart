import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exam_engine.dart';
import 'wordlist.dart';

const String _kProfile = 'wq_profile_v1';
const String _kStats = 'wq_stats_v1';
const String _kMistakes = 'wq_mistakes_v1';

/// How an item was marked during study sessions.
const String markKnown = 'k';
const String markPractice = 'p';

/// One saved wrong answer, kept separately per topic.
class MistakeRecord {
  MistakeRecord({
    required this.id,
    required this.topicId,
    required this.day,
    required this.question,
    required this.chosenIndex,
  });

  final String id;
  final String topicId;
  final int day;
  final ExamQuestion question;
  final int chosenIndex;

  String get chosen => question.options[chosenIndex];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'topicId': topicId,
        'day': day,
        'question': question.toJson(),
        'chosenIndex': chosenIndex,
      };

  factory MistakeRecord.fromJson(Map<String, dynamic> m) => MistakeRecord(
        id: m['id'] as String,
        topicId: m['topicId'] as String,
        day: m['day'] as int,
        question:
            ExamQuestion.fromJson(m['question'] as Map<String, dynamic>),
        chosenIndex: m['chosenIndex'] as int,
      );
}

/// Persisted per-topic learning stats.
class TopicStats {
  TopicStats();

  /// item index -> 'k' (known) / 'p' (needs practice)
  final Map<int, String> learned = <int, String>{};

  /// Days passed with >= 90%.
  final Set<int> passedDays = <int>{};

  /// Day -> best accuracy percentage.
  final Map<int, int> best = <int, int>{};

  String statusOf(int itemIndex) => learned[itemIndex] ?? '';

  int get masteredCount =>
      learned.values.where((v) => v == markKnown).length;

  int get practiceCount =>
      learned.values.where((v) => v == markPractice).length;

  bool passed(int day) => passedDays.contains(day);

  int bestFor(int day) => best[day] ?? 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'learned': learned.map((k, v) => MapEntry<String, dynamic>('$k', v)),
        'passed': passedDays.toList(),
        'best': best.map((k, v) => MapEntry<String, dynamic>('$k', v)),
      };

  factory TopicStats.fromJson(Map<String, dynamic> m) {
    final TopicStats s = TopicStats();
    final Map<String, dynamic> learned =
        (m['learned'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    learned.forEach((String k, dynamic v) {
      s.learned[int.parse(k)] = v as String;
    });
    final List<dynamic> passed = (m['passed'] as List<dynamic>?) ?? <dynamic>[];
    for (final dynamic d in passed) {
      s.passedDays.add(d as int);
    }
    final Map<String, dynamic> best =
        (m['best'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    best.forEach((String k, dynamic v) {
      s.best[int.parse(k)] = v as int;
    });
    return s;
  }
}

/// Global application store: profile + progress + mistake bank, persisted
/// through [SharedPreferences] (fully offline).
class AppStore extends ChangeNotifier {
  AppStore(this._prefs) {
    _load();
  }

  static AppStore? _instance;

  static AppStore get instance {
    final AppStore? s = _instance;
    if (s == null) {
      throw StateError('AppStore.instance not initialised');
    }
    return s;
  }

  static AppStore init(SharedPreferences prefs) {
    final AppStore store = AppStore(prefs);
    _instance = store;
    return store;
  }

  final SharedPreferences _prefs;

  bool _initialised = false;
  String _name = '';
  String _gender = 'male';
  final Map<String, TopicStats> _stats = <String, TopicStats>{};
  final Map<String, List<MistakeRecord>> _mistakes = <String, List<MistakeRecord>>{};

  bool get initialised => _initialised;

  String get name => _name;
  String get gender => _gender;
  bool get hasProfile => _name.isNotEmpty;

  TopicStats statsFor(String topicId) {
    final TopicStats? s = _stats[topicId];
    if (s == null) {
      final TopicStats fresh = TopicStats();
      _stats[topicId] = fresh;
      return fresh;
    }
    return s;
  }

  /// How many days of [topic] are unlocked (always at least one).
  int unlockedDay(Topic topic) {
    final TopicStats s = statsFor(topic.id);
    int d = 1;
    while (s.passed(d) && d < topic.totalDays) {
      d++;
    }
    return d;
  }

  int passedCount(String topicId) => statsFor(topicId).passedDays.length;

  int get totalMastered {
    int n = 0;
    _stats.forEach((String k, TopicStats s) => n += s.masteredCount);
    return n;
  }

  int get totalPractice {
    int n = 0;
    _stats.forEach((String k, TopicStats s) => n += s.practiceCount);
    return n;
  }

  int get totalExamPassed {
    int n = 0;
    _stats.forEach((String k, TopicStats s) => n += s.passedDays.length);
    return n;
  }

  /// Marks one item and persists.
  void markItem(String topicId, int itemIndex, String status) {
    statsFor(topicId).learned[itemIndex] = status;
    _save();
    notifyListeners();
  }

  /// Records an exam attempt. Returns true when the day became passed.
  bool recordExam({
    required String topicId,
    required int day,
    required int correct,
    required int total,
  }) {
    final TopicStats s = statsFor(topicId);
    final int percent = total == 0 ? 0 : ((correct * 100) / total).round();
    final int prevBest = s.bestFor(day);
    if (percent > prevBest) s.best[day] = percent;
    final bool passed = percent >= 90 && !s.passed(day);
    if (passed) s.passedDays.add(day);
    _save();
    notifyListeners();
    return passed;
  }

  List<MistakeRecord> mistakesFor(String topicId) =>
      _mistakes[topicId] ?? <MistakeRecord>[];

  void addMistake({
    required String topicId,
    required int day,
    required ExamQuestion question,
    required int chosenIndex,
  }) {
    if (chosenIndex == question.correctIndex) return; // not a mistake
    final List<MistakeRecord> list =
        _mistakes.putIfAbsent(topicId, () => <MistakeRecord>[]);
    list.insert(
        0,
        MistakeRecord(
          id: '${DateTime.now().microsecondsSinceEpoch}_${list.length}',
          topicId: topicId,
          day: day,
          question: question,
          chosenIndex: chosenIndex,
        ));
    _save();
    notifyListeners();
  }

  void removeMistake(String topicId, String id) {
    _mistakes[topicId]?.removeWhere((MistakeRecord m) => m.id == id);
    _save();
    notifyListeners();
  }

  /// Called by mistake-bank practice when the learner answers a previously
  /// wrong question correctly — removes the matching saved record(s).
  void reviewMistakeSolved(String topicId, ExamQuestion question) {
    final List<MistakeRecord>? list = _mistakes[topicId];
    if (list == null) return;
    list.removeWhere((MistakeRecord m) => _sameQuestion(m.question, question));
    _save();
    notifyListeners();
  }

  static bool _sameQuestion(ExamQuestion a, ExamQuestion b) {
    if (a.term != b.term ||
        a.prompt != b.prompt ||
        a.correctIndex != b.correctIndex ||
        a.options.length != b.options.length) {
      return false;
    }
    for (int i = 0; i < a.options.length; i++) {
      if (a.options[i] != b.options[i]) return false;
    }
    return true;
  }

  void clearTopicMistakes(String topicId) {
    _mistakes[topicId]?.clear();
    _save();
    notifyListeners();
  }

  /// Wipes all progress (marks, passes, best scores, mistake bank).
  void resetProgress() {
    _stats.clear();
    _mistakes.clear();
    _save();
    notifyListeners();
  }

  /// Clears the profile so the welcome dialog shows again.
  void resetProfile() {
    _name = '';
    _gender = 'male';
    _save();
    notifyListeners();
  }

  void saveProfile({required String name, required String gender}) {
    _name = name.trim();
    _gender = gender;
    _save();
    notifyListeners();
  }

  void _load() {
    final String? profileRaw = _prefs.getString(_kProfile);
    if (profileRaw != null && profileRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> m =
            jsonDecode(profileRaw) as Map<String, dynamic>;
        _name = (m['name'] as String?) ?? '';
        _gender = (m['gender'] as String?) ?? 'male';
      } catch (_) {
        // corrupted store: start fresh
      }
    }
    final String? statsRaw = _prefs.getString(_kStats);
    if (statsRaw != null && statsRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> m =
            jsonDecode(statsRaw) as Map<String, dynamic>;
        m.forEach((String topicId, dynamic v) {
          _stats[topicId] =
              TopicStats.fromJson(v as Map<String, dynamic>);
        });
      } catch (_) {
        // corrupted store: start fresh
      }
    }
    final String? mistakesRaw = _prefs.getString(_kMistakes);
    if (mistakesRaw != null && mistakesRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> m =
            jsonDecode(mistakesRaw) as Map<String, dynamic>;
        m.forEach((String topicId, dynamic v) {
          _mistakes[topicId] = <MistakeRecord>[
            for (final dynamic e in v as List<dynamic>)
              MistakeRecord.fromJson(e as Map<String, dynamic>),
          ];
        });
      } catch (_) {
        // corrupted store: start fresh
      }
    }
    _initialised = true;
  }

  void _save() {
    _prefs.setString(_kProfile, jsonEncode(<String, String>{
      'name': _name,
      'gender': _gender,
    }));
    _prefs.setString(_kStats, jsonEncode(_stats.map((String k, TopicStats v) =>
        MapEntry<String, dynamic>(k, v.toJson()))));
    _prefs.setString(_kMistakes, jsonEncode(_mistakes.map(
        (String k, List<MistakeRecord> v) =>
            MapEntry<String, dynamic>(k, v.map((e) => e.toJson()).toList()))));
  }
}
