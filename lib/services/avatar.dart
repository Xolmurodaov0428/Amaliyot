import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class AvatarService {
  static const String _key = 'student_avatar_base64';

  static Future<void> saveImageBytes(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, base64Encode(bytes));
  }

  static Future<Uint8List?> loadImageBytes() async {
    final prefs = await SharedPreferences.getInstance();

    final base64Image = prefs.getString(_key);
    if (base64Image == null || base64Image.isEmpty) return null;

    try {
      return base64Decode(base64Image);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}