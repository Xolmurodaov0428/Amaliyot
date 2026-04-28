import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_amaliyot_app/app/app.dart';
import 'package:student_amaliyot_app/screens/profile_screen.dart';
import 'package:student_amaliyot_app/screens/setting/about_app_screen.dart';
import 'package:student_amaliyot_app/screens/setting/connect_screen.dart';
import 'package:student_amaliyot_app/screens/setting/language_screen.dart';
import 'package:student_amaliyot_app/screens/setting/security_screen.dart';

import 'login_screen.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String _getLanguageName(String code) {
    switch (code) {
      case 'uz':
        return "O'zbek tili";
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'qr':
        return 'Qaraqalpaq';
      case 'uzc':
        return 'Ўзбек тили';
      default:
        return "O'zbek tili";
    }
  }

  Future<void> showLanguageSheet(BuildContext context) async {
    final appState = MyApp.of(context);
    final currentLanguage = appState?.languageCode ?? 'uz';

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => LanguageSheet(
        selectedLanguageCode: currentLanguage,
      ),
    );

    if (result != null && result != currentLanguage) {
      await appState?.changeLanguage(result);

      if (!mounted) return;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = MyApp.of(context)?.languageCode ?? 'uz';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel(label: 'Hisob va Xavfsizlik'),
              _SettingTile(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF6C63FF),
                iconBg: const Color(0xFFEDE9FF),
                title: 'Profil',
                subtitle: 'Ma\'lumotlaringizni tahrirlang',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AkkountPage(),
                    ),
                  );
                },
              ),
              _SettingTile(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF00B4D8),
                iconBg: const Color(0xFFE0F7FC),
                title: 'Xavfsizlik',
                subtitle: 'Parol va autentifikatsiya',
                onTap: () {
                  // SecurityScreen ochiladi
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SecurityScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              const _SectionLabel(label: 'Ilova sozlamalari'),
              _SettingTile(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF43AA8B),
                iconBg: const Color(0xFFE6F7F2),
                title: 'Til',
                subtitle: _getLanguageName(appLanguage),
                onTap: () {
                  showLanguageSheet(context);
                },
              ),
              _SettingTile(
                icon: Icons.notifications_none_rounded,
                iconColor: const Color(0xFFF4A261),
                iconBg: const Color(0xFFFFF3E8),
                title: 'Bildirishnomalar',
                subtitle: 'Push va email xabarnomalar',
                onTap: () {
                  // NotificationsScreen ochiladi
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactScreen(),
                    ),
                  );
                },
              ),
              _SettingTile(
                icon: Icons.palette_outlined,
                iconColor: const Color(0xFFE63946),
                iconBg: const Color(0xFFFFECEE),
                title: 'Ko\'rinish',
                subtitle: 'Mavzu va rang sxemasi',
                onTap: () {
                  // AppearanceScreen ochiladi
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              const _SectionLabel(label: 'Boshqa'),
              _SettingTile(
                icon: Icons.support_agent,
                iconColor: const Color(0xFF8338EC),
                iconBg: const Color(0xFFF1E9FD),
                title: 'Bog\'lanish',
                subtitle: 'Savollar va muammolar bo\'yicha yordam',
                onTap: () {
                  // Bog'lanish sahifasi yoki dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactScreen(),
                    ),
                  );
                },
              ),
              _SettingTile(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF8338EC),
                iconBg: const Color(0xFFF1E9FD),
                title: 'Ilova haqida',
                subtitle: 'Versiya, litsenziya va aloqa',
                onTap: () {
                  // AboutAppScreen ochiladi
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutAppScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();

                    // 🔥 tokenni o‘chiramiz
                    await prefs.remove('token');

                    if (!mounted) return;

                    // 🔥 login sahifaga qaytish (barcha oldingi sahifalarni o‘chiradi)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                          (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE63946),
                    size: 20,
                  ),
                  label: const Text(
                    'Chiqish',
                    style: TextStyle(
                      color: Color(0xFFE63946),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFFE63946),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9B9BB4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9B9BB4),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFCCCCDD),
          size: 22,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}