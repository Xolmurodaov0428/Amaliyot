import 'package:flutter/material.dart';

class LanguageSheet extends StatefulWidget {
  final String selectedLanguageCode;

  const LanguageSheet({
    super.key,
    required this.selectedLanguageCode,
  });

  @override
  State<LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<LanguageSheet> {
  late String selectedLang;

  final List<Map<String, String>> languages = const [
    {
      'code': 'uz',
      'title': "O'zbek tili",
      'flag': 'assets/flags/uz.png',
    },
    {
      'code': 'en',
      'title': 'English',
      'flag': 'assets/flags/sh.png',
    },
    {
      'code': 'ru',
      'title': 'Русский',
      'flag': 'assets/flags/ru.png',
    },
    {
      'code': 'qr',
      'title': 'Qaraqalpaq',
      'flag': 'assets/flags/qr.png',
    },
    {
      'code': 'uzc',
      'title': 'Ўзбек тили',
      'flag': 'assets/flags/uz_k.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedLang = widget.selectedLanguageCode;
  }

  void _selectLanguage(String code) {
    Navigator.pop(context, code);
  }

  Widget _buildFlag(String path) {
    return Container(
      width: 30,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 16,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tilni tanlang',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF555555),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: languages.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final code = lang['code']!;
                  final title = lang['title']!;
                  final flagPath = lang['flag']!;
                  final isSelected = selectedLang == code;

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _selectLanguage(code),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          _buildFlag(flagPath),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2A2A2A),
                              ),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF7BC67B)
                                    : const Color(0xFFD8D8D8),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                              child: CircleAvatar(
                                radius: 7,
                                backgroundColor: Color(0xFF7BC67B),
                              ),
                            )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}