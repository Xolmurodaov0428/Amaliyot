import 'package:flutter/material.dart';

import '../widgets/setting/setting_appbar.dart';


class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomAppBar(title: "Bog‘lanish"),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: Color(0xFF4F46E5),
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Amaliyot tizimi",
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Versiya: 1.0.0",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    const _SectionTitle("📌 Ilova maqsadi"),
                    const _InfoText(
                      "Ushbu ilova talabalar amaliyot jarayonini raqamlashtirish, nazorat qilish va qulay boshqarish uchun yaratilgan.",
                    ),

                    const SizedBox(height: 16),

                    const _SectionTitle("🎓 Talaba imkoniyatlari"),
                    const _TechItem("Profil ma’lumotlarini ko‘rish"),
                    const _TechItem("Amaliyot muddati va faol kunlarni kuzatish"),
                    const _TechItem("Davomat holatini tekshirish"),
                    const _TechItem("Topshiriqlarni ko‘rish va bajarish"),
                    const _TechItem("Hujjatlarni yuklash va ko‘rish"),

                    const SizedBox(height: 16),

                    const _SectionTitle("⚙️ Texnologiyalar"),
                    const _TechItem("Flutter"),
                    const _TechItem("Laravel"),
                    const _TechItem("MySQL"),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        "© $currentYear Amaliyot tizimi",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
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

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String text;

  const _InfoText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 14,
        height: 1.6,
      ),
    );
  }
}

class _TechItem extends StatelessWidget {
  final String text;

  const _TechItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Color(0xFF4F46E5),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}