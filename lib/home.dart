import 'package:flutter/material.dart';

import 'bank.dart';
import 'exam.dart';
import 'learn.dart';
import 'menus.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wordlist.dart';

/// Bottom-navigation shell hosting Dashboard / Learning / Exams / Mistakes.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const <Widget>[
            DashboardView(),
            LearnTabView(),
            ExamTabView(),
            BankTabView(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: 'Exams',
          ),
          NavigationDestination(
            icon: Icon(Icons.error_outline),
            selectedIcon: Icon(Icons.error_rounded),
            label: 'Mistakes',
          ),
        ],
      ),
    );
  }
}

/// Top strip with avatar, name and menu.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppStore.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Pal.inkSoft,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Text(
                      store.name.isEmpty ? 'Learner' : store.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Pal.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Avatar(gender: store.gender, size: 52),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'More',
            color: Pal.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: (String value) {
              if (value == 'about') {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const AboutScreen(),
                ));
              } else if (value == 'reset') {
                _showResetSheet(context);
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.favorite_outline, color: Pal.lavender),
                    SizedBox(width: 10),
                    Text('About Word Quest'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'reset',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.restart_alt, color: Pal.blush),
                    SizedBox(width: 10),
                    Text('Reset progress'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showResetSheet(BuildContext context) {
  final AppStore store = AppStore.instance;
  showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext sheetContext) => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Reset',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose what you would like to clear. This cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Pal.inkSoft),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Pal.blush),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset learning progress'),
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _confirm(
                context,
                title: 'Reset progress?',
                message: 'Day unlocks, exam results and the mistake bank '
                    'will be cleared. Your profile stays.',
                onYes: () {
                  store.resetProgress();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress has been reset.')),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Start fresh (erase profile too)'),
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _confirm(
                context,
                title: 'Erase everything?',
                message: 'Your name and all progress will be removed and the '
                    'welcome screen will appear again.',
                destructive: true,
                onYes: () {
                  store.resetProfile();
                  store.resetProgress();
                },
              );
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onYes,
  bool destructive = false,
}) {
  final Color accent = destructive ? Pal.danger : Pal.lavender;
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onYes();
          },
          child: const Text('Yes, do it'),
        ),
      ],
    ),
  );
}

/// Landing screen: user statistics + a progress bar for every topic.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (BuildContext context, Widget? _) {
        final AppStore store = AppStore.instance;
        int totalWords = 0;
        for (final Topic t in Vocab.topics) {
          totalWords += t.items.length;
        }
        int totalDays = 0;
        for (final Topic t in Vocab.topics) {
          totalDays += t.totalDays;
        }
        final int mastered = store.totalMastered;
        final int passedExams = store.totalExamPassed;

        return ListView(
          padding: const EdgeInsets.only(bottom: 26),
          children: <Widget>[
            _TopBar(title: 'WORD QUEST'),
            const SizedBox(height: 14),
            // Hero greeting card with avatar (gender-based).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Pal.lavenderSoft, Pal.blushSoft],
                  ),
                  boxShadow: softShadow,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Hi ${store.name.isEmpty ? 'learner' : store.name} 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Pal.ink,
                            ),
                          ),
                        ),
                        Avatar(gender: store.gender, size: 58),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready for today’s vocabulary quest?',
                      style: TextStyle(color: Pal.inkSoft, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        _MiniStat(
                          icon: Icons.military_tech_outlined,
                          value: '$mastered',
                          label: 'mastered words',
                          color: Pal.lavender,
                        ),
                        const SizedBox(width: 10),
                        _MiniStat(
                          icon: Icons.task_alt_outlined,
                          value: '$passedExams',
                          label: 'exams passed',
                          color: Pal.mint,
                        ),
                        const SizedBox(width: 10),
                        _MiniStat(
                          icon: Icons.calendar_month_outlined,
                          value: '$totalDays',
                          label: 'total days',
                          color: Pal.blush,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Your progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '$mastered / $totalWords words mastered',
                    style: const TextStyle(
                      color: Pal.inkSoft,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < Vocab.topics.length; i++) TopicCard(index: i),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tap a topic to start learning or taking exams',
                style: TextStyle(color: fade(Pal.inkSoft, 0.85), fontSize: 12.5),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: fade(Colors.white, 0.75),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Pal.ink,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Pal.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

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
