import 'package:flutter/material.dart';
import 'kundalik_screen.dart';
import 'shartnoma_screen.dart';

class FaoliyatPage extends StatelessWidget {
  const FaoliyatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD), // Juda och toza fon
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    // Indicatorni butunlay qoplaydigan qilish
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: Colors.orange[800],
                    unselectedLabelColor: Colors.grey[500],
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Inter', // Agar fontingiz bo'lsa
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: "Kundalik"),
                      Tab(text: "Hujjatlar"),
                      // Tab(text: "Rasimlar"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Asosiy kontent
              const Expanded(
                child: TabBarView(
                  // Fizik effekt qo'shish (Bounce)
                  physics: BouncingScrollPhysics(),
                  children: [
                    KundalikScreen(),
                    ShartnomaScreen(),
                    // RasimlarScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}