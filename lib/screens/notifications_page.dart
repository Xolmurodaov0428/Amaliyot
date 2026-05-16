import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../constants/app_colors.dart';

// ─── MODEL ────────────────────────────────────────────────────────────────────

class NotificationModel {
  final int id;
  final int studentId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  bool isRead;
  final String? readAt;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.studentId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      studentId: int.tryParse(json['student_id']?.toString() ?? '') ?? 0,
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? 'Bildirishnoma').toString(),
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['data'])
          : {},
      isRead: json['is_read'] == true,
      readAt: json['read_at']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

// ─── TYPE FILTER ──────────────────────────────────────────────────────────────

class _TypeFilter {
  final String label;
  final String? value;
  const _TypeFilter(this.label, this.value);
}

const _typeFilters = [
  _TypeFilter('Barchasi', null),
  _TypeFilter('Topshiriq', 'new_task'),
  _TypeFilter('Muddat', 'task_deadline'),
  _TypeFilter('Davomat', 'attendance'),
  _TypeFilter('Xabar', 'message'),
  _TypeFilter("E'lon", 'announcement'),
];

// ─── PAGE ─────────────────────────────────────────────────────────────────────

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  final http.Client _httpClient = http.Client();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;

  late TabController _tabController;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isMarkingAll = false;
  String? _errorMessage;
  int _serverUnreadCount = 0;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _showUnreadOnly = false;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _markMessageNotificationsRead();
    _loadServerUnreadCount();
    _loadNotifications(reset: true);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        _loadServerUnreadCount();
        _loadNotifications(reset: true);
      },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    _scrollController.dispose();
    _httpClient.close();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() => _showUnreadOnly = _tabController.index == 1);
    _loadNotifications(reset: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _safeJson(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic>) return d;
      return {};
    } catch (_) {
      return {};
    }
  }

  String _timeAgo(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Hozir';
      if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
      if (diff.inHours < 24) return '${diff.inHours} soat oldin';
      if (diff.inDays < 7) return '${diff.inDays} kun oldin';
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  // ─── API CALLS ──────────────────────────────────────────────────────────────

  Future<void> _markMessageNotificationsRead() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;
      await _httpClient.post(
        ApiConfig.uri('notifications/read-all', {'type': 'message'}),
        headers: _headers(token),
      );
    } catch (_) {}
  }

  Future<void> _loadServerUnreadCount() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;

      final response = await _httpClient.get(
        ApiConfig.uri('notifications/unread-count'),
        headers: _headers(token),
      );
      final body = _safeJson(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'];
        final count = data is Map
            ? int.tryParse(
                    (data['unread_count'] ?? 0).toString()) ??
                0
            : 0;
        setState(() => _serverUnreadCount = count);
      }
    } catch (_) {}
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      });
    }

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Token topilmadi. Qayta login qiling.';
          _isLoading = false;
        });
        return;
      }

      final params = <String, String>{
        'page': _currentPage.toString(),
        'per_page': '15',
      };
      if (_showUnreadOnly) params['is_read'] = '0';
      if (_selectedType != null) params['type'] = _selectedType!;

      final response = await _httpClient.get(
        ApiConfig.uri('notifications', params),
        headers: _headers(token),
      );
      final body = _safeJson(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && body['success'] == true) {
        final rawList = body['data'];
        final pagination = body['pagination'] is Map<String, dynamic>
            ? body['pagination'] as Map<String, dynamic>
            : {};

        final items = rawList is List
            ? rawList
                .whereType<Map>()
                .map((e) => NotificationModel.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList()
            : <NotificationModel>[];

        setState(() {
          _notifications = reset ? items : [..._notifications, ...items];
          _lastPage =
              int.tryParse(pagination['last_page']?.toString() ?? '1') ?? 1;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Sessiya tugagan. Qayta login qiling.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              body['message']?.toString() ?? 'Yuklashda xato yuz berdi.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Xato: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadNotifications();
  }

  Future<void> _markOneRead(NotificationModel notif) async {
    if (notif.isRead) return;
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await _httpClient.post(
        ApiConfig.uri('notifications/${notif.id}/read'),
        headers: _headers(token),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          notif.isRead = true;
          if (_serverUnreadCount > 0) _serverUnreadCount--;
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    setState(() => _isMarkingAll = true);
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      setState(() => _isMarkingAll = false);
      return;
    }

    try {
      final response = await _httpClient.post(
        ApiConfig.uri('notifications/read-all'),
        headers: _headers(token),
      );
      final body = _safeJson(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && body['success'] == true) {
        setState(() {
          for (final n in _notifications) {
            n.isRead = true;
          }
          _serverUnreadCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message']?.toString() ??
              "Barcha bildirishnomalar o'qildi"),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
    if (mounted) setState(() => _isMarkingAll = false);
  }

  Future<void> _deleteNotification(NotificationModel notif) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await _httpClient.delete(
        ApiConfig.uri('notifications/${notif.id}'),
        headers: _headers(token),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          if (!notif.isRead && _serverUnreadCount > 0) _serverUnreadCount--;
          _notifications.remove(notif);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Bildirishnoma o'chirildi"),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  IconData _typeIcon(String type) {
    switch (type) {
      case 'new_task':
        return Icons.assignment_rounded;
      case 'task_deadline':
        return Icons.timer_outlined;
      case 'attendance':
        return Icons.how_to_reg_rounded;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'new_task':
        return AppColors.primaryBlue;
      case 'task_deadline':
        return AppColors.warningOrange;
      case 'attendance':
        return AppColors.successGreen;
      case 'message':
        return AppColors.accentPurple;
      case 'announcement':
        return AppColors.dangerRed;
      default:
        return AppColors.textSecondary;
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bildirishnomalar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_serverUnreadCount > 0)
            _isMarkingAll
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _markAllRead,
                    icon: const Icon(Icons.done_all_rounded,
                        color: Colors.white, size: 18),
                    label: const Text(
                      "Barchasini o'qish",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            const Tab(text: 'Barchasi'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("O'qilmaganlar"),
                  if (_serverUnreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$_serverUnreadCount',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTypeFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildTypeFilterBar() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: _typeFilters.map((f) {
            final isSelected = _selectedType == f.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedType = f.value);
                  _loadNotifications(reset: true);
                },
                selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primaryBlue,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : Theme.of(context).dividerColor,
                ),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.dangerRed),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.dangerRed, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadNotifications(reset: true),
                child: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _showUnreadOnly
                  ? "O'qilmagan bildirishnomalar yo'q"
                  : "Bildirishnomalar yo'q",
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadNotifications(reset: true);
        await _loadServerUnreadCount();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildNotificationCard(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final color = _typeColor(notif.type);
    final icon = _typeIcon(notif.type);

    return Dismissible(
      key: Key('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.dangerRed,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("O'chirish"),
            content: const Text("Bu bildirishnomani o'chirmoqchimisiz?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Bekor qilish')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dangerRed,
                    foregroundColor: Colors.white),
                child: const Text("O'chirish"),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteNotification(notif),
      child: GestureDetector(
        onTap: () => _markOneRead(notif),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: notif.isRead
                ? Theme.of(context).cardColor
                : AppColors.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead
                  ? Theme.of(context).dividerColor
                  : color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            _timeAgo(notif.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          if (notif.isRead) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.done_all_rounded,
                                size: 13, color: AppColors.successGreen),
                            const SizedBox(width: 2),
                            const Text(
                              "O'qildi",
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.successGreen),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
