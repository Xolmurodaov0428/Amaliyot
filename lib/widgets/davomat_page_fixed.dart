import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthService helper
// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────
class AttendanceRecord {
  final int id;
  final int studentId;
  final DateTime date;
  final String session;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;
  final String? notes;
  final double? latitude;
  final double? longitude;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    required this.session,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
    return AttendanceRecord(
      id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      studentId: int.tryParse(j['student_id']?.toString() ?? '0') ?? 0,
      date: (DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now()).toLocal(),
      session: j['session']?.toString() ?? 'session_1',
      status: j['status']?.toString() ?? 'absent',
      checkInTime: j['check_in_time']?.toString(),
      checkOutTime: j['check_out_time']?.toString(),
      notes: j['notes']?.toString(),
      latitude: double.tryParse(j['latitude']?.toString() ?? ''),
      longitude: double.tryParse(j['longitude']?.toString() ?? ''),
    );
  }

  int get sessionNumber {
    if (session.contains('1')) return 1;
    if (session.contains('2')) return 2;
    if (session.contains('3')) return 3;
    return 1;
  }

  String get sessionName {
    if (sessionNumber == 1) return 'Ertalabki seans';
    if (sessionNumber == 2) return 'Kunduzi seans';
    return 'Kechki seans';
  }
}
class UzbekCalendarDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Set<String> allowedDates;

  const UzbekCalendarDialog({
    super.key,
    required this.selectedDate,
    required this.allowedDates,
  });

  @override
  State<UzbekCalendarDialog> createState() => _UzbekCalendarDialogState();
}

class _UzbekCalendarDialogState extends State<UzbekCalendarDialog> {
  late DateTime visibleMonth;

  @override
  void initState() {
    super.initState();
    visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  String _key(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final lastDay = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);

    final startWeekday = firstDay.weekday % 7;
    final totalCells = startWeekday + lastDay.day;
    final cellCount = (totalCells / 7).ceil() * 7;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sana tanlash',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            Row(
              children: [
                Text(
                  '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      visibleMonth = DateTime(
                        visibleMonth.year,
                        visibleMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      visibleMonth = DateTime(
                        visibleMonth.year,
                        visibleMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Row(
              children: [
                _CalendarWeekDay('Yak'),
                _CalendarWeekDay('Dush'),
                _CalendarWeekDay('Sesh'),
                _CalendarWeekDay('Chor'),
                _CalendarWeekDay('Pay'),
                _CalendarWeekDay('Jum'),
                _CalendarWeekDay('Shan'),
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

                final key = _key(date);
                final isAllowed = widget.allowedDates.contains(key);
                final isSelected = _key(widget.selectedDate) == key;
                final isToday = _key(DateTime.now()) == key;

                return InkWell(
                  borderRadius: BorderRadius.circular(100),
                    onTap: () => Navigator.pop(context, date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.teal
                          : isAllowed
                          ? const Color(0xFFD1FAE5)
                          : isToday
                          ? const Color(0xFFE0F2FE)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                      border: isAllowed
                          ? Border.all(color: Colors.teal, width: 1.5)
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontWeight: isAllowed || isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isAllowed
                              ? Colors.teal.shade800
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    border: Border.all(color: Colors.teal),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Amaliyot kuni'),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Bekor qilish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarWeekDay extends StatelessWidget {
  final String text;

  const _CalendarWeekDay(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class DayAttendance {
  final DateTime date;
  final List<AttendanceRecord> records;
  final int dailySessions;

  const DayAttendance(this.date, this.records, this.dailySessions);

  bool get session1 =>
      records.any((r) => r.sessionNumber == 1 && r.status == 'present');

  bool get session2 =>
      records.any((r) => r.sessionNumber == 2 && r.status == 'present');

  bool get session3 =>
      records.any((r) => r.sessionNumber == 3 && r.status == 'present');

  int get presentCount {
    int count = 0;
    if (session1) count++;
    if (dailySessions >= 2 && session2) count++;
    if (dailySessions >= 3 && session3) count++;
    return count;
  }

  String get statusLabel {
    if (presentCount >= dailySessions) return "To'liq";
    if (presentCount == 0) return "Yo'q";
    return 'Qisman';
  }

  String get dateStr =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive helper
// ─────────────────────────────────────────────────────────────────────────────
class _R {
  final double w;
  const _R(this.w);

  bool get isXS => w < 360;
  bool get isSM => w < 414;

  double get pad => isXS ? 10 : (isSM ? 14 : 18);
  double get gap => isXS ? 12 : (isSM ? 16 : 20);
  double get radius => isXS ? 12 : 16;

  double get fs10 => isXS ? 10 : (isSM ? 11 : 12);
  double get fs12 => isXS ? 11 : (isSM ? 12 : 13);
  double get fs14 => isXS ? 12 : (isSM ? 13 : 14);
  double get fs16 => isXS ? 13 : (isSM ? 15 : 16);
  double get fs18 => isXS ? 14 : (isSM ? 16 : 18);
  double get fs20 => isXS ? 16 : (isSM ? 18 : 20);
  double get fs32 => isXS ? 24 : (isSM ? 28 : 32);

  double get iconSm => isXS ? 18 : (isSM ? 20 : 22);
  double get iconMd => isXS ? 22 : (isSM ? 24 : 26);
  double get circle => isXS ? 100 : (isSM ? 115 : 130);
  double get stroke => isXS ? 9 : (isSM ? 10 : 12);
  double get slotPad => isXS ? 6 : (isSM ? 8 : 10);
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class DavomatPage extends StatefulWidget {
  const DavomatPage({super.key});

  @override
  State<DavomatPage> createState() => _DavomatPageState();
}

class _DavomatPageState extends State<DavomatPage> {
  bool is9amChecked = false;
  bool is1pmChecked = false;
  bool is4pmChecked = false;
  
  // Normalize date to YMD
  DateTime selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  bool _isLoading = false;
  String _error = '';

  List<DayAttendance> _history = [];
  int dailySessions = 3;
  Set<String> selectedDates = {};

  // Organization location from API: data.student.organization
  double? organizationLatitude;
  double? organizationLongitude;
  double organizationRadiusMeters = 70; // API radius 0.07 km => 70 metr

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  int get _selectedCount =>
      [is9amChecked, is1pmChecked, is4pmChecked].where((e) => e).length;

  bool _canSelectMore() => _selectedCount < dailySessions;

  String _selectedDateKey() {
    return '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
  }

  bool _isSelectedDateAllowed() {
    if (selectedDates.isEmpty) return true;
    return selectedDates.contains(_selectedDateKey());
  }

  Set<String> _existingSessionsForSelectedDate() {
    final target = _selectedDateKey();
    for (final day in _history) {
      final dayKey = '${day.date.year.toString().padLeft(4, '0')}-'
          '${day.date.month.toString().padLeft(2, '0')}-'
          '${day.date.day.toString().padLeft(2, '0')}';

      if (dayKey == target) {
        return day.records
            .map((r) => r.session)
            .toSet();
      }
    }

    return <String>{};
  }

  void _syncCheckedSessionsFromHistory() {
    if (!mounted) return;
    final existing = _existingSessionsForSelectedDate();

    setState(() {
      is9amChecked = existing.contains('session_1');
      is1pmChecked = existing.contains('session_2');
      is4pmChecked = existing.contains('session_3');
    });
  }

  void _handleCheck({
    required int sessionNumber,
    required bool? value,
  }) {
    final newValue = value ?? false;
    final existing = _existingSessionsForSelectedDate();

    if (sessionNumber == 1 && existing.contains('session_1')) {
      _snack('Bu sana uchun 1-seans allaqachon saqlangan.', Colors.orange);
      return;
    }
    if (sessionNumber == 2 && existing.contains('session_2')) {
      _snack('Bu sana uchun 2-seans allaqachon saqlangan.', Colors.orange);
      return;
    }
    if (sessionNumber == 3 && existing.contains('session_3')) {
      _snack('Bu sana uchun 3-seans allaqachon saqlangan.', Colors.orange);
      return;
    }

    if (newValue && !_canSelectMore()) {
      _snack(
        'Bir kunda faqat $dailySessions ta seans belgilash mumkin.',
        Colors.orange,
      );
      return;
    }

    setState(() {
      if (sessionNumber == 1) is9amChecked = newValue;
      if (sessionNumber == 2) is1pmChecked = newValue;
      if (sessionNumber == 3) is4pmChecked = newValue;
    });
  }

  String _currentTimeHHmm() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // DateTime _sessionWindowStart(String session) {
  //   if (dailySessions == 1) {
  //     return DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       selectedDate.day,
  //       11,
  //       30,
  //     );
  //   }
  //
  //   if (dailySessions == 2) {
  //     if (session == 'session_1') {
  //       return DateTime(
  //         selectedDate.year,
  //         selectedDate.month,
  //         selectedDate.day,
  //         9,
  //         0,
  //       );
  //     }
  //     return DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       selectedDate.day,
  //       13,
  //       0,
  //     );
  //   }
  //
  //   if (session == 'session_1') {
  //     return DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       selectedDate.day,
  //       9,
  //       0,
  //     );
  //   }
  //
  //   if (session == 'session_2') {
  //     return DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       selectedDate.day,
  //       13,
  //       0,
  //     );
  //   }
  //
  //   return DateTime(
  //     selectedDate.year,
  //     selectedDate.month,
  //     selectedDate.day,
  //     15,
  //     30,
  //   );
  // }
  //
  // DateTime _sessionWindowEnd(String session) {
  //   if (dailySessions == 1) {
  //     return DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       selectedDate.day,
  //       12,
  //       0,
  //     );
  //   }
  //
  //   if (dailySessions == 2) {
  //     if (session == 'session_1') {
  //       return DateTime(
  //         selectedDate.year,
  //         selectedDate.month,
  //         selectedDate.day,
  //         9,
  //         30,
  //       );
  //     }
  //     return DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       selectedDate.day,
  //       13,
  //       30,
  //     );
  //   }
  //
  //   if (session == 'session_1') {
  //     return DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       selectedDate.day,
  //       9,
  //       30,
  //     );
  //   }
  //
  //   if (session == 'session_2') {
  //     return DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       selectedDate.day,
  //       13,
  //       30,
  //     );
  //   }
  //
  //   return DateTime(
  //     selectedDate.year,
  //     selectedDate.month,
  //     selectedDate.day,
  //     16,
  //     0,
  //   );
  // }
  DateTime _sessionStart(String session) {
    if (dailySessions == 1) {
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 11, 30);
    }

    if (session == 'session_1') {
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 0);
    }

    if (session == 'session_2') {
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 0);
    }

    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 15, 30);
  }

  DateTime _sessionEnd(String session) {
    if (dailySessions == 1) {
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12, 0);
    }

    if (session == 'session_1') {
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 9, 30);
    }

    if (session == 'session_2') {
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 30);
    }

    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 16, 0);
  }

  DateTime _sessionAbsentDeadline(String session) {
    if (dailySessions == 1) {
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 14, 0);
    }

    if (dailySessions == 2) {
      if (session == 'session_1') {
        return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 0);
      }

      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 15, 0);
    }

    if (session == 'session_1') {
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 13, 0);
    }

    if (session == 'session_2') {
      return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 15, 30);
    }

    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 16, 30);
  }

  String _attendanceNoteForSession(String session) {
    final now = DateTime.now();

    final start = _sessionStart(session);
    final end = _sessionEnd(session);
    final absentDeadline = _sessionAbsentDeadline(session);

    if (now.isBefore(start)) {
      return 'Vaqti kelmagan';
    }

    if (!now.isAfter(end)) {
      return 'Keldi';
    }

    if (now.isBefore(absentDeadline) || now.isAtSameMomentAs(absentDeadline)) {
      return 'Kechikib keldi';
    }

    return 'Kelmadi';
  }

  bool _isTooEarlyForSession(String session) {
    return _attendanceNoteForSession(session) == 'Vaqti kelmagan';
  }

  String _sessionTimeText(String session) {
    final start = _sessionStart(session);
    final end = _sessionEnd(session);

    String fmt(DateTime d) {
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    return '${fmt(start)} dan ${fmt(end)} gacha';
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS yoqilmagan. Lokatsiyani yoqing.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Lokatsiya ruxsati berilmadi.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Lokatsiya ruxsati doimiy rad etilgan. Sozlamadan yoqing.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
  double _distanceToOrganizationMeters(Position position) {
    if (organizationLatitude == null || organizationLongitude == null) {
      throw Exception('Tashkilot lokatsiyasi topilmadi.');
    }

    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      organizationLatitude!,
      organizationLongitude!,
    );
  }

  bool _isInsideOrganizationRadius(Position position) {
    final distance = _distanceToOrganizationMeters(position);
    return distance <= organizationRadiusMeters;
  }

  Future<bool> _confirmOutsideLocation(double distanceMeters) async {
    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Lokatsiya ogohlantirishi'),
            content: Text(
              'Siz tashkilot hududida emassiz.\n'
              'Masofa: ${distanceMeters.toStringAsFixed(0)} metr.\n\n'
              'Davomat saqlansinmi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Yo‘q'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ha'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // GET API
  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final token = await AuthService.getToken();
      if (!mounted) return;

      if (token == null || token.isEmpty) {
        return _setError('Sessiya tugagan. Qayta kiring.');
      }

      final res = await http.get(
        Uri.parse('https://shaxa.mycoder.uz/api/student/attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);
        if (body is! Map<String, dynamic>) {
          return _setError('Server xatosi: noto‘g‘ri JSON format.');
        }

        final dynamic data = body['data'];
        if (data is! Map<String, dynamic>) {
          return _setError('Ma’lumotlar topilmadi (data field missing).');
        }
        final selectedDatesRaw =
            data['selected_dates'] ?? data['active_days'] ?? data['internship']?['selected_dates'];

        final Set<String> apiSelectedDates = {};

        if (selectedDatesRaw is List) {
          apiSelectedDates.addAll(selectedDatesRaw.map((e) => e.toString()));
        }
        final dynamic student = data['student'];
        final Map<String, dynamic>? studentMap = (student is Map) ? Map<String, dynamic>.from(student) : null;

        double? apiOrganizationLatitude;
        double? apiOrganizationLongitude;
        double apiOrganizationRadiusMeters = 70;

        final dynamic organizationRaw = studentMap?['organization'];
        final Map<String, dynamic>? organizationMap =
            (organizationRaw is Map) ? Map<String, dynamic>.from(organizationRaw) : null;

        if (organizationMap != null) {
          apiOrganizationLatitude = double.tryParse(
            organizationMap['latitude']?.toString() ?? '',
          );
          apiOrganizationLongitude = double.tryParse(
            organizationMap['longitude']?.toString() ?? '',
          );

          // Backenddan radius odatda km ko‘rinishida keladi: 0.07 => 70 metr.
          final radiusKm = double.tryParse(
                organizationMap['radius']?.toString() ?? '',
              ) ??
              0.07;
          apiOrganizationRadiusMeters = radiusKm * 1000;
        }

        final dynamic attendancesRaw = data['attendances'];
        final List<dynamic> attendancesList = (attendancesRaw is List) ? attendancesRaw : [];

        int apiDailySessions = 3;
        if (studentMap != null) {
          apiDailySessions = int.tryParse(
            studentMap['daily-sesions']?.toString() ??
            studentMap['daily_sessions']?.toString() ??
            '3'
          ) ?? 3;
        }

        if (apiDailySessions < 1) apiDailySessions = 1;
        if (apiDailySessions > 3) apiDailySessions = 3;

        final records = attendancesList
            .whereType<Map>()
            .map((e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final Map<String, List<AttendanceRecord>> grouped = {};
        for (final r in records) {
          // Guruhlash uchun har doim mahalliy sanadan foydalanamiz
          final d = r.date.toLocal();
          final key = '${d.year.toString().padLeft(4, '0')}-'
              '${d.month.toString().padLeft(2, '0')}-'
              '${d.day.toString().padLeft(2, '0')}';
          grouped.putIfAbsent(key, () => []).add(r);
        }

        final history = grouped.entries.map((e) {
          final date = DateTime.tryParse(e.key) ?? DateTime.now();
          return DayAttendance(date, e.value, apiDailySessions);
        }).toList();

        history.sort((a, b) => b.date.compareTo(a.date));

        setState(() {
          selectedDates = apiSelectedDates;
          dailySessions = apiDailySessions;
          organizationLatitude = apiOrganizationLatitude;
          organizationLongitude = apiOrganizationLongitude;
          organizationRadiusMeters = apiOrganizationRadiusMeters;
          _history = history;
          _isLoading = false;
        });

        _syncCheckedSessionsFromHistory();
      } else if (res.statusCode == 401) {
        _setError('Sessiya tugagan. Qayta kiring.');
      } else {
        _setError('Server xatosi (${res.statusCode}).');
      }
    } on SocketException {
      _setError('Internet aloqasi mavjud emas.');
    } on TimeoutException {
      _setError('Server javob bermadi.');
    } on FormatException {
      _setError('Serverdan noto‘g‘ri ma’lumot keldi.');
    } catch (e) {
      _setError('Xato: $e');
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _error = msg;
      _isLoading = false;
    });
  }

  // POST API
  Future<void> _save() async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    if (selectedDate.isBefore(today)) {
      _snack('O‘tgan kunlar uchun davomat belgilab bo‘lmaydi!', Colors.red);
      return;
    }
    if (!_isSelectedDateAllowed()) {
      _snack('Bu sana amaliyot kuni emas. Davomat belgilab bo‘lmaydi!', Colors.red);
      return;
    }
    if (_selectedCount == 0) {
      _snack('Kamida bitta seansni belgilang!', Colors.red);
      return;
    }

    if (_selectedCount > dailySessions) {
      _snack('Faqat $dailySessions ta seans saqlash mumkin.', Colors.red);
      return;
    }

    final userId = await AuthService.getUserId();
    final token = await AuthService.getToken();

    if (!mounted) return;

    if (userId == null || token == null || token.isEmpty) {
      _snack('Sessiya tugagan. Qayta kiring.', Colors.red);
      return;
    }

    final selectedSessions = <String>[];
    if (is9amChecked) selectedSessions.add('session_1');
    if (dailySessions >= 2 && is1pmChecked) selectedSessions.add('session_2');
    if (dailySessions >= 3 && is4pmChecked) selectedSessions.add('session_3');

    final existingSessions = _existingSessionsForSelectedDate();
    final sessionsToSend = selectedSessions
        .where((session) => !existingSessions.contains(session))
        .toList();

    if (sessionsToSend.isEmpty) {
      _snack('Bu sana uchun tanlangan seanslar allaqachon saqlangan.', Colors.orange);
      return;
    }

    for (final session in sessionsToSend) {
      if (_isTooEarlyForSession(session)) {
        _snack('$session uchun vaqt hali kelmagan. Ruxsat: ${_sessionTimeText(session)}', Colors.orange);
        return;
      }
    }

    try {
      setState(() => _isLoading = true);

      final position = await _getCurrentPosition();
      if (!mounted) return;

      final distanceMeters = _distanceToOrganizationMeters(position);
      final isInsideOrganization = distanceMeters <= organizationRadiusMeters;

      if (!isInsideOrganization) {
        final allowSave = await _confirmOutsideLocation(distanceMeters);
        if (!mounted) return;

        if (!allowSave) {
          setState(() => _isLoading = false);
          _snack('Davomat saqlanmadi.', Colors.orange);
          return;
        }
      }

      for (final session in sessionsToSend) {
        final normalNote = _attendanceNoteForSession(session);

        if (normalNote == 'Vaqti kelmagan') {
          _snack('$session uchun vaqt hali kelmagan. Ruxsat: ${_sessionTimeText(session)}', Colors.orange);
          setState(() => _isLoading = false);
          return;
        }

        final note = isInsideOrganization
            ? normalNote
            : 'Tashkilot hududida emas';

        final status = isInsideOrganization
            ? (note == 'Kelmadi' ? 'absent' : 'present')
            : 'absent';

        final body = {
          'student_id': userId,
          'date': _selectedDateKey(),
          'session': session,
          'status': status,
          // Hududdan tashqarida bo‘lsa ham urinish vaqti saqlanadi.
          'check_in_time': _currentTimeHHmm(),
          'check_out_time': null,
          // Hududdan tashqarida bo‘lsa ham audit uchun koordinata yuboriladi.
          'latitude': position.latitude,
          'longitude': position.longitude,
          'notes': note,
        };

        final res = await http.post(
          Uri.parse('https://shaxa.mycoder.uz/api/student/attendance'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 15));

        if (!mounted) return;

        if (res.statusCode != 200 && res.statusCode != 201) {
          throw Exception('Server xatosi: ${res.statusCode}');
        }
      }

      final skippedCount = selectedSessions.length - sessionsToSend.length;
      if (skippedCount > 0) {
        _snack('${sessionsToSend.length} ta yangi seans saqlandi, $skippedCount tasi oldin bor.', Colors.green);
      } else {
        _snack('Davomat muvaffaqiyatli saqlandi! ✅', Colors.green);
      }

      await _loadHistory();
      
      // _loadHistory already handles loading state and syncing checked boxes.
    } on SocketException {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Internet aloqasi mavjud emas.', Colors.red);
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Server javob bermadi.', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack('Xato: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final r = _R(box.maxWidth);
      return Scaffold(
        backgroundColor: Colors.grey[100],
        floatingActionButton: _fab(r),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadHistory,
            color: Colors.teal,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(r.pad, 12, r.pad, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateCard(r),
                  SizedBox(height: r.gap),
                  _attendanceSection(r),
                  SizedBox(height: r.gap),
                  _historySection(r),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _fab(_R r) => FloatingActionButton.extended(
    onPressed: _isLoading ? null : _save,
    backgroundColor: Colors.teal,
    icon: Icon(Icons.save, size: r.iconSm),
    label: Text('Saqlash', style: TextStyle(fontSize: r.fs14)),
  );

  Widget _dateCard(_R r) => Container(
    padding: EdgeInsets.symmetric(horizontal: r.pad, vertical: 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.teal.shade400, Colors.teal.shade600],
      ),
      borderRadius: BorderRadius.circular(r.radius),
      boxShadow: [
        BoxShadow(
          color: Colors.teal.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.calendar_month, color: Colors.white, size: r.iconMd),
          onPressed: _isLoading ? null : _pickDate,
        ),
        SizedBox(width: r.isXS ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tanlangan sana',
                style: TextStyle(color: Colors.white70, fontSize: r.fs12),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _fmtDate(selectedDate),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.fs20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          _weekday(selectedDate),
          style: TextStyle(color: Colors.white, fontSize: r.fs14),
        ),
      ],
    ),
  );

  Widget _attendanceSection(_R r) {
    final total = _selectedCount;
    final pct = dailySessions == 0 ? 0.0 : (total / dailySessions) * 100;

    return Column(
      children: [
        _progressCard(r, pct, total),
        SizedBox(height: r.gap * 0.65),
        _checkboxCard(r),
      ],
    );
  }

  Widget _progressCard(_R r, double pct, int total) {
    final color = pct >= 100 ? Colors.green : Colors.teal;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: r.isXS ? 14 : 18,
        horizontal: r.pad,
      ),
      decoration: _card(r),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: r.circle,
                height: r.circle,
                child: CircularProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  strokeWidth: r.stroke,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${pct.toInt()}%',
                      style: TextStyle(
                        fontSize: r.fs32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Text(
                    '$total / $dailySessions seans',
                    style: TextStyle(fontSize: r.fs12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(width: r.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bugungi davomat',
                  style: TextStyle(
                    fontSize: r.fs16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: r.isXS ? 6 : 10),
                Text(
                  pct >= 100
                      ? "Davomat to'liq ✅"
                      : (pct == 0 ? 'Boshlanmagan' : 'Qisman bajarilgan'),
                  style: TextStyle(
                    fontSize: r.fs14,
                    fontWeight: FontWeight.w500,
                    color: pct >= 100
                        ? Colors.green
                        : (pct == 0 ? Colors.grey : Colors.teal),
                  ),
                ),
                SizedBox(height: r.isXS ? 8 : 12),
                Wrap(
                  spacing: r.isXS ? 4 : 6,
                  runSpacing: 4,
                  children: [
                    _badge(r, 'Ertala', is9amChecked),
                    if (dailySessions >= 2) _badge(r, 'Kunduz', is1pmChecked),
                    if (dailySessions >= 3) _badge(r, 'Kech', is4pmChecked),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(_R r, String label, bool active) => Container(
    padding: EdgeInsets.symmetric(horizontal: r.isXS ? 5 : 7, vertical: 3),
    decoration: BoxDecoration(
      color: active ? Colors.teal : Colors.grey[200],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? Colors.white : Colors.grey[500],
        fontSize: r.fs10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _checkboxCard(_R r) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(r.pad, 14, r.pad, 8),
    decoration: _card(r),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.teal, size: r.iconSm),
            const SizedBox(width: 6),
            Text(
              'Davomat belgilash ($dailySessions ta seans)',
              style: TextStyle(fontSize: r.fs16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: r.isXS ? 10 : 14),
        _slot(
          r,
          time: dailySessions == 1 ? '11:30' : '9:00',
          label: 'Ertalabki seans',
          icon: Icons.wb_sunny,
          color: Colors.orange,
          checked: is9amChecked,
          onChange: (v) => _handleCheck(sessionNumber: 1, value: v),
        ),
        if (dailySessions >= 2) ...[
          const Divider(height: 4, thickness: 0.5),
          _slot(
            r,
            time: '13:00',
            label: 'Kunduzi seans',
            icon: Icons.wb_sunny_outlined,
            color: Colors.amber,
            checked: is1pmChecked,
            onChange: (v) => _handleCheck(sessionNumber: 2, value: v),
          ),
        ],
        if (dailySessions >= 3) ...[
          const Divider(height: 4, thickness: 0.5),
          _slot(
            r,
            time: '15:30',
            label: 'Kechki seans',
            icon: Icons.nights_stay,
            color: Colors.indigo,
            checked: is4pmChecked,
            onChange: (v) => _handleCheck(sessionNumber: 3, value: v),
          ),
        ],
      ],
    ),
  );

  Widget _slot(
      _R r, {
        required String time,
        required String label,
        required IconData icon,
        required Color color,
        required bool checked,
        required ValueChanged<bool?> onChange,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: r.isXS ? 5 : 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(r.slotPad),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: r.iconSm),
          ),
          SizedBox(width: r.isXS ? 8 : 12),
          Text(
            time,
            maxLines: 1,
            style: TextStyle(
              fontSize: r.fs16,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          SizedBox(width: r.isXS ? 6 : 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: r.fs12),
            ),
          ),
          SizedBox(
            width: 40,
            child: Checkbox(
              value: checked,
              onChanged: (_isLoading || !_isSelectedDateAllowed()) ? null : onChange,
              activeColor: Colors.teal,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historySection(_R r) {
    if (_isLoading && _history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
              const SizedBox(height: 12),
              Text(_error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Davomat tarixi yo\'q',
            style: TextStyle(color: Colors.grey[600], fontSize: r.fs14),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Davomat tarixi',
          style: TextStyle(fontSize: r.fs18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._history.map((day) => _historyCard(r, day)),
      ],
    );
  }

  Widget _historyCard(_R r, DayAttendance day) {
    final Color statusColor;
    final IconData statusIcon;
    switch (day.statusLabel) {
      case "To'liq":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Qisman':
        statusColor = Colors.orange;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: r.pad, vertical: 12),
      decoration: _card(r),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: r.iconMd),
          SizedBox(width: r.isXS ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.dateStr,
                  style: TextStyle(
                    fontSize: r.fs14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _miniBox(r, day.session1),
                    if (day.dailySessions >= 2) ...[
                      const SizedBox(width: 4),
                      _miniBox(r, day.session2),
                    ],
                    if (day.dailySessions >= 3) ...[
                      const SizedBox(width: 4),
                      _miniBox(r, day.session3),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.isXS ? 8 : 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              day.statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: r.fs12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBox(_R r, bool on) {
    final size = r.isXS ? 15.0 : 18.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: on ? Colors.teal : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: on ? Icon(Icons.check, color: Colors.white, size: size - 5) : null,
    );
  }

  BoxDecoration _card(_R r) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(r.radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => UzbekCalendarDialog(
        selectedDate: selectedDate,
        allowedDates: selectedDates,
      ),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month, picked.day);
      });

      _syncCheckedSessionsFromHistory();
    }
  }
  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _weekday(DateTime d) =>
      const ['Dush', 'Sesh', 'Chor', 'Pay', 'Juma', 'Shan', 'Yak'][d.weekday - 1];
}