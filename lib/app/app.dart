import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  Locale get _locale {
    switch (_languageCode) {
      case 'uzc': return const Locale('uz');
      case 'qr':  return const Locale('kaa');
      default:    return Locale(_languageCode);
    }
  }

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

      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uz'),
        Locale('en'),
        Locale('ru'),
        Locale('kaa'),
      ],

      themeMode: _themeMode,

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066CC),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE5E7EB),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066CC),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        dividerColor: const Color(0xFF334155),
        useMaterial3: true,
      ),
    );
  }
}