import 'package:flutter/material.dart';

import 'data/settings_repo.dart';
import 'theme/themes.dart';
import 'ui/home/home_screen.dart';

class BabyCompanionApp extends StatefulWidget {
  const BabyCompanionApp({super.key});

  @override
  State<BabyCompanionApp> createState() => _BabyCompanionAppState();
}

class _BabyCompanionAppState extends State<BabyCompanionApp> {
  final _settings = SettingsRepo();
  AppTheme _theme = AppTheme.neutral;

  @override
  void initState() {
    super.initState();
    _settings.readTheme().then((t) {
      if (mounted) setState(() => _theme = t);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Companion',
      theme: themeFor(_theme),
      home: const HomeScreen(),
    );
  }
}
