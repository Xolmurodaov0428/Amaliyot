import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/setting/setting_appbar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool push = true;
  bool chat = false;
  bool tasks = true;
  bool attendance = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      push = prefs.getBool('push') ?? true;
      chat = prefs.getBool('email') ?? false;
      tasks = prefs.getBool('tasks') ?? true;
      attendance = prefs.getBool('attendance') ?? true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(title: "Bildirishnomalar"),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _tile("Push bildirishnoma", push, (v) {
                  setState(() => push = v);
                  _save('push', v);
                }),

                _tile("Chat bildirishnoma", chat, (v) {
                  setState(() => chat = v);
                  _save('email', v);
                }),

                const SizedBox(height: 20),

                const Text("Maxsus bildirishnomalar",
                    style: TextStyle(fontWeight: FontWeight.bold)),

                _tile("Topshiriqlar", tasks, (v) {
                  setState(() => tasks = v);
                  _save('tasks', v);
                }),

                _tile("Davomat", attendance, (v) {
                  setState(() => attendance = v);
                  _save('attendance', v);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        title: Text(title),
        onChanged: onChanged,
      ),
    );
  }
}