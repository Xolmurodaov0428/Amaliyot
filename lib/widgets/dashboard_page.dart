import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/profile_screen.dart';
// ============= COLOR CONSTANTS =============
class AppColors {
  static const Color primaryBlue = Color(0xFF0066cc);
  static const Color primaryDarkBlue = Color(0xFF0052a3);
  static const Color secondaryCyan = Color(0xFF00d9ff);
  static const Color successGreen = Color(0xFF10b981);
  static const Color warningOrange = Color(0xFFf59e0b);
  static const Color dangerRed = Color(0xFFef4444);
  static const Color lightGray = Color(0xFFF9FAFB);
  static const Color borderGray = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color lightBlue = Color(0xFFE6F0FF);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningLight = Color(0xFFFEF3C7);
}

// ============= MODELS =============
class TaskModel {
  final String title;
  final String status;
  final String date;
  final bool isPending;

  const TaskModel({
    required this.title,
    required this.status,
    required this.date,
    required this.isPending,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final due = json['due_date'];

    String formattedDate = '📅 Sana yo‘q';

    if (due != null) {
      final d = DateTime.parse(due.toString());
      formattedDate =
      '📅 ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    }

    return TaskModel(
      title: (json['title'] ?? 'Nomsiz topshiriq').toString(),
      status: 'Yangi',
      date: formattedDate,
      isPending: true,
    );
  }
}

class StatisticModel {
  final String value;
  final String label;
  final LinearGradient gradient;

  const StatisticModel({
    required this.value,
    required this.label,
    required this.gradient,
  });
}

// ============= MAIN PAGE =============
class StudentPortalPage extends StatefulWidget {

  const StudentPortalPage({
    Key? key,
  }) : super(key: key);

  @override
  State<StudentPortalPage> createState() => _StudentPortalPageState();
}

class _StudentPortalPageState extends State<StudentPortalPage>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late AnimationController _contentController;

  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? dashboard;
  Uint8List? avatarBytes;



  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvatar(); // 🔥 SHUNI QO‘SH
    fetchDashboard();
  }

  Future<void> _loadAvatar() async {
    final bytes = await AvatarService.loadImageBytes();
    if (!mounted) return;
    setState(() => avatarBytes = bytes);
  }
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _openOrganizationLocation() async {
    final organization = map('organization');

    final latRaw = organization['latitude'];
    final lonRaw = organization['longitude'];

    final lat = double.tryParse(latRaw?.toString() ?? '');
    final lon = double.tryParse(lonRaw?.toString() ?? '');

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokatsiya hali kiritilmagan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );

    final opened = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Maps ochilmadi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  DateTime? _parseDate(String? date) {
    if (date == null || date.isEmpty) return null;
    return DateTime.tryParse(date);
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openInternshipCalendar() async {
    final internship = map('internship');

    final activeDaysRaw = internship['active_days'];
    final activeDays = <String>{};

    if (activeDaysRaw is List) {
      activeDays.addAll(activeDaysRaw.map((e) => e.toString()));
    }

    final startDate = _parseDate(internship['start_date']?.toString()) ??
        DateTime.now();

    await showDialog(
      context: context,
      builder: (_) {
        return InternshipCalendarDialog(
          initialDate: startDate,
          activeDays: activeDays,
        );
      },
    );
  }



  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerController.forward();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _cardsController.forward();
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });
  }

  Future<void> fetchDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = 'Token topilmadi. Qayta login qiling.';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://shaxa.mycoder.uz/api/student/dashboard-student'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        setState(() {
          dashboard = Map<String, dynamic>.from(body['data']);
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = 'Sessiya tugagan. Qayta login qiling.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = body['message']?.toString() ??
              'Server xatolik qaytardi: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'API ulanish xatosi: $e';
        isLoading = false;
      });
    }
  }
  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String value(dynamic v, [String fallback = 'Kiritilmagan']) {
    if (v == null) return fallback;
    final text = v.toString();
    return text.isEmpty ? fallback : text;
  }

  Map<String, dynamic> map(String key) {
    final item = dashboard?[key];
    if (item is Map<String, dynamic>) return item;
    return {};
  }

  List<TaskModel> get tasks {
    final raw = dashboard?['tasks']; // 🔥 FIX

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return [];
  }
  List<StatisticModel> get statistics {
    final stats = map('attendance_stats');

    return [
      StatisticModel(
        value: '${value(stats['percentage'], '0')}%',
        label: 'Davomat',
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryDarkBlue],
        ),
      ),
      StatisticModel(
        value: value(stats['present'], '0'),
        label: 'Keldi',
        gradient: const LinearGradient(
          colors: [AppColors.successGreen, Color(0xFF059669)],
        ),
      ),
      StatisticModel(
        value: value(stats['absent'], '0'),
        label: 'Kelmadi',
        gradient: const LinearGradient(
          colors: [AppColors.dangerRed, Color(0xFFdc2626)],
        ),
      ),
      StatisticModel(
        value: value(stats['late'], '0'),
        label: 'Kech keldi',
        gradient: const LinearGradient(
          colors: [AppColors.warningOrange, Color(0xFFd97706)],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width < 1024;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.lightGray,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.lightGray,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.dangerRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fetchDashboard,
                  child: const Text('Qayta urinish'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: RefreshIndicator(
        onRefresh: fetchDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                _buildAnimatedHeader(),
                const SizedBox(height: 32),
                _buildAnimatedStatusCards(),
                const SizedBox(height: 32),
                _buildAnimatedContent(isMobile, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
      ),
      child: FadeTransition(
        opacity: _headerController,
        child: _buildHeaderSection(),
      ),
    );
  }

  Widget _buildHeaderSection() {
    final student = map('student');
    final group = student['group'] is Map<String, dynamic>
        ? student['group'] as Map<String, dynamic>
        : {};
    final supervisor = map('supervisor');
    final leader = map('leader');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.primaryDarkBlue],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(100),
              image: avatarBytes != null
                  ? DecorationImage(
                image: MemoryImage(avatarBytes!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: avatarBytes == null
                ? const Center(
              child: Text('👤', style: TextStyle(fontSize: 32)),
            )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value(student['full_name']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetaItem('🎓 Guruh:', value(group['name'])),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetaItem('👨‍🏫 Rahbar:', value(supervisor['name'])),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetaItem('🏢 Tashkilot Rahbari:', value(leader['name']),),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildAnimatedStatusCards() {
    return FadeTransition(
      opacity: _cardsController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _cardsController, curve: Curves.easeOut),
        ),
        child: _buildStatusCardsSection(),
      ),
    );
  }

  Widget _buildStatusCardsSection() {
    final internship = map('internship');
    final organization = map('organization');

    final activeDays = internship['active_days'];
    String firstDay = value(internship['start_date']);
    String lastDay = value(internship['end_date']);
    final today = DateTime.now().toString().substring(0, 10);

    String trailingIcon;

    if (activeDays == null) {
      trailingIcon = '📅';
    } else {
      final today = DateTime.now().toString().substring(0, 10);

      final isTodayActive = (activeDays as List).contains(today);

      trailingIcon = isTodayActive ? '✔️' : '❌';
    }

    return Column(
      children: [
        _buildStatusCard(
          icon: '📅',
          title: 'Amaliyot muddati',
          mainText: '$firstDay dan $lastDay gacha.',
          trailing: trailingIcon,
          subText: 'Jami kunlar: ${value(internship['active_days_count'], '0')}',
          iconBg: AppColors.lightBlue,
          onTap: _openInternshipCalendar,
        ),
        const SizedBox(height: 20),
        _buildStatusCard(
          icon: '📍',
          title: 'Lokatsiya',
          mainText: value(organization['name'], 'Tashkilot kiritilmagan'),
          subText: organization['latitude'] == null || organization['longitude'] == null
              ? 'Lokatsiya hali kiritilmagan'
              : 'Xaritada ko‘rish uchun bosing',
          iconBg: AppColors.lightBlue,
          trailing: organization['latitude'] == null || organization['longitude'] == null
              ? '❌'
              : '📍',
          onTap: _openOrganizationLocation,
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String icon,
    required String title,
    required String mainText,
    required String subText,
    required Color iconBg,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ??
                () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title - $mainText'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primaryBlue,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.secondaryCyan],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mainText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (trailing != null)
                              Text(
                                trailing,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContent(bool isMobile, bool isTablet) {
    return FadeTransition(
      opacity: _contentController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
        ),
        child: isMobile ? _buildContentColumnMobile() : _buildContentGridDesktop(),
      ),
    );
  }

  Widget _buildContentGridDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTasksSection()),
        const SizedBox(width: 32),
        Expanded(child: _buildStatisticsSection()),
      ],
    );
  }

  Widget _buildContentColumnMobile() {
    return Column(
      children: [
        _buildTasksSection(),
        const SizedBox(height: 24),
        _buildStatisticsSection(),
      ],
    );
  }

  Widget _buildTasksSection() {
    final taskList = tasks.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Oxirgi Topshiriqlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          if (taskList.isEmpty)
            const Text(
              'Topshiriqlar mavjud emas',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            )
          else
            ...taskList.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < taskList.length - 1 ? 12 : 0,
                ),
                child: _buildTaskItem(task: task),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTaskItem({required TaskModel task}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.primaryBlue, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: task.isPending
                      ? AppColors.warningLight
                      : AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: task.isPending
                        ? const Color(0xFF92400E)
                        : const Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.date,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Statistika',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: statistics.map((stat) => _buildStatCard(stat: stat)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required StatisticModel stat}) {
    return Container(
      decoration: BoxDecoration(
        gradient: stat.gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
class InternshipCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final Set<String> activeDays;

  const InternshipCalendarDialog({
    super.key,
    required this.initialDate,
    required this.activeDays,
  });

  @override
  State<InternshipCalendarDialog> createState() =>
      _InternshipCalendarDialogState();
}

class _InternshipCalendarDialogState extends State<InternshipCalendarDialog> {
  late DateTime visibleMonth;

  @override
  void initState() {
    super.initState();
    visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  String _key(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'Iyun',
      'Iyul',
      'Avgust',
      'Sentabr',
      'Oktabr',
      'Noyabr',
      'Dekabr',
    ];
    return months[month - 1];
  }

  void _previousMonth() {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final lastDay = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);

    final startWeekday = firstDay.weekday % 7; // Sunday = 0
    final totalCells = startWeekday + lastDay.day;
    final rowCount = (totalCells / 7).ceil();
    final cellCount = rowCount * 7;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Amaliyot kunlari',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Row(
              children: [
                _WeekDayText('Y'),
                _WeekDayText('D'),
                _WeekDayText('S'),
                _WeekDayText('Ch'),
                _WeekDayText('P'),
                _WeekDayText('J'),
                _WeekDayText('Sh'),
              ],
            ),

            const SizedBox(height: 8),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - startWeekday + 1;

                if (dayNumber < 1 || dayNumber > lastDay.day) {
                  return const SizedBox();
                }

                final date = DateTime(
                  visibleMonth.year,
                  visibleMonth.month,
                  dayNumber,
                );

                final isActive = widget.activeDays.contains(_key(date));
                final isToday = _key(date) == _key(DateTime.now());

                return Container(
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.successGreen
                        : isToday
                        ? AppColors.lightBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    border: isToday && !isActive
                        ? Border.all(color: AppColors.primaryBlue, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        isActive || isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Amaliyot kuni',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDayText extends StatelessWidget {
  final String text;

  const _WeekDayText(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}