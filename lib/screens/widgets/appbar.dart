import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../profile_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final bytes = await AvatarService.loadImageBytes();
    if (!mounted) return;
    setState(() => avatarBytes = bytes);
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AkkountPage()),
    ).then((_) => _loadAvatar());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
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
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 33,
              ),
              onPressed: () {},
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