import 'package:flutter_test/flutter_test.dart';

import 'package:word_quest/exam_engine.dart';
import 'package:word_quest/wordlist.dart';

/// Builds a small fake topic for engine tests without loading the asset.
Topic makeTopic(String id, int count, {bool withSentences = false}) {
  final List<VocabItem> items = <VocabItem>[];
  for (int i = 0; i < count; i++) {
    final String w = 'WORD${i + 1}';
    items.add(VocabItem(
      term: w,
      en: 'Meaning of $w',
      bn: 'অর্থ $w',
      syn: 'SynA$w, SynB$w',
      ant: 'AntA$w, AntB$w',
      ex: withSentences ? 'A sentence that includes $w here.' : '',
      pos: 'Noun',
      theme: 'Theme $i',
      bank: 'exam ref $i',
    ));
  }
  return Topic(id: id, title: id, subtitle: '', items: items);
}

void main() {
  group('Topic day split', () {
    test('20 words per day', () {
      final Topic t = makeTopic('wordSmart', 45);
      expect(t.totalDays, 3);
      expect(t.dayItems(1).length, 20);
      expect(t.dayItems(2).length, 20);
      expect(t.dayItems(3).length, 5);
      expect(t.itemIndexesOfDay(1).first, 0);
      expect(t.itemIndexesOfDay(3).last, 44);
    });

    test('gap sentence blanks the term', () {
      final VocabItem item = VocabItem(
        term: 'ABASH',
        en: '',
        bn: 'লজ্জিত করা',
        syn: 'Shame',
        ant: '',
        ex: 'She did not let the question abash her.',
        pos: 'Verb',
        theme: '',
        bank: '',
      );
      expect(item.gapUsable, isTrue);
      expect(item.gapSentence, contains('______'));
      expect(item.gapSentence.toLowerCase(), isNot(contains('abash')));
    });
  });

  group('Exam generation', () {
    test('builds requested number of questions inside the day syllabus', () {
      final Topic t = makeTopic('wordSmart', 45, withSentences: true);
      final List<ExamQuestion> qs = buildExam(topic: t, day: 1, count: 30);
      expect(qs.length, 30);
      for (final ExamQuestion q in qs) {
        expect(q.topicId, 'wordSmart');
        // item must belong to day 1
        expect(t.itemIndexesOfDay(1), contains(q.itemIndex));
        expect(q.options.length, 4);
        expect(q.correctIndex, inInclusiveRange(0, 3));
        expect(q.correctAnswer, q.options[q.correctIndex]);
        expect(q.prompt, isNotEmpty);
        // only allowed kinds
        expect(allowedQuestionTypes(t), contains(q.type));
      }
    });

    test('every attempt randomises order and options', () {
      final Topic t = makeTopic('gre333', 40);
      final List<ExamQuestion> a = buildExam(topic: t, day: 1, count: 20);
      final List<ExamQuestion> b = buildExam(topic: t, day: 1, count: 20);
      bool different = false;
      for (int i = 0; i < a.length; i++) {
        if (a[i].prompt != b[i].prompt || a[i].correctIndex != b[i].correctIndex) {
          different = true;
          break;
        }
      }
      expect(different, isTrue, reason: 'two builds should not be identical');
    });

    test('correct answer is always one of the options', () {
      final Topic t = makeTopic('oneWord', 40);
      for (final ExamQuestion q in buildExam(topic: t, day: 1, count: 20)) {
        expect(q.options, contains(q.correctAnswer));
      }
    });

    test('question kinds per topic are sane', () {
      expect(allowedQuestionTypes(makeTopic('wordSmart', 5)),
          <String>[qMeaning, qSynonym, qAntonym, qGap]);
      expect(allowedQuestionTypes(makeTopic('gre333', 5)),
          <String>[qMeaning, qSynonym, qAntonym]);
      expect(allowedQuestionTypes(makeTopic('previousYear', 5)),
          <String>[qMeaning, qSynonym, qAntonym]);
      expect(allowedQuestionTypes(makeTopic('oneWord', 5)),
          <String>[qMeaning, qReverse]);
      expect(allowedQuestionTypes(makeTopic('idioms', 5)),
          <String>[qMeaning, qReverse]);
    });
  });

  group('Exam rules', () {
    test('90% pass thresholds', () {
      expect(passThreshold(20), 18);
      expect(passThreshold(25), 23);
      expect(passThreshold(30), 27);
    });

    test('time is half the question count, in minutes', () {
      expect(examDurationSeconds(20), 600); // 10 minutes
      expect(examDurationSeconds(30), 900); // 15 minutes
    });
  });
}
