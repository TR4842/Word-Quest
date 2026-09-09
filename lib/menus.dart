import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'widgets.dart';

/// About section — app details, developer details and credits.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $text')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
        children: <Widget>[
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 116,
              height: 116,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Pal.lavenderSoft, Pal.blushSoft],
                ),
              ),
              child: ClipOval(
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Word Quest',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Offline vocabulary learning app · v1.0.0',
              style: TextStyle(color: Pal.inkSoft, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          const SoftCard(
            child: Text(
              'Master the words that matter — completely offline. Word Quest '
              'bundles Word Smart 1, GRE 333 high-frequency vocabulary, '
              'important previous-year bank vocabulary, one word '
              'substitutions and idioms & phrases. Learn at least 20 words a '
              'day, then prove yourself with a timed day-wise exam. Score '
              '90% or more to unlock the next day. No internet, no ads, no '
              'text-to-speech — just focused practice.',
              style: TextStyle(height: 1.55, color: Pal.inkSoft),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Developer'),
          const SoftCard(
            padding: EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                _DevAvatar(initials: 'TR'),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tanvir Rahman',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Barishal, Bangladesh',
                        style: TextStyle(color: Pal.inkSoft),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '🟢 Passionate about learning new things.\n'
                        '🟡 Curious mind.\n'
                        '🔵 Love to travel.',
                        style: TextStyle(color: Pal.inkSoft, height: 1.5, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code, color: Pal.lavender),
              title: const Text('GitHub', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('github.com/TR4842/Word-Quest'),
              trailing: const Icon(Icons.copy_rounded, color: Pal.inkSoft, size: 18),
              onTap: () => _copy(context, 'https://github.com/TR4842/Word-Quest'),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Word lists'),
          const SoftCard(
            child: Column(
              children: <Widget>[
                _ListRow(text: 'Word Smart 1 — 793 words'),
                _ListRow(text: 'GRE 333 — 406 high-frequency words'),
                _ListRow(text: 'Previous-year bank vocab — 162 words'),
                _ListRow(text: 'One word substitutions — 1,001 items'),
                _ListRow(text: 'Idioms & phrases — 475 items', last: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Made with'),
          const SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ListRow(
                  text: 'Flutter — one codebase, native Android app',
                ),
                _ListRow(
                  text: 'flutter_lints · Material 3 pastel design',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'Licensed under the MIT License\n© 2026 Tanvir Rahman',
              textAlign: TextAlign.center,
              style: TextStyle(color: Pal.inkSoft, fontSize: 12.5, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Pal.lavender,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DevAvatar extends StatelessWidget {
  const _DevAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Pal.lavender, Pal.blush],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.text, this.last = false});

  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, size: 17, color: Pal.mint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Pal.inkSoft, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
