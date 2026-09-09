import 'dart:math';

import 'wordlist.dart';

/// Question kinds.
const String qMeaning = 'meaning'; // term -> definition
const String qReverse = 'reverse'; // definition -> term
const String qSynonym = 'synonym';
const String qAntonym = 'antonym';
const String qGap = 'gap'; // fill in the blank from the example sentence

/// A single multiple-choice exam question.
class ExamQuestion {
  const ExamQuestion({
    required this.type,
    required this.topicId,
    required this.itemIndex,
    required this.term,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String type;
  final String topicId;
  final int itemIndex;
  final String term;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  String get correctAnswer => options[correctIndex];

  String get typeLabel {
    switch (type) {
      case qSynonym:
        return 'Synonym';
      case qAntonym:
        return 'Antonym';
      case qGap:
        return 'Fill in the gap';
      case qReverse:
        return 'Find the word';
      default:
        return 'Meaning';
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'topicId': topicId,
        'itemIndex': itemIndex,
        'term': term,
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
      };

  factory ExamQuestion.fromJson(Map<String, dynamic> m) => ExamQuestion(
        type: m['type'] as String,
        topicId: m['topicId'] as String,
        itemIndex: m['itemIndex'] as int,
        term: m['term'] as String,
        prompt: m['prompt'] as String,
        options: (m['options'] as List<dynamic>).cast<String>(),
        correctIndex: m['correctIndex'] as int,
      );
}

/// Which question kinds a topic offers.
List<String> allowedQuestionTypes(Topic topic) {
  switch (topic.id) {
    case 'wordSmart':
      return <String>[qMeaning, qSynonym, qAntonym, qGap];
    case 'gre333':
      return <String>[qMeaning, qSynonym, qAntonym];
    case 'previousYear':
      return <String>[qMeaning, qSynonym, qAntonym];
    case 'oneWord':
      return <String>[qMeaning, qReverse];
    case 'idioms':
      return <String>[qMeaning, qReverse];
    default:
      return <String>[qMeaning];
  }
}

/// The definition text used as the *answer* to a "meaning" question for this
/// topic (English or Bengali, matching the workbook columns).
String definitionFor(Topic topic, VocabItem item) {
  switch (topic.id) {
    case 'wordSmart':
    case 'gre333':
      return item.bn;
    default:
      return item.en;
  }
}

/// Prompt shown to the learner for a given (topic, kind, item).
String promptFor(Topic topic, String type, VocabItem item) {
  switch (type) {
    case qMeaning:
      switch (topic.id) {
        case 'oneWord':
          return 'What is the meaning of “${item.term}”?';
        case 'idioms':
          return 'What does the idiom “${item.term}” mean?';
        default:
          return 'What is the meaning of “${item.term}”?';
      }
    case qReverse:
      if (topic.id == 'oneWord') {
        return 'Which single word best replaces “${item.en}”?';
      }
      return 'Which idiom matches “${item.en}”?';
    case qSynonym:
      return 'Choose the word closest in meaning (a synonym) to “${item.term}”.';
    case qAntonym:
      return 'Choose the word opposite in meaning (an antonym) to “${item.term}”.';
    case qGap:
      return 'Choose the word that best fills the gap:\n\n“${item.gapSentence}”';
    default:
      return 'About “${item.term}”';
  }
}

bool _itemSupportsKind(Topic topic, VocabItem item, String kind) {
  switch (kind) {
    case qGap:
      return item.gapUsable;
    case qSynonym:
      return item.synonyms.isNotEmpty;
    case qAntonym:
      return item.antonyms.isNotEmpty;
    case qMeaning:
      return definitionFor(topic, item).trim().isNotEmpty;
    case qReverse:
      return item.term.trim().isNotEmpty && item.en.trim().isNotEmpty;
    default:
      return false;
  }
}

/// Generates [count] questions for one day of a topic.
///
/// * The syllabus is exactly the day's words (see [Topic.itemIndexesOfDay]).
/// * Every attempt is randomised — question order and option order.
/// * Distractors come from the same day first, then the whole topic.
/// * When [count] exceeds the number of possible (word, kind) pairs, extra
///   slots are filled by re-sampling — still inside the day's syllabus.
List<ExamQuestion> buildExam({
  required Topic topic,
  required int day,
  required int count,
}) {
  final Random rng = Random();
  final List<int> dayIndexes = topic.itemIndexesOfDay(day);
  final List<String> kinds = allowedQuestionTypes(topic);

  final List<MapEntry<int, String>> pairs = <MapEntry<int, String>>[];
  for (final int idx in dayIndexes) {
    final VocabItem item = topic.items[idx];
    for (final String kind in kinds) {
      if (_itemSupportsKind(topic, item, kind)) {
        pairs.add(MapEntry<int, String>(idx, kind));
      }
    }
  }
  if (pairs.isEmpty) return <ExamQuestion>[];

  final List<ExamQuestion> questions = <ExamQuestion>[];

  while (questions.length < count) {
    final List<MapEntry<int, String>> shuffled =
        List<MapEntry<int, String>>.of(pairs)..shuffle(rng);
    for (final MapEntry<int, String> pair in shuffled) {
      if (questions.length >= count) break;
      questions.add(_buildOne(topic, day, pair.key, pair.value, rng));
    }
  }
  questions.shuffle(rng);
  return questions;
}

ExamQuestion _buildOne(Topic topic, int day, int idx, String kind, Random rng) {
  final VocabItem item = topic.items[idx];
  final String correct = _correctFor(topic, item, kind, rng);
  final List<String> block = <String>[
    if (kind == qSynonym) ...item.synonyms,
    if (kind == qAntonym) ...item.antonyms,
  ].map((s) => s.toLowerCase()).toList();

  final List<String> options = _makeOptions(
    correct: correct,
    dayTexts: _textsFor(topic, day, kind),
    allTexts: _textsFor(topic, -1, kind),
    blocked: block,
    rng: rng,
  );

  return ExamQuestion(
    type: kind,
    topicId: topic.id,
    itemIndex: idx,
    term: item.term,
    prompt: promptFor(topic, kind, item),
    options: options,
    correctIndex: options.indexOf(correct),
  );
}

/// The distractor text pool for a question kind, restricted to one day (or to
/// the whole topic when [day] is < 1).
List<String> _textsFor(Topic topic, int day, String kind) {
  final List<VocabItem> items = day >= 1 ? topic.dayItems(day) : topic.items;
  switch (kind) {
    case qMeaning:
      return items.map((v) => definitionFor(topic, v)).toList();
    case qReverse:
      return items.map((v) => v.term).toList();
    case qSynonym:
      return items.expand((v) => v.synonyms).toList();
    case qAntonym:
      return items.expand((v) => v.antonyms).toList();
    case qGap:
      return items.map((v) => v.term).toList();
    default:
      return items.map((v) => v.term).toList();
  }
}

String _correctFor(Topic topic, VocabItem item, String kind, Random rng) {
  switch (kind) {
    case qSynonym:
      return item.synonyms[rng.nextInt(item.synonyms.length)];
    case qAntonym:
      return item.antonyms[rng.nextInt(item.antonyms.length)];
    case qMeaning:
      return definitionFor(topic, item);
    default:
      return item.term;
  }
}

/// Assembles a shuffled 4-option list containing [correct].
List<String> _makeOptions({
  required String correct,
  required List<String> dayTexts,
  required List<String> allTexts,
  required List<String> blocked,
  required Random rng,
}) {
  bool usable(String c) =>
      c.trim().isNotEmpty &&
      c != correct &&
      !blocked.contains(c.toLowerCase());

  final List<String> day = dayTexts.where(usable).toSet().toList()..shuffle(rng);
  final Set<String> daySet = day.toSet();
  final List<String> rest =
      allTexts.where((c) => usable(c) && !daySet.contains(c)).toSet().toList()
        ..shuffle(rng);

  final List<String> distractors = <String>[];
  for (final String s in day) {
    if (distractors.length >= 3) break;
    distractors.add(s);
  }
  for (final String s in rest) {
    if (distractors.length >= 3) break;
    distractors.add(s);
  }
  while (distractors.length < 3) {
    final String pad = 'None of these';
    final String unique =
        distractors.contains(pad) ? '$pad ${distractors.length}' : pad;
    distractors.add(unique);
  }

  final List<String> options = <String>[correct, ...distractors.take(3)];
  options.shuffle(rng);
  return options;
}

/// Minimum questions answered correctly to pass (>= 90%).
int passThreshold(int total) => (total * 9 + 9) ~/ 10;

/// Exam duration in seconds = half of the question count, in minutes.
int examDurationSeconds(int questionCount) => questionCount * 30;
