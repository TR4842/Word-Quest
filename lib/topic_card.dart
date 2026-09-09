import 'package:flutter/material.dart';

import 'exam.dart';
import 'learn.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wordlist.dart';

/// One topic row with its progress bar. Tap opens the topic — in learning
/// mode (flashcards + day plan) or exam mode.
class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.index, this.examMode = false});

  final int index;
  final bool examMode;

  @override
  Widget build(BuildContext context) {
    final Topic topic = Vocab.topics[index];
    final TopicColor accent = topicAccents[index % topicAccents.length];
    final AppStore store = AppStore.instance;
    final int mastered = store.statsFor(topic.id).masteredCount;
    final int total = topic.items.length;
    final double fraction = total == 0 ? 0 : mastered / total;
    final int unlocked = store.unlockedDay(topic);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => examMode
              ? ExamTopicScreen(topicIndex: index)
              : LearnTopicScreen(topicIndex: index),
        )),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.soft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_iconFor(topic.id), color: accent.main, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          topic.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        'Day $unlocked/${topic.totalDays}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: accent.main,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    topic.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Pal.inkSoft),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: PastelProgress(
                          value: fraction,
                          color: accent.main,
                          trackColor: accent.soft,
                          height: 9,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        mastered == 0 && total > 0 ? '0%' : '${(fraction * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: accent.main,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String topicId) {
  switch (topicId) {
    case 'wordSmart':
      return Icons.auto_stories_outlined;
    case 'gre333':
      return Icons.school_outlined;
    case 'previousYear':
      return Icons.history_edu_outlined;
    case 'oneWord':
      return Icons.translate_outlined;
    case 'idioms':
      return Icons.forum_outlined;
    default:
      return Icons.menu_book_outlined;
  }
}
