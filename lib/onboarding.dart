import 'package:flutter/material.dart';

import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

/// First-run welcome: asks for the user's name and gender. Saving the entry
/// automatically closes the page and reveals the dashboard.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final TextEditingController _name = TextEditingController();
  String _gender = 'male';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name first.')),
      );
      return;
    }
    setState(() => _saving = true);
    // Persist (fire-and-forget); the store notifies listeners and the app
    // swaps to the dashboard, i.e. the popup auto-closes after saving.
    AppStore.instance.saveProfile(name: name, gender: _gender);
  }

  @override
  Widget build(BuildContext context) {
    final bool saving = _saving;
    return Scaffold(
      backgroundColor: Pal.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SoftCard(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Logo + title
                    Center(
                      child: Container(
                        width: 108,
                        height: 108,
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[Pal.lavenderSoft, Pal.blushSoft],
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Welcome to Word Quest!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Pal.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tell us a little about yourself so we can personalise '
                      'your vocabulary journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Pal.inkSoft, height: 1.45),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _name,
                      enabled: !saving,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 24,
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        prefixIcon: Icon(Icons.person_outline, color: Pal.lavender),
                        counterText: '',
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'I am a …',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Pal.ink),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _GenderCard(
                            gender: 'male',
                            label: 'Male',
                            selected: _gender == 'male',
                            onTap: saving
                                ? null
                                : () => setState(() => _gender = 'male'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GenderCard(
                            gender: 'female',
                            label: 'Female',
                            selected: _gender == 'female',
                            onTap: saving
                                ? null
                                : () => setState(() => _gender = 'female'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: saving ? null : _save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.rocket_launch_outlined),
                      label: Text(saving ? 'Getting ready…' : 'Start learning'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.gender,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String gender;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Pal.lavenderSoft : Pal.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Pal.lavender : Pal.border,
            width: selected ? 2 : 1.4,
          ),
          boxShadow: selected ? tinyShadow : null,
        ),
        child: Column(
          children: <Widget>[
            Avatar(gender: gender, size: 56),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? Pal.lavender : Pal.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
