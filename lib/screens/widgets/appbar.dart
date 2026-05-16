import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/api_config.dart';
import '../../constants/app_colors.dart';
import '../profile_screen.dart';
import '../notifications_page.dart';

class AppBarPage extends StatefulWidget {
  final String title;
  final String? userInitials;
  final VoidCallback? onLanguageTap;

  const AppBarPage({
    required this.title,
    this.userInitials,
    this.onLanguageTap,
    super.key,
  });

  @override
  State<AppBarPage> createState() => _AppBarPageState();
}

class _AppBarPageState extends State<AppBarPage> {
  Uint8List? avatarBytes;
  int _unreadCount = 0;
  final http.Client _httpClient = http.Client();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _loadUnreadCount();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadUnreadCount(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _httpClient.close();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final bytes = await AvatarService.loadImageBytes();
    if (!mounted) return;
    setState(() => avatarBytes = bytes);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return;

      final response = await _httpClient.get(
        ApiConfig.uri('notifications/unread-count'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final data = body['data'];
          final count = data is Map
              ? int.tryParse(
                      (data['unread_count'] ?? 0).toString()) ??
                  0
              : 0;
          setState(() => _unreadCount = count);
        }
      }
    } catch (_) {}
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AkkountPage()),
    ).then((_) => _loadAvatar());
  }

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    ).then((_) => _loadUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.accentPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔔 Notification button
          Positioned(
            right: 8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 33,
                  ),
                  onPressed: () => _openNotifications(context),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 18, minHeight: 18),
                      child: Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 📝 Title
          Center(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 👤 Avatar
          Positioned(
            left: 8,
            child: GestureDetector(
              onTap: () => _openProfile(context),
              child: Hero(
                tag: 'profile_avatar',
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: avatarBytes != null
                    // ✅ Foydalanuvchi o'z rasmini qo'ygan bo'lsa
                        ? Image.memory(
                      avatarBytes!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    )
                    // ✅ Rasm yo'q bo'lsa — SVG ikonka ko'rsatiladi
                        : SvgPicture.asset(
                      'assets/images/icon_TunKoki_round.svg',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}