import 'package:flutter/material.dart';

class DavomatPage extends StatefulWidget {
  const DavomatPage({super.key});

  @override
  State<DavomatPage> createState() => _DavomatPageState();
}

class _DavomatPageState extends State<DavomatPage> {
  bool is9amChecked = false;
  bool is1pmChecked = false;
  bool is4pmChecked = false;

  bool is9amLocked = false;
  bool is1pmLocked = false;
  bool is4pmLocked = false;

  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> attendanceHistory = [
    {
      'date': '15.01.2025',
      'morning': true,
      'afternoon': true,
      'evening': false,
      'status': 'Qisman',
    },
    {
      'date': '14.01.2025',
      'morning': true,
      'afternoon': true,
      'evening': true,
      'status': 'To\'liq',
    },
    {
      'date': '13.01.2025',
      'morning': false,
      'afternoon': false,
      'evening': false,
      'status': 'Yo\'q',
    },
    {
      'date': '13.01.2025',
      'morning': false,
      'afternoon': false,
      'evening': false,
      'status': 'Yo\'q',
    },
    {
      'date': '13.01.2025',
      'morning': false,
      'afternoon': false,
      'evening': false,
      'status': 'Yo\'q',
    },
  ];

  // 📤 API orqali yuborish (mock)
  Future<void> _sendToApi(String session) async {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('APIga yuborildi: $session seansi');
  }

  void _saveAttendance() async {
    if (!(is9amChecked || is1pmChecked || is4pmChecked)) {
      _showSnack('Kamida bitta seansni belgilang!', Colors.red);
      return;
    }

    DateTime now = DateTime.now();

    // 9:00 seansi (9:00 – 9:40)
    if (is9amChecked && !is9amLocked) {
      final start9 = DateTime(now.year, now.month, now.day, 9, 0);
      final end9 = DateTime(now.year, now.month, now.day, 9, 40, 59);
      if (now.isAfter(start9.subtract(const Duration(seconds: 1))) &&
          now.isBefore(end9.add(const Duration(seconds: 1)))) {
        await _sendToApi("9:00");
        setState(() => is9amLocked = true);
      } else {
        _showSnack("9:00 dan 9:40 gacha belgilang!", Colors.orange);
        setState(() => is9amChecked = false);
        return;
      }
    }

    // 13:00 seansi (13:00 – 13:40)
    if (is1pmChecked && !is1pmLocked) {
      final start13 = DateTime(now.year, now.month, now.day, 13, 0);
      final end13 = DateTime(now.year, now.month, now.day, 13, 40, 59);
      if (now.isAfter(start13.subtract(const Duration(seconds: 1))) &&
          now.isBefore(end13.add(const Duration(seconds: 1)))) {
        await _sendToApi("13:00");
        setState(() => is1pmLocked = true);
      } else {
        _showSnack("13:00 dan 13:40 gacha belgilang!", Colors.orange);
        setState(() => is1pmChecked = false);
        return;
      }
    }

    // 16:00 seansi (15:30 – 16:00)
    if (is4pmChecked && !is4pmLocked) {
      final start16 = DateTime(now.year, now.month, now.day, 15, 30);
      final end16 = DateTime(now.year, now.month, now.day, 16, 0, 59);
      if (now.isAfter(start16.subtract(const Duration(seconds: 1))) &&
          now.isBefore(end16.add(const Duration(seconds: 1)))) {
        await _sendToApi("16:00");
        setState(() => is4pmLocked = true);
      } else {
        _showSnack("15:30 dan 16:00 gacha belgilang!", Colors.orange);
        setState(() => is4pmChecked = false);
        return;
      }
    }

    _showSnack('Davomat muvaffaqiyatli saqlandi! ✅', Colors.green);
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  String _getWeekday(DateTime date) {
    const days = ['Dush', 'Sesh', 'Chor', 'Pay', 'Juma', 'Shan', 'Yak'];
    return days[date.weekday - 1];
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.teal),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  Widget _buildTimeSlot({
    required String time,
    required String label,
    required IconData icon,
    required Color color,
    required bool isChecked,
    required bool isLocked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
        Checkbox(
          value: isChecked,
          onChanged: isLocked ? null : onChanged,
          activeColor: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildProgressCard(double percentage, int totalChecked) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Bugungi davomat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                      percentage == 100 ? Colors.green : Colors.teal),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: percentage == 100 ? Colors.green : Colors.teal),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalChecked / 3 seans',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            percentage == 100
                ? 'Davomat to‘liq'
                : (percentage == 0 ? 'Boshlanmagan' : 'Qisman bajarilgan'),
            style: TextStyle(
              color: percentage == 100
                  ? Colors.green
                  : (percentage == 0 ? Colors.grey : Colors.teal),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.teal, size: 24),
              SizedBox(width: 8),
              Text(
                'Davomat belgilash',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimeSlot(
            time: '9:00',
            label: 'Ertalabki seans',
            icon: Icons.wb_sunny,
            color: Colors.orange,
            isChecked: is9amChecked,
            isLocked: is9amLocked,
            onChanged: (v) => setState(() => is9amChecked = v ?? false),
          ),
          const Divider(),
          _buildTimeSlot(
            time: '13:00',
            label: 'Kunduzi seans',
            icon: Icons.wb_sunny_outlined,
            color: Colors.amber,
            isChecked: is1pmChecked,
            isLocked: is1pmLocked,
            onChanged: (v) => setState(() => is1pmChecked = v ?? false),
          ),
          const Divider(),
          _buildTimeSlot(
            time: '16:00',
            label: 'Kechki seans',
            icon: Icons.nights_stay,
            color: Colors.indigo,
            isChecked: is4pmChecked,
            isLocked: is4pmLocked,
            onChanged: (v) => setState(() => is4pmChecked = v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    Color statusColor;
    IconData statusIcon;

    switch (data['status']) {
      case 'To\'liq':
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['date'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniCheckbox(data['morning']),
                    const SizedBox(width: 4),
                    _buildMiniCheckbox(data['afternoon']),
                    const SizedBox(width: 4),
                    _buildMiniCheckbox(data['evening']),

                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(data['status'],
                style:
                TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCheckbox(bool isChecked) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isChecked ? Colors.teal : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: isChecked
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Davomat tarixi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...attendanceHistory.map(_buildHistoryCard).toList(),
      ],
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: _selectDate,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bugungi sana',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  _formatDate(selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _getWeekday(selectedDate),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    int totalChecked = [is9amChecked, is1pmChecked, is4pmChecked]
        .where((e) => e)
        .length;
    double percentage = (totalChecked / 3) * 100;

    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(child: _buildProgressCard(percentage, totalChecked)),
          const SizedBox(width: 10),
          Expanded(child: _buildCheckboxCard()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateCard(),
            const SizedBox(height: 20),
            _buildAttendanceCard(),
            const SizedBox(height: 20),
            _buildHistorySection(),
            // ElevatedButton o'chirildi, floatingActionButton ishlatiladi
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAttendance,
        icon: const Icon(Icons.save),
        label: const Text("Saqlash"),
        backgroundColor: Colors.teal,
      ),
    );

  }
}
