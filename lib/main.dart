import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'onboarding.dart';
import 'store.dart';
import 'theme.dart';
import 'wordlist.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Offline word bank from the bundled asset (no network required).
  await Vocab.load();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  AppStore.init(prefs);
  runApp(const WordQuestApp());
}

class WordQuestApp extends StatelessWidget {
  const WordQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          title: 'Word Quest',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: AppStore.instance.hasProfile
              ? const HomeShell()
              : const WelcomePage(),
        );
      },
    );
  }
}
