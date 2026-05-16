import 'package:flutter/material.dart';
import 'package:student_amaliyot_app/app/app.dart';
import 'package:student_amaliyot_app/screens/profile_screen.dart';
import 'package:student_amaliyot_app/screens/setting/about_app_screen.dart';
import 'package:student_amaliyot_app/screens/setting/appearance_screen.dart';
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

  Future<void> _confirmLogout(BuildContext context) async {
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chiqish'),
        content: const Text('Hisobdan chiqishni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await AuthService.logout();
    await AvatarService.clearImage();

    if (!mounted) return;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
                subtitle: "Ma'lumotlaringizni tahrirlang",
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
                icon: Icons.palette_outlined,
                iconColor: const Color(0xFFE63946),
                iconBg: const Color(0xFFFFECEE),
                title: "Ko'rinish",
                subtitle: 'Mavzu va rang sxemasi',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppearanceScreen(),
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
                title: "Bog'lanish",
                subtitle: "Savollar va muammolar bo'yicha yordam",
                onTap: () {
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
                  onPressed: () => _confirmLogout(context),
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.outlineVariant,
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