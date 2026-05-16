import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/setting/setting_appbar.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Ochilmadi: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(title: "Bog'lanish"),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bog'lanish",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Savollar, texnik muammolar yoki takliflar bo'yicha murojaat qilishingiz mumkin.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),

                    const _ContactItem(
                      icon: Icons.person_rounded,
                      title: "Mas'ul",
                      value: "Shahzod Xolmurodov",
                    ),
                    _ContactItem(
                      icon: Icons.telegram,
                      title: "Telegram",
                      value: "t.me/XolmurodovShahzod",
                      onTap: () => _openUrl("https://t.me/XolmurodovShahzod"),
                    ),
                    _ContactItem(
                      icon: Icons.phone_rounded,
                      title: "Telefon",
                      value: "+998 XX XXX XX XX",
                      onTap: () => _openUrl("tel:+998XXXXXXXXX"),
                    ),
                    _ContactItem(
                      icon: Icons.email_rounded,
                      title: "Email",
                      value: "support@example.com",
                      onTap: () => _openUrl("mailto:support@example.com"),
                    ),


                    const SizedBox(height: 22),
                    Text(
                      "Murojaat mavzulari",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _TopicItem("Login yoki parol muammosi"),
                    const _TopicItem("Topshiriqlar ko'rinmasligi"),
                    const _TopicItem("Davomat xatoligi"),
                    const _TopicItem("Hujjat yuklash muammosi"),
                    const _TopicItem("Ilova bo'yicha takliflar"),

                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        "© $currentYear Amaliyot tizimi",
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFEDE9FE),
                  child: Icon(icon, color: const Color(0xFF7C3AED)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.open_in_new_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 21,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicItem extends StatelessWidget {
  const _TopicItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}