import 'dart:math';

import 'package:flutter/material.dart';

import 'exam.dart' as exam_screen; // exam flow entry points
import 'home.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wordlist.dart';

/// Learning tab: every topic card opens the day-wise learning section.
class LearnTabView extends StatelessWidget {
  const LearnTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 2),
          child: UserStrip(label: 'Day-wise vocabulary practice'),
        ),
        const _TabIntro(
          title: 'Learning',
          message:
              'Each topic is split into days of 20 words. Study a day, then '
              'score 90% in that day’s exam to unlock the next one.',
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < Vocab.topics.length; i++) TopicCard(index: i),
      ],
    );
  }
}

class _TabIntro extends StatelessWidget {
  const _TabIntro({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: Pal.inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Day-wise learning section for one topic: day picker + study actions +
/// vocabulary list of the chosen day.
class LearnTopicScreen extends StatefulWidget {
  const LearnTopicScreen({super.key, required this.topicIndex});

  final int topicIndex;

  @override
  State<LearnTopicScreen> createState() => _LearnTopicScreenState();
}

class _LearnTopicScreenState extends State<LearnTopicScreen> {
  late int _day;

  @override
  void initState() {
    super.initState();
    final AppStore store = AppStore.instance;
    final Topic topic = Vocab.topics[widget.topicIndex];
    _day = store.unlockedDay(topic);
  }

  @override
  Widget build(BuildContext context) {
    final Topic topic = Vocab.topics[widget.topicIndex];
    final TopicColor accent = topicAccents[widget.topicIndex % topicAccents.length];
    final AppStore store = AppStore.instance;
    final TopicStats stats = store.statsFor(topic.id);
    final int unlocked = store.unlockedDay(topic);

    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: ListenableBuilder(
        listenable: store,
        builder: (BuildContext context, Widget? _) {
          final int masteredInDay =
              topic.itemIndexesOfDay(_day).where((i) => stats.statusOf(i) == markKnown).length;
          final int daySize = topic.itemIndexesOfDay(_day).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
            children: <Widget>[
              Text(topic.subtitle, style: const TextStyle(color: Pal.inkSoft)),
              const SizedBox(height: 14),
              // Day chips
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: topic.totalDays,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int d) {
                    final int day = d + 1;
                    final bool passed = stats.passed(day);
                    final bool isCurrent = day == _day;
                    final bool locked = day > unlocked;
                    final bool best = stats.bestFor(day) >= 90;
                    return _DayChip(
                      day: day,
                      selected: isCurrent,
                      locked: locked,
                      passed: passed || best,
                      accent: accent,
                      onTap: locked
                          ? null
                          : () => setState(() => _day = day),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              if (_day > unlocked) ...<Widget>[
                // Locked day: show the unlock path instead of content.
                SoftCard(
                  color: accent.soft,
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 6),
                      Icon(Icons.lock_clock_outlined,
                          size: 44, color: accent.main),
                      const SizedBox(height: 12),
                      Text(
                        'Day $_day is locked',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Score 90% in the Day ${_day - 1} exam to unlock '
                        'this day’s learning and exam.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Pal.inkSoft,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent.main,
                        ),
                        icon: const Icon(Icons.edit_note_outlined),
                        label: Text('Go to Day ${_day - 1} exam'),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => exam_screen.ExamStartScreen(
                              topic: topic,
                              day: _day - 1,
                            ),
                          ));
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...<Widget>[
                // Day actions
                SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Day $_day',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Pill(
                            text: '$masteredInDay/$daySize known',
                            color: accent.main,
                            soft: accent.soft,
                            icon: Icons.emoji_events_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Daily goal: ${daySize >= wordsPerDay ? '$wordsPerDay words' : 'finish remaining $daySize words'}. '
                        'Study with flashcards, then take the timed exam.',
                        style: const TextStyle(color: Pal.inkSoft, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.style_outlined),
                        label: const Text('Study Day — flashcards'),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => StudySessionScreen(
                              topic: topic,
                              day: _day,
                            ),
                          ));
                        },
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: Icon(Icons.timer_outlined, color: accent.main),
                        label: Text(stats.passed(_day)
                            ? 'Day $_day exam passed — retake'
                            : 'Take Day $_day exam'),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => exam_screen.ExamStartScreen(
                                topic: topic, day: _day),
                          ));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Day words',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap any word for its full card. Tick it when you know it.',
                  style: TextStyle(color: Pal.inkSoft, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < daySize; i++) _WordRow(
                  topic: topic,
                  itemIndex: topic.itemIndexesOfDay(_day)[i],
                  accent: accent,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.locked,
    required this.passed,
    required this.accent,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool locked;
  final bool passed;
  final TopicColor accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = locked
        ? const Color(0xFFE8E4F0)
        : selected
            ? accent.main
            : accent.soft;
    final Color fg = locked
        ? Pal.inkSoft.withOpacity(0.5)
        : selected
            ? Colors.white
            : accent.main;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent.main : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              locked
                  ? Icons.lock_outline
                  : passed
                      ? Icons.check_circle_rounded
                      : Icons.menu_book_outlined,
              size: 16,
              color: fg,
            ),
            const SizedBox(height: 3),
            Text(
              'Day $day',
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.topic,
    required this.itemIndex,
    required this.accent,
  });

  final Topic topic;
  final int itemIndex;
  final TopicColor accent;

  @override
  Widget build(BuildContext context) {
    final VocabItem item = topic.items[itemIndex];
    final AppStore store = AppStore.instance;
    final String status = store.statsFor(topic.id).statusOf(itemIndex);
    final Color statusColor = status == markKnown
        ? Pal.mint
        : status == markPractice
            ? Pal.butter
            : Pal.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        radius: 18,
        onTap: () => _showItemSheet(context, topic, itemIndex),
        child: Row(
          children: <Widget>[
            Icon(
              status == markKnown
                  ? Icons.check_circle_rounded
                  : status == markPractice
                      ? Icons.replay_rounded
                      : Icons.radio_button_unchecked,
              color: statusColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.term,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                  Text(
                    _hintFor(topic, item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Pal.inkSoft, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Pal.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }
}

String _hintFor(Topic topic, VocabItem item) {
  switch (topic.id) {
    case 'wordSmart':
    case 'gre333':
      return item.bn.isNotEmpty ? item.bn : item.term;
    default:
      return item.en.isNotEmpty ? item.en : (item.bn.isNotEmpty ? item.bn : '');
  }
}

/// Bottom sheet with the full word card and quick marking.
void _showItemSheet(BuildContext context, Topic topic, int itemIndex) {
  final VocabItem item = topic.items[itemIndex];
  final AppStore store = AppStore.instance;
  final String status = store.statsFor(topic.id).statusOf(itemIndex);
  final TopicColor accent =
      topicAccents[Vocab.topics.indexOf(topic) % topicAccents.length];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final EdgeInsets pad = MediaQuery.of(sheetContext).viewInsets;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + pad.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Pal.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              item.term,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            if (item.pos.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Center(child: Pill(text: item.pos, color: accent.main, soft: accent.soft)),
            ],
            const SizedBox(height: 16),
            _InfoBlock(label: 'Meaning', text: _hintFor(topic, item)),
            if (item.hasBn && _hintFor(topic, item) != item.bn)
              _InfoBlock(label: 'Bengali', text: item.bn),
            if (item.synonyms.isNotEmpty)
              _InfoBlock(label: 'Synonyms', text: item.synonyms.join(', ')),
            if (item.antonyms.isNotEmpty)
              _InfoBlock(label: 'Antonyms', text: item.antonyms.join(', ')),
            if (item.hasEx) _InfoBlock(label: 'Example', text: item.ex),
            if (item.theme.isNotEmpty) _InfoBlock(label: 'Theme', text: item.theme),
            if (item.bank.isNotEmpty) _InfoBlock(label: 'Asked in', text: item.bank),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      status == markPractice ? 'Needs practice' : 'Practice',
                    ),
                    onPressed: () {
                      store.markItem(topic.id, itemIndex, markPractice);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Pal.mint),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Got it'),
                    onPressed: () {
                      store.markItem(topic.id, itemIndex, markKnown);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Pal.lavender,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(text, style: const TextStyle(color: Pal.ink, height: 1.5, fontSize: 14.5)),
        ],
      ),
    );
  }
}

/// Flashcard study session for one day (or a mistake-bank selection).
class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key, required this.topic, required this.day, this.indexes});

  final Topic topic;
  final int day;
  final List<int>? indexes;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  late final List<int> _order;
  int _pos = 0;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    final List<int> source = widget.indexes ??
        widget.topic.itemIndexesOfDay(widget.day);
    _order = List<int>.of(source)..shuffle(Random());
  }

  int get _total => _order.length;

  void _answer(bool known) {
    final int idx = _order[_pos];
    AppStore.instance.markItem(widget.topic.id, idx, known ? markKnown : markPractice);
    if (_pos + 1 >= _total) {
      // Session finished.
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Day done! 🎉'),
          content: Text(
            known
                ? 'You finished all $_total words. Keep going — now try the '
                    'day exam and aim for 90%!'
                : 'You finished all $_total words — some need practice, and '
                    'that is exactly what the exam is for!',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to day'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      _pos++;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final VocabItem item = widget.topic.items[_order[_pos]];
    final int idx = _order[_pos];
    final TopicColor accent =
        topicAccents[Vocab.topics.indexOf(widget.topic) % topicAccents.length];

    return Scaffold(
      backgroundColor: accent.soft,
      appBar: AppBar(
        backgroundColor: accent.soft,
        title: Text('Day ${widget.day} · Flashcards'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            Text(
              '${_pos + 1} / $_total',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: accent.main,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_pos) / _total,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.7),
                  valueColor: AlwaysStoppedAnimation<Color>(accent.main),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // The card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: GestureDetector(
                  onTap: () => setState(() => _flipped = !_flipped),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _flipped
                        ? _CardBack(
                            key: ValueKey<int>('b$idx$_pos'),
                            topic: widget.topic,
                            item: item,
                            accent: accent,
                          )
                        : _CardFront(
                            key: ValueKey<int>('f$idx$_pos'),
                            item: item,
                            accent: accent,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Pal.butter, width: 1.6),
                        foregroundColor: Pal.butter,
                      ),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Practice'),
                      onPressed: () => _answer(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Pal.mint),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Got it'),
                      onPressed: () => _answer(true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _flipped
                  ? 'Tap the card to flip back'
                  : 'Tap the card to reveal the meaning',
              style: TextStyle(color: accent.main.withOpacity(0.8), fontSize: 12.5),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({super.key, required this.item, required this.accent});

  final VocabItem item;
  final TopicColor accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: softShadow,
      ),
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'WORD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Pal.inkSoft,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            item.term,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Pal.ink,
            ),
          ),
          const SizedBox(height: 14),
          if (item.pos.isNotEmpty)
            Pill(text: item.pos, color: accent.main, soft: accent.soft),
          if (item.theme.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Pill(text: item.theme, color: Pal.sky, soft: Pal.skySoft),
          ],
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    super.key,
    required this.topic,
    required this.item,
    required this.accent,
  });

  final Topic topic;
  final VocabItem item;
  final TopicColor accent;

  @override
  Widget build(BuildContext context) {
    final String meaning = _hintFor(topic, item);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: softShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.term,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Pal.ink,
              ),
            ),
            const SizedBox(height: 10),
            _BackRow('Meaning', meaning, accent.main),
            if (item.hasBn && meaning != item.bn) _BackRow('Bengali', item.bn, Pal.sky),
            if (item.synonyms.isNotEmpty)
              _BackRow('Synonyms', item.synonyms.join(', '), Pal.mint),
            if (item.antonyms.isNotEmpty)
              _BackRow('Antonyms', item.antonyms.join(', '), Pal.blush),
            if (item.hasEx) _BackRow('Example', item.ex, Pal.inkSoft),
            if (item.bank.isNotEmpty) _BackRow('Asked in', item.bank, Pal.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow(this.label, this.text, this.color);

  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: const TextStyle(color: Pal.ink, height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
