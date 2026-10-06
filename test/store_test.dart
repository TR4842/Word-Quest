import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_quest/exam_engine.dart';
import 'package:word_quest/store.dart';
import 'package:word_quest/wordlist.dart';

Topic _topic(String id, int itemCount) {
  return Topic(
    id: id,
    title: id,
    subtitle: '',
    items: <VocabItem>[
      for (int i = 0; i < itemCount; i++)
        VocabItem(
          term: 'WORD$i',
          en: 'Meaning $i',
          bn: '',
          syn: '',
          ant: '',
          ex: '',
          pos: '',
          theme: '',
          bank: '',
        ),
    ],
  );
}

void main() {
  group('AppStore day unlocks', () {
    late SharedPreferences prefs;
    late AppStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      store = AppStore.init(prefs);
    });

    test(
      'advances independently per topic without requiring all words marked',
      () {
        final Topic wordSmart = _topic('wordSmart', 60);
        final Topic gre333 = _topic('gre333', 60);

        // Even if a later day's result exists, a topic unlocks sequentially.
        store.recordExam(
          topicId: wordSmart.id,
          day: 2,
          correct: 18,
          total: 20,
        );
        expect(store.unlockedDay(wordSmart), 1);

        // Passing the previous day unlocks the next day for this topic only.
        // No vocabulary item has to be marked as known first.
        store.recordExam(
          topicId: wordSmart.id,
          day: 1,
          correct: 18,
          total: 20,
        );
        expect(store.statsFor(wordSmart.id).learned, isEmpty);
        expect(store.unlockedDay(wordSmart), 3);
        expect(store.unlockedDay(gre333), 1);
      },
    );

    test('75 percent is enough to unlock the next day', () {
      final Topic topic = _topic('wordSmart', 40);

      store.recordExam(
        topicId: topic.id,
        day: 1,
        correct: 15,
        total: 20,
      );

      expect(store.unlockedDay(topic), 2);
    });

    test('a score below 75 percent does not unlock the next day', () {
      final Topic topic = _topic('wordSmart', 40);

      store.recordExam(
        topicId: topic.id,
        day: 1,
        correct: 14,
        total: 20,
      );

      expect(store.unlockedDay(topic), 1);
    });
  });

  group('existing on-device data', () {
    test(
      'loads and retains the existing v1 preferences and progress',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final ExamQuestion savedQuestion = ExamQuestion(
          type: qMeaning,
          topicId: 'wordSmart',
          itemIndex: 0,
          term: 'WORD0',
          prompt: 'What does WORD0 mean?',
          options: <String>['Meaning 0', 'Another meaning'],
          correctIndex: 0,
        );

        // These are the keys and JSON fields written by the previous version.
        await prefs.setString(
          'wq_profile_v1',
          jsonEncode(<String, String>{'name': 'Amina', 'gender': 'female'}),
        );
        await prefs.setString(
          'wq_stats_v1',
          jsonEncode(<String, dynamic>{
            'wordSmart': <String, dynamic>{
              'learned': <String, String>{'0': markKnown, '1': markPractice},
              'passed': <int>[1],
              'best': <String, int>{'1': 95},
            },
            'gre333': <String, dynamic>{
              'learned': <String, String>{},
              'passed': <int>[],
              'best': <String, int>{'1': 80},
            },
          }),
        );
        await prefs.setString(
          'wq_mistakes_v1',
          jsonEncode(<String, dynamic>{
            'wordSmart': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'old-mistake',
                'topicId': 'wordSmart',
                'day': 1,
                'question': savedQuestion.toJson(),
                'chosenIndex': 1,
              },
            ],
          }),
        );

        final AppStore upgradedStore = AppStore(prefs);
        final Topic topic = _topic('wordSmart', 40);

        expect(upgradedStore.name, 'Amina');
        expect(upgradedStore.gender, 'female');
        expect(upgradedStore.statsFor(topic.id).statusOf(0), markKnown);
        expect(upgradedStore.statsFor(topic.id).statusOf(1), markPractice);
        expect(upgradedStore.statsFor(topic.id).bestFor(1), 95);
        expect(upgradedStore.unlockedDay(topic), 2);
        final Topic previouslyFailedTopic = _topic('gre333', 40);
        expect(
          upgradedStore.statsFor(previouslyFailedTopic.id).passed(1),
          isTrue,
        );
        expect(upgradedStore.unlockedDay(previouslyFailedTopic), 2);
        expect(
          upgradedStore.mistakesFor(topic.id).single.chosen,
          'Another meaning',
        );

        // A normal save after upgrade must keep the old profile, scores, and
        // mistake bank alongside any new progress.
        upgradedStore.markItem(topic.id, 2, markKnown);
        final AppStore reloadedStore = AppStore(prefs);
        expect(reloadedStore.name, 'Amina');
        expect(reloadedStore.statsFor(topic.id).statusOf(0), markKnown);
        expect(reloadedStore.statsFor(topic.id).statusOf(1), markPractice);
        expect(reloadedStore.statsFor(topic.id).statusOf(2), markKnown);
        expect(reloadedStore.statsFor(topic.id).bestFor(1), 95);
        expect(reloadedStore.unlockedDay(topic), 2);
        expect(reloadedStore.statsFor('gre333').passed(1), isTrue);
        expect(reloadedStore.unlockedDay(previouslyFailedTopic), 2);
        expect(reloadedStore.mistakesFor(topic.id).single.id, 'old-mistake');
      },
    );
  });
}
