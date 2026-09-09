import 'package:flutter/material.dart';

import 'exam.dart' as exam_flow;
import 'exam_engine.dart' as engine;
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wordlist.dart';

/// Mistake Bank tab — wrong answers saved separately per topic.
class BankTabView extends StatefulWidget {
  const BankTabView({super.key});

  @override
  State<BankTabView> createState() => _BankTabViewState();
}

class _BankTabViewState extends State<BankTabView> {
  int? _filter; // topic index; null = all topics

  @override
  Widget build(BuildContext context) {
    final List<int> shown = <int>[
      for (int i = 0; i < Vocab.topics.length; i++)
        if (_filter == null || _filter == i) i,
    ];

    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (BuildContext context, Widget? _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: UserStrip(label: 'Your saved wrong answers'),
            ),
            const Text(
              'Mistake Bank',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Every wrong answer is saved here for review — separately for '
              'each topic. Practise them until they leave the bank!',
              style: TextStyle(color: Pal.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 14),
            // Topic filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _FilterChip(
                    label: 'All topics',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (int i = 0; i < Vocab.topics.length; i++) ...<Widget>[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: Vocab.topics[i].title,
                      selected: _filter == i,
                      onTap: () => setState(() => _filter = i),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (shown.isEmpty) const SizedBox.shrink(),
            for (final int i in shown) _TopicMistakeSection(topicIndex: i),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Pal.lavender : Pal.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Pal.lavender : Pal.border,
            width: 1.5,
          ),
          boxShadow: selected ? tinyShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : Pal.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _TopicMistakeSection extends StatelessWidget {
  const _TopicMistakeSection({super.key, required this.topicIndex});

  final int topicIndex;

  @override
  Widget build(BuildContext context) {
    final Topic topic = Vocab.topics[topicIndex];
    final TopicColor accent = topicAccents[topicIndex % topicAccents.length];
    final List<MistakeRecord> mistakes =
        AppStore.instance.mistakesFor(topic.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.soft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: accent.main,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  topic.title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${mistakes.length} saved',
                style: TextStyle(
                  color: accent.main,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (mistakes.isEmpty)
            SoftCard(
              padding: const EdgeInsets.all(14),
              radius: 18,
              color: accent.soft.withOpacity(0.6),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.sentiment_satisfied_alt_outlined,
                      color: Pal.inkSoft),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No mistakes here — keep it up!',
                      style: TextStyle(
                        color: accent.main,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent.main,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: Text('Practise ${mistakes.length}'),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => exam_flow.ExamPlayerScreen(
                          topic: topic,
                          day: 0,
                          questionCount: mistakes.length,
                          preset: <engine.ExamQuestion>[
                            for (final MistakeRecord m in mistakes) m.question,
                          ]..shuffle(),
                          practice: true,
                        ),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Pal.danger,
                    side: const BorderSide(color: Pal.danger, width: 1.4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onPressed: () => _confirmClear(context, topic.id),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final MistakeRecord m in mistakes)
              _MistakeCard(record: m, accent: accent),
          ],
        ],
      ),
    );
  }
}

Future<void> _confirmClear(BuildContext context, String topicId) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Clear mistake bank?'),
      content: const Text('All saved wrong answers for this topic will be removed.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Pal.danger),
          onPressed: () {
            AppStore.instance.clearTopicMistakes(topicId);
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Clear'),
        ),
      ],
    ),
  );
}

class _MistakeCard extends StatefulWidget {
  const _MistakeCard({required this.record, required this.accent});

  final MistakeRecord record;
  final TopicColor accent;

  @override
  State<_MistakeCard> createState() => _MistakeCardState();
}

class _MistakeCardState extends State<_MistakeCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final MistakeRecord r = widget.record;
    final engine.ExamQuestion q = r.question;
    final bool right = r.chosenIndex == q.correctIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () => setState(() => _open = !_open),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: <Widget>[
                  Icon(
                    right ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: right ? Pal.mint : Pal.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.term,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (r.day > 0)
                    Pill(text: 'Day ${r.day}', color: widget.accent.main, soft: widget.accent.soft),
                  const SizedBox(width: 6),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: Pal.inkSoft,
                  ),
                ],
              ),
            ),
            if (_open)
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Divider(color: Pal.border, height: 1),
                    const SizedBox(height: 10),
                    Text(
                      '${q.typeLabel} question',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: widget.accent.main,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.prompt,
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    for (int i = 0; i < q.options.length; i++)
                      _reviewOption(
                        text: q.options[i],
                        isCorrect: i == q.correctIndex,
                        isChosen: i == r.chosenIndex,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Answered ${r.day > 0 ? 'on Day ${r.day}' : 'in practice'}',
                            style: const TextStyle(
                              color: Pal.inkSoft,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Remove from bank',
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Pal.inkSoft, size: 20),
                          onPressed: () => AppStore.instance
                              .removeMistake(r.topicId, r.id),
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

Widget _reviewOption({
  required String text,
  required bool isCorrect,
  required bool isChosen,
}) {
  Color bg = Pal.card;
  Color fg = Pal.ink;
  Color border = Pal.border;
  IconData? icon;
  if (isCorrect) {
    bg = Pal.mintSoft;
    border = Pal.mint;
    icon = Icons.check_rounded;
    fg = Pal.ink;
  } else if (isChosen) {
    bg = Pal.blushSoft;
    border = Pal.blush;
    icon = Icons.close_rounded;
    fg = Pal.ink;
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.3),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: fg),
            ),
          ),
          if (icon != null)
            Icon(icon,
                size: 17, color: isCorrect ? Pal.mint : Pal.danger),
        ],
      ),
    ),
  );
}
