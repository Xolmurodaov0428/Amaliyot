import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_config.dart';
import '../constants/app_colors.dart';
import '../screens/profile_screen.dart';
import 'chat_page.dart';

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

    String formattedDate = "📅 Sana yo'q";

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
  final IconData icon;

  const StatisticModel({
    required this.value,
    required this.label,
    required this.gradient,
    required this.icon,
  });
}

// ============= MAIN PAGE =============
class StudentPortalPage extends StatefulWidget {

  const StudentPortalPage({super.key});

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
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvatar();
    fetchDashboard();
    _loadUnreadCount();
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

  Uri _buildStudentUri(String path) => ApiConfig.uri(path);

  Map<String, String> _authHeaders(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _safeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        _buildStudentUri('messages/unread-count'),
        headers: _authHeaders(token),
      );
      final body = _safeJsonMap(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'];
        int unread = 0;

        if (data is Map<String, dynamic>) {
          unread = int.tryParse(
                (data['unread_count'] ?? data['count'] ?? 0).toString(),
              ) ??
              0;
        } else {
          unread = int.tryParse(data?.toString() ?? '0') ?? 0;
        }

        setState(() => _unreadCount = unread);
      }
    } catch (_) {
      // Unread badge stays non-blocking.
    }
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
        ApiConfig.uri('dashboard-student'),
        headers: _authHeaders(token),
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
  Future<void> _refreshDashboard() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;
      final response = await http.get(
        ApiConfig.uri('dashboard-student'),
        headers: _authHeaders(token),
      );
      final body = _safeJsonMap(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && body['success'] == true) {
        setState(() {
          dashboard = Map<String, dynamic>.from(body['data']);
          errorMessage = null;
        });
      }
    } catch (_) {}
    await _loadUnreadCount();
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
    final text = v.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'no name' || text.toLowerCase() == 'null') {
      return fallback;
    }
    return text;
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return 'Kiritilmagan';
    try {
      final s = raw.toString().replaceFirst(' ', 'T');
      final dt = DateTime.parse(s);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      return '$d.$m.${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  Map<String, dynamic> map(String key) {
    final item = dashboard?[key];
    if (item is Map<String, dynamic>) return item;
    return {};
  }

  List<TaskModel> get tasks {
    final raw = dashboard?['tasks'];

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
        icon: Icons.bar_chart_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
      ),
      StatisticModel(
        value: value(stats['present'], '0'),
        label: 'Keldi',
        icon: Icons.check_circle_outline_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
      ),
      StatisticModel(
        value: value(stats['absent'], '0'),
        label: 'Kelmadi',
        icon: Icons.highlight_off_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
        ),
      ),
      StatisticModel(
        value: value(stats['late'], '0'),
        label: 'Kech keldi',
        icon: Icons.schedule_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
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
      floatingActionButton: _buildChatFab(),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
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
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatFab() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatPage()),
            );
            _loadUnreadCount();
          },
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          tooltip: 'Rahbar bilan chat',
          child: const Icon(Icons.chat_bubble_rounded),
        ),
        if (_unreadCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.dangerRed,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
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
            color: AppColors.primaryBlue.withValues(alpha: 0.15),
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
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
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
                if (value(leader['name']) != 'Kiritilmagan') ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildMetaItem('🏢 Tashkilot Rahbari:', value(leader['name'])),
                    ],
                  ),
                ],
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
    final firstDay = _fmtDate(internship['start_date']);
    final lastDay = _fmtDate(internship['end_date']);

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
              : "Xaritada ko'rish uchun bosing",
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '📋 Oxirgi Topshiriqlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    DefaultTabController.of(context).animateTo(1),
                child: const Text(
                  "Barchasini ko'rish →",
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Statistika',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -14,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(stat.icon, color: Colors.white, size: 18),
                ),
                const Spacer(),
                Text(
                  stat.value,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
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
    final now = DateTime.now();
    visibleMonth = DateTime(now.year, now.month);
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
      backgroundColor: Theme.of(context).cardColor,
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
                Expanded(
                  child: Text(
                    'Amaliyot kunlari',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
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
                        ? AppColors.primaryBlue.withValues(alpha: 0.18)
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
                            : isToday
                            ? AppColors.primaryBlue
                            : Theme.of(context).colorScheme.onSurface,
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
                Text(
                  'Amaliyot kuni',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}