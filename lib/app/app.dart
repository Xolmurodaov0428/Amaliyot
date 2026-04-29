import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/theme_service.dart';
import '../utils/tools/app_router.dart';

class MyApp extends StatefulWidget {
  final String initialLanguageCode;

  const MyApp({
    super.key,
    required this.initialLanguageCode,
  });

  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late String _languageCode;
  ThemeMode _themeMode = ThemeMode.light;

  String get languageCode => _languageCode;

  @override
  void initState() {
    super.initState();
    _languageCode = widget.initialLanguageCode;
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.getTheme();
    if (!mounted) return;

    setState(() {
      _themeMode = ThemeService.getThemeMode(theme);
    });
  }

  Future<void> changeTheme(String theme) async {
    await ThemeService.saveTheme(theme);

    if (!mounted) return;

    setState(() {
      _themeMode = ThemeService.getThemeMode(theme);
    });
  }

  Future<void> changeLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);

    if (!mounted) return;

    setState(() {
      _languageCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: RouteName.login,
      onGenerateRoute: AppRouter.generateRoute,
      title: "Amaliyot",

      themeMode: _themeMode,

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}