import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IconService {
  static const _channel = MethodChannel('app.icon/change');
  static const _key = 'selected_icon';

  static Future<void> changeIcon(int index) async {
    await _channel.invokeMethod('changeIcon', index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }

  static Future<int> getIcon() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }
}