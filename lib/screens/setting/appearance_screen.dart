import 'package:flutter/material.dart';
import 'package:student_amaliyot_app/app/app.dart';
import 'package:student_amaliyot_app/services/theme_service.dart';

import '../widgets/setting/setting_appbar.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  String _theme = 'light';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final t = await ThemeService.getTheme();
    if (!mounted) return;
    setState(() => _theme = t);
  }

  Future<void> _changeTheme(String value) async {
    await ThemeService.saveTheme(value);
    setState(() => _theme = value);

    // 🔥 real-time change
    MyApp.of(context)?.changeTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(title: "Ko‘rinish"),
          RadioListTile(
            value: 'light',
            groupValue: _theme,
            title: const Text("Yorug‘ (Light)"),
            onChanged: (v) => _changeTheme(v!),
          ),
          RadioListTile(
            value: 'dark',
            groupValue: _theme,
            title: const Text("Qorong‘i (Dark)"),
            onChanged: (v) => _changeTheme(v!),
          ),
          RadioListTile(
            value: 'system',
            groupValue: _theme,
            title: const Text("Tizim bilan bir xil"),
            onChanged: (v) => _changeTheme(v!),
          ),
        ],
      ),
    );
  }
}