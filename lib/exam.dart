import 'dart:async';

import 'package:flutter/material.dart';

import 'exam_engine.dart' as engine;
import 'home.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wordlist.dart';

/// Exam tab: pick a topic then a day exam.
class ExamTabView extends StatelessWidget {
  const ExamTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 2),
          child: UserStrip(label: 'Timed day-wise exams'),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Exams',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'Each topic has its own day-wise exam. The syllabus is exactly '
                'that day’s learning goal. Score 90% to unlock the next day.',
                style: TextStyle(color: Pal.inkSoft, height: 1.5),
              ),
            ],
          ),
        ),
        for (int i = 0; i < Vocab.topics.length; i++)
          TopicCard(index: i, examMode: true),
      ],
    );
  }
}

/// Day-wise exam section of one topic.
class ExamTopicScreen extends StatelessWidget {
  const ExamTopicScreen({super.key, required this.topicIndex});

  final int topicIndex;

  @override
  Widget build(BuildContext context) {
    final Topic topic = Vocab.topics[topicIndex];
    final TopicColor accent = topicAccents[topicIndex % topicAccents.length];
    final AppStore store = AppStore.instance;
    final TopicStats stats = store.statsFor(topic.id);
    final int unlocked = store.unlockedDay(topic);

    return Scaffold(
      appBar: AppBar(title: Text('${topic.title} · Exams')),
      body: ListenableBuilder(
        listenable: store,
        builder: (BuildContext context, Widget? _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Pill(
                      text: '${stats.passedDays.length}/${topic.totalDays} days passed',
                      color: accent.main,
                      soft: accent.soft,
                      icon: Icons.flag_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Pill(
                      text: 'Pass mark: 90%',
                      color: Pal.blush,
                      soft: Pal.blushSoft,
                      icon: Icons.gpp_good_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SoftCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.quiz_outlined, color: accent.main),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'How day exams work',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose 20, 25 or 30 questions. The timer runs for half '
                      'that many minutes (20 questions → 10 minutes). Every '
                      'attempt shuffles the questions and options. Wrong '
                      'answers go to your mistake bank.',
                      style: TextStyle(color: Pal.inkSoft, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Days',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'A day unlocks after you pass the previous day’s exam.',
                style: TextStyle(color: Pal.inkSoft, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              for (int d = 1; d <= topic.totalDays; d++)
                _DayExamRow(
                  topic: topic,
                  day: d,
                  locked: d > unlocked,
                  accent: accent,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DayExamRow extends StatelessWidget {
  const _DayExamRow({
    required this.topic,
    required this.day,
    required this.locked,
    required this.accent,
  });

  final Topic topic;
  final int day;
  final bool locked;
  final TopicColor accent;

  @override
  Widget build(BuildContext context) {
    final TopicStats stats = AppStore.instance.statsFor(topic.id);
    final bool passed = stats.passed(day);
    final int best = stats.bestFor(day);
    final int words = topic.itemIndexesOfDay(day).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: locked ? const Color(0xFFE9E5F2) : accent.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                locked
                    ? Icons.lock_outline
                    : passed
                        ? Icons.emoji_events_rounded
                        : Icons.edit_note_outlined,
                color: locked ? fade(Pal.inkSoft, 0.5) : accent.main,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Day $day · $words words',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locked
                        ? 'Pass Day ${day - 1} with 90% to unlock'
                        : passed
                            ? 'Passed ✓  Best $best%'
                            : best > 0
                                ? 'Best attempt: $best%  · need 90%'
                                : 'Not attempted yet',
                    style: const TextStyle(color: Pal.inkSoft, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: locked ? fade(Pal.inkSoft, 0.25) : accent.main,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: locked
                  ? null
                  : () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => ExamStartScreen(topic: topic, day: day),
                      ));
                    },
              child: Text(passed ? 'Retake' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-exam screen: choose the number of questions (20/25/30).
class ExamStartScreen extends StatefulWidget {
  const ExamStartScreen({super.key, required this.topic, required this.day});

  final Topic topic;
  final int day;

  @override
  State<ExamStartScreen> createState() => _ExamStartScreenState();
}

class _ExamStartScreenState extends State<ExamStartScreen> {
  int _count = 20;

  @override
  Widget build(BuildContext context) {
    final Topic topic = widget.topic;
    final TopicColor accent =
        topicAccents[Vocab.topics.indexOf(topic) % topicAccents.length];
    final int minutes = _count ~/ 2;
    final int threshold = engine.passThreshold(_count);

    return Scaffold(
      appBar: AppBar(title: Text('Day ${widget.day} exam')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  Text(
                    'Day ${widget.day} · ${topic.title}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Syllabus: the ${topic.itemIndexesOfDay(widget.day).length} words '
                    'you learned today',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Pal.inkSoft, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Number of questions',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                for (final int n in const <int>[20, 25, 30]) ...<Widget>[
                  Expanded(
                    child: _CountChoice(
                      count: n,
                      selected: _count == n,
                      accent: accent,
                      onTap: () => setState(() => _count = n),
                    ),
                  ),
                  if (n != 30) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.soft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.timer_outlined, color: accent.main),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '$_count questions · $minutes minutes',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Time = half of the questions · pass at 90% accuracy',
                          style: TextStyle(color: Pal.inkSoft, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need $threshold of $_count correct to pass and unlock '
              'Day ${widget.day + 1}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Pal.inkSoft, fontSize: 13),
            ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start exam'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ExamPlayerScreen(
                    topic: topic,
                    day: widget.day,
                    questionCount: _count,
                  ),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChoice extends StatelessWidget {
  const _CountChoice({
    required this.count,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final TopicColor accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? accent.main : Pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent.main : Pal.border,
            width: 2,
          ),
          boxShadow: selected ? tinyShadow : null,
        ),
        child: Column(
          children: <Widget>[
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Pal.ink,
              ),
            ),
            Text(
              'questions',
              style: TextStyle(
                fontSize: 11.5,
                color: selected ? fade(Colors.white, 0.9) : Pal.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The timed exam player. With [preset] questions and [practice] = true it
/// runs as an untimed practice session driven from the mistake bank.
class ExamPlayerScreen extends StatefulWidget {
  const ExamPlayerScreen({
    super.key,
    required this.topic,
    required this.day,
    required this.questionCount,
    this.preset,
    this.practice = false,
  });

  final Topic topic;
  final int day;
  final int questionCount;
  final List<engine.ExamQuestion>? preset;
  final bool practice;

  @override
  State<ExamPlayerScreen> createState() => _ExamPlayerScreenState();
}

class _ExamPlayerScreenState extends State<ExamPlayerScreen> {
  late final List<engine.ExamQuestion> _questions;
  late final List<int?> _answers;
  int _pos = 0;
  late int _remainingSeconds;
  Timer? _timer;
  bool _locked = false; // short lock after answering / when finishing
  bool _finished = false;

  TopicColor get _accent =>
      topicAccents[Vocab.topics.indexOf(widget.topic) % topicAccents.length];

  @override
  void initState() {
    super.initState();
    _questions = widget.preset ??
        engine.buildExam(
          topic: widget.topic,
          day: widget.day,
          count: widget.questionCount,
        );
    _answers = List<int?>.filled(_questions.length, null);
    _remainingSeconds =
        widget.practice ? 0 : engine.examDurationSeconds(_questions.length);
    if (!widget.practice) {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (!mounted) return;
        setState(() {
          if (_remainingSeconds > 0) _remainingSeconds--;
        });
        if (_remainingSeconds <= 0) _finish();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _confirmExit() async {
    final bool leave = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Leave the exam?'),
            content: const Text(
              'Your answers so far will be lost and this attempt will not be '
              'recorded.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep going'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Pal.danger),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
    if (!leave || !mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _answer(int optionIndex) {
    if (_locked) return;
    final int i = _pos;
    if (_answers[i] != null) return;
    setState(() => _answers[i] = optionIndex);
    _locked = true;
    if (widget.practice && optionIndex == _questions[i].correctIndex) {
      AppStore.instance.reviewMistakeSolved(widget.topic.id, _questions[i]);
    }
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (_pos + 1 >= _questions.length) {
        _finish();
      } else {
        setState(() {
          _pos++;
          _locked = false;
        });
      }
    });
  }

  void _finish() {
    if (!mounted || _finished) return;
    _finished = true;
    _timer?.cancel();
    final List<engine.ExamQuestion> qs = _questions;
    final List<int?> answers = _answers;

    int correct = 0;
    for (int i = 0; i < qs.length; i++) {
      final int? chosen = answers[i];
      if (chosen != null && chosen == qs[i].correctIndex) {
        correct++;
      } else if (chosen != null && !widget.practice) {
        AppStore.instance.addMistake(
          topicId: widget.topic.id,
          day: widget.day,
          question: qs[i],
          chosenIndex: chosen,
        );
      }
    }

    // Untimed practice (mistake bank): show a short summary and pop back.
    if (widget.practice) {
      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Practice done!'),
          content: Text(
            'You answered $correct of ${qs.length} correctly.\n'
            'Correctly solved questions were removed from the mistake bank.',
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // back to the mistake bank
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
      return;
    }

    final int total = qs.length;
    final int percent = total == 0 ? 0 : ((correct * 100) / total).round();
    final bool passed = AppStore.instance.recordExam(
      topicId: widget.topic.id,
      day: widget.day,
      correct: correct,
      total: total,
    );
    final bool newUnlock = passed &&
        widget.day + 1 <= widget.topic.totalDays &&
        !AppStore.instance.statsFor(widget.topic.id).passed(widget.day + 1);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => ExamResultScreen(
        topic: widget.topic,
        day: widget.day,
        questions: qs,
        answers: answers,
        correct: correct,
        total: total,
        percent: percent,
        passed: passed,
        newDayUnlocked: newUnlock,
      ),
    ));
  }

  String get _clock {
    final int m = _remainingSeconds ~/ 60;
    final int s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final engine.ExamQuestion q = _questions[_pos];
    final int? chosen = _answers[_pos];

    return Scaffold(
      backgroundColor: Pal.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Exit exam',
          onPressed: _confirmExit,
        ),
        title: Text(
          widget.practice ? 'Mistake practice' : 'Day ${widget.day} exam',
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: widget.practice
                ? const Pill(
                    text: 'PRACTICE · untimed',
                    color: Pal.mint,
                    soft: Pal.mintSoft,
                    icon: Icons.replay_rounded,
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _remainingSeconds <= 60
                          ? Pal.blushSoft
                          : Pal.lavenderSoft,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.timer_outlined,
                          size: 17,
                          color: _remainingSeconds <= 60
                              ? Pal.danger
                              : Pal.lavender,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _clock,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _remainingSeconds <= 60
                                ? Pal.danger
                                : Pal.lavender,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_pos + 1) / _questions.length,
                    minHeight: 8,
                    backgroundColor: Pal.border,
                    valueColor: AlwaysStoppedAnimation<Color?>(_accent.main),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Question ${_pos + 1} of ${_questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${_answers.where((a) => a != null).length} answered',
                      style: const TextStyle(color: Pal.inkSoft, fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SoftCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Pill(
                          text: q.typeLabel,
                          color: _accent.main,
                          soft: _accent.soft,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q.prompt,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (int i = 0; i < q.options.length; i++)
                          _OptionTile(
                            option: q.options[i],
                            index: i,
                            correctIndex: q.correctIndex,
                            chosen: chosen,
                            accent: _accent,
                            onTap: () => _answer(i),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.index,
    required this.correctIndex,
    required this.chosen,
    required this.accent,
    required this.onTap,
  });

  final String option;
  final int index;
  final int correctIndex;
  final int? chosen;
  final TopicColor accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const String letters = 'ABCD';
    final bool revealed = chosen != null;
    final bool isCorrect = index == correctIndex;
    final bool isChosen = index == chosen;

    Color bg = Pal.card;
    Color fg = Pal.ink;
    IconData? trailing;
    Color borderColor = Pal.border;

    if (revealed) {
      if (isCorrect) {
        bg = Pal.mintSoft;
        fg = Pal.ink;
        borderColor = Pal.mint;
        trailing = Icons.check_circle_rounded;
      } else if (isChosen) {
        bg = Pal.blushSoft;
        fg = Pal.ink;
        borderColor = Pal.blush;
        trailing = Icons.cancel_rounded;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: revealed ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: revealed && isCorrect ? Pal.mint : accent.soft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letters[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: revealed && isCorrect ? Colors.white : accent.main,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                if (trailing != null)
                  Icon(trailing, color: isCorrect ? Pal.mint : Pal.blush, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Result + full answer review.
class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({
    super.key,
    required this.topic,
    required this.day,
    required this.questions,
    required this.answers,
    required this.correct,
    required this.total,
    required this.percent,
    required this.passed,
    required this.newDayUnlocked,
  });

  final Topic topic;
  final int day;
  final List<engine.ExamQuestion> questions;
  final List<int?> answers;
  final int correct;
  final int total;
  final int percent;
  final bool passed;
  final bool newDayUnlocked;

  @override
  Widget build(BuildContext context) {
    final TopicColor accent =
        topicAccents[Vocab.topics.indexOf(topic) % topicAccents.length];
    final bool pass = passed || percent >= 90;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Result'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        children: <Widget>[
          // Score circle
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Pal.card,
                boxShadow: softShadow,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: pass ? Pal.mint : Pal.danger,
                    ),
                  ),
                  Text(
                    '$correct / $total correct',
                    style: const TextStyle(color: Pal.inkSoft, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              pass
                  ? (newDayUnlocked
                      ? '🎉 Passed! Day ${day + 1} is unlocked.'
                      : '🎉 Passed!')
                  : 'Not yet — you need 90% to pass.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Day $day · ${topic.title}',
              style: const TextStyle(color: Pal.inkSoft),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retake'),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                      builder: (_) => ExamPlayerScreen(
                        topic: topic,
                        day: day,
                        questionCount: total,
                      ),
                    ));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: pass ? Pal.mint : accent.main,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to topic'),
                  onPressed: () {
                    // Result -> ExamStart -> ExamTopicScreen.
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Answer review',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Wrong answers have been saved to your mistake bank.',
            style: TextStyle(color: Pal.inkSoft, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < questions.length; i++)
            _ReviewCard(
              number: i + 1,
              question: questions[i],
              chosen: answers[i],
              accent: accent,
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.number,
    required this.question,
    required this.chosen,
    required this.accent,
  });

  final int number;
  final engine.ExamQuestion question;
  final int? chosen;
  final TopicColor accent;

  @override
  Widget build(BuildContext context) {
    final bool wasRight = chosen == question.correctIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: wasRight ? Pal.mintSoft : Pal.blushSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    wasRight ? Icons.check_rounded : Icons.close_rounded,
                    size: 15,
                    color: wasRight ? Pal.mint : Pal.blush,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Q$number · ${question.typeLabel} · “${question.term}”',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question.prompt,
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 8),
            Text(
              'Answer: ${question.correctAnswer}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: wasRight ? Pal.mint : accent.main,
              ),
            ),
            if (chosen != null && !wasRight)
              Text(
                'You picked: ${question.options[chosen!]}',
                style: const TextStyle(fontSize: 13, color: Pal.danger),
              ),
          ],
        ),
      ),
    );
  }
}
