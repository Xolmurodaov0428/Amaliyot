import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KundalikScreen extends StatefulWidget {
  const KundalikScreen({super.key});

  @override
  State<KundalikScreen> createState() => _KundalikScreenState();
}

class _KundalikScreenState extends State<KundalikScreen> {
  static const String _baseUrl = 'https://shaxa.mycoder.uz/api';

  bool _loadingTemplates = true;
  bool _loadingReports = true;
  bool _submitting = false;
  bool _openingFile = false;

  String _templateError = '';
  String _reportError = '';

  List<DailyTemplateModel> _templates = [];
  List<StudentReportModel> _reports = [];

  final http.Client _client = http.Client();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadTemplates(),
      _loadReports(),
    ]);
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  Map<String, String> _headers(String token, {bool json = false}) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _loadingTemplates = true;
      _templateError = '';
    });

    try {
      final token = await _token();
      if (token == null) {
        setState(() {
          _templateError = 'Token topilmadi';
          _loadingTemplates = false;
        });
        return;
      }

      final res = await _client.get(
        Uri.parse('$_baseUrl/student/dailies'),
        headers: _headers(token),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        final List items = body['data'] ?? [];
        setState(() {
          _templates = items
              .map((e) => DailyTemplateModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loadingTemplates = false;
        });
      } else {
        setState(() {
          _templateError =
              body['message']?.toString() ?? 'Shablonlarni olishda xato';
          _loadingTemplates = false;
        });
      }
    } catch (e) {
      setState(() {
        _templateError = 'Xato: $e';
        _loadingTemplates = false;
      });
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _loadingReports = true;
      _reportError = '';
    });

    try {
      final token = await _token();
      if (token == null) {
        setState(() {
          _reportError = 'Token topilmadi';
          _loadingReports = false;
        });
        return;
      }

      final res = await _client.get(
        Uri.parse('$_baseUrl/student/reports'),
        headers: _headers(token),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        final List items = body['data'] ?? [];
        setState(() {
          _reports = items
              .map((e) => StudentReportModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loadingReports = false;
        });
      } else {
        setState(() {
          _reportError =
              body['message']?.toString() ?? 'Kundaliklarni olishda xato';
          _loadingReports = false;
        });
      }
    } catch (e) {
      setState(() {
        _reportError = 'Xato: $e';
        _loadingReports = false;
      });
    }
  }

  Future<void> _createReport(
      DailyTemplateModel template,
      String note,
      PlatformFile? file,
      ) async {
    setState(() => _submitting = true);

    try {
      final token = await _token();
      if (token == null) {
        _show('Token topilmadi', error: true);
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/student/reports'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['daily_template_id'] = template.id.toString();
      request.fields['status'] = 'submitted';
      request.fields['completion_percent'] = '100';

      request.fields['fields[0][field_key]'] = 'notes';
      request.fields['fields[0][field_label]'] = 'Izoh';
      request.fields['fields[0][field_value]'] = note;

      if (file != null && file.path != null && file.path!.trim().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'report_file',
            file.path!,
            filename: file.name,
          ),
        );

        request.fields['fields[1][field_key]'] = 'report_file_name';
        request.fields['fields[1][field_label]'] = 'Fayl nomi';
        request.fields['fields[1][field_value]'] = file.name;
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('CREATE REPORT STATUS: ${response.statusCode}');
      debugPrint('CREATE REPORT BODY: ${response.body}');

      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        _show('Kundalik yuborildi');
        await _loadReports();
        return;
      }

      if (response.statusCode == 422) {
        final errors = body['errors'];
        if (errors is Map) {
          final firstError = errors.values.isNotEmpty
              ? (errors.values.first as List).first.toString()
              : 'Validatsiya xatosi';
          _show(firstError, error: true);
          return;
        }
      }

      _show(
        body['message']?.toString() ??
            'Xato: ${response.statusCode}\n${response.body}',
        error: true,
      );
    } catch (e) {
      debugPrint('CREATE REPORT EXCEPTION: $e');
      _show('Xato: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _updateReport(
      StudentReportModel report,
      String note,
      PlatformFile? file,
      ) async {
    setState(() => _submitting = true);

    try {
      final token = await _token();
      if (token == null) {
        _show('Token topilmadi', error: true);
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/student/reports/${report.id}'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['_method'] = 'PUT';
      request.fields['status'] = 'submitted';
      request.fields['completion_percent'] = '100';

      request.fields['fields[0][field_key]'] = 'notes';
      request.fields['fields[0][field_label]'] = 'Izoh';
      request.fields['fields[0][field_value]'] = note;

      if (file != null && file.path != null && file.path!.trim().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'report_file',
            file.path!,
            filename: file.name,
          ),
        );

        request.fields['fields[1][field_key]'] = 'report_file_name';
        request.fields['fields[1][field_label]'] = 'Fayl nomi';
        request.fields['fields[1][field_value]'] = file.name;
      }

      final streamed = await request.send();
      final bodyText = await streamed.stream.bytesToString();

      Map<String, dynamic> body = {};
      if (bodyText.trim().isNotEmpty) {
        try {
          body = jsonDecode(bodyText) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        _show('Kundalik tahrirlandi');
        await _loadReports();
      } else if (streamed.statusCode == 422) {
        final errors = body['errors'];
        if (errors is Map) {
          final firstError = errors.values.isNotEmpty
              ? (errors.values.first as List).first.toString()
              : 'Validatsiya xatosi';
          _show(firstError, error: true);
          return;
        }
        _show('Validatsiya xatosi', error: true);
      } else {
        _show(
          body['message']?.toString() ??
              'Tahrirlashda xato: ${streamed.statusCode}\n$bodyText',
          error: true,
        );
      }
    } catch (e) {
      _show('Xato: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteReport(StudentReportModel report) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('O‘chirish'),
        content: const Text('Haqiqatan ham o‘chirasizmi?'),
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

    if (!ok) return;

    setState(() => _submitting = true);

    try {
      final token = await _token();
      if (token == null) {
        _show('Token topilmadi', error: true);
        return;
      }

      final res = await _client.delete(
        Uri.parse('$_baseUrl/student/reports/${report.id}'),
        headers: _headers(token),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        _show('Kundalik o‘chirildi');
        await _loadReports();
      } else {
        Map<String, dynamic> body = {};
        try {
          body = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {}
        _show(
          body['message']?.toString() ?? 'O‘chirishda xato',
          error: true,
        );
      }
    } catch (e) {
      _show('Xato: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openFile(String url) async {
    if (url.trim().isEmpty) {
      _show('Fayl manzili yo‘q', error: true);
      return;
    }

    setState(() => _openingFile = true);

    try {
      final token = await _token();
      final uri = Uri.tryParse(url);

      if (uri == null) {
        _show('Noto‘g‘ri fayl manzili', error: true);
        return;
      }

      final response = await _client.get(
        uri,
        headers: {
          'Accept': '*/*',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        _show('Faylni yuklab bo‘lmadi: ${response.statusCode}', error: true);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();

      String fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'file_${DateTime.now().millisecondsSinceEpoch}';

      if (fileName.trim().isEmpty) {
        fileName = 'file_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      if (!fileName.contains('.')) {
        fileName = '$fileName.pdf';
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final result = await OpenFilex.open(file.path);

      if (result.type != ResultType.done) {
        _show('Fayl ochilmadi: ${result.message}', error: true);
      }
    } catch (e) {
      _show('Faylni ochishda xato: $e', error: true);
    } finally {
      if (mounted) setState(() => _openingFile = false);
    }
  }

  void _show(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _openSubmitSheet(DailyTemplateModel template) async {
    final result = await showModalBottomSheet<_SheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(title: template.title),
    );

    if (result != null) {
      await _createReport(template, result.note, result.file);
    }
  }

  Future<void> _openEditSheet(StudentReportModel report) async {
    final result = await showModalBottomSheet<_SheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(
        title: report.templateTitle.isEmpty
            ? 'Kundalik #${report.id}'
            : report.templateTitle,
        initialNote: report.note,
      ),
    );

    if (result != null) {
      await _updateReport(report, result.note, result.file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageLoading = _submitting || _openingFile;

    return Scaffold(
            body: pageLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _init,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 14, 12, 8),
              child: Text(
                'Shablon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildTemplates(),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Text(
                'Mening kundaliklarim',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildReports(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplates() {
    if (_loadingTemplates) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_templateError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(_templateError)),
      );
    }
    if (_templates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Shablon topilmadi')),
      );
    }

    return Column(
      children: _templates.map((item) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(item.title),
            subtitle: Text(
              item.originalName.isEmpty ? 'Noma’lum fayl' : item.originalName,
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: item.fileUrl.trim().isEmpty
                      ? null
                      : () => _openFile(item.fileUrl),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: item.isActive ? () => _openSubmitSheet(item) : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReports() {
    if (_loadingReports) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_reportError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(_reportError)),
      );
    }
    if (_reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Kundaliklar topilmadi')),
      );
    }

    return Column(
      children: _reports.map((item) {
        final canEdit = item.status == 'pending';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.templateTitle.isEmpty
                      ? 'Kundalik #${item.id}'
                      : item.templateTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.note.isNotEmpty) Text(item.note),
                Text('Holat: ${item.statusLabel}'),
                if (item.submittedAt.isNotEmpty)
                  Text('Sana: ${item.submittedAt}'),
                if (item.rejectReason.isNotEmpty)
                  Text('Sabab: ${item.rejectReason}'),
                const SizedBox(height: 12),
                if (item.templateFileUrl.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 18),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Shablon fayli',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openFile(item.templateFileUrl),
                        child: const Text('Ochish'),
                      ),
                    ],
                  ),
                if (item.studentFileUrl.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 18),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Talaba yuborgan fayl',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openFile(item.studentFileUrl),
                        child: const Text('Ochish'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openEditSheet(item),
                      ),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteReport(item),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DailyTemplateModel {
  final int id;
  final String title;
  final String fileUrl;
  final String originalName;
  final bool isActive;

  DailyTemplateModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.originalName,
    required this.isActive,
  });

  factory DailyTemplateModel.fromJson(Map<String, dynamic> json) {
    return DailyTemplateModel(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? '').toString(),
      originalName: (json['original_name'] ?? '').toString(),
      isActive: _toBool(json['is_active']),
    );
  }
}

class StudentReportModel {
  final int id;
  final int templateId;
  final String templateTitle;
  final String status;
  final String submittedAt;
  final String note;
  final String rejectReason;
  final String templateFileUrl;
  final String studentFileUrl;

  StudentReportModel({
    required this.id,
    required this.templateId,
    required this.templateTitle,
    required this.status,
    required this.submittedAt,
    required this.note,
    required this.rejectReason,
    required this.templateFileUrl,
    required this.studentFileUrl,
  });

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Tasdiqlandi';
      case 'rejected':
        return 'Rad etildi';
      default:
        return 'Kutilmoqda';
    }
  }

  factory StudentReportModel.fromJson(Map<String, dynamic> json) {
    final fields = (json['fields'] as List?) ?? [];
    String noteValue = '';
    String uploadedFileUrl = '';

    for (final field in fields) {
      if (field is Map<String, dynamic>) {
        final key = (field['field_key'] ?? '').toString();
        final value = (field['field_value'] ?? '').toString();

        if (key == 'notes') {
          noteValue = value;
        }

        if (key == 'file' ||
            key == 'file_url' ||
            key == 'report_file' ||
            key == 'student_file' ||
            key == 'report_file_name') {
          if (value.startsWith('http://') || value.startsWith('https://')) {
            uploadedFileUrl = value;
          }
        }
      }
    }

    final template = json['template'] as Map<String, dynamic>?;

    final directStudentFileUrl = (json['file_url'] ?? '').toString();
    final nestedStudentFileUrl = (json['report_file_url'] ?? '').toString();
    final templateFile = (template?['file_url'] ?? '').toString();

    return StudentReportModel(
      id: _toInt(json['id']),
      templateId: _toInt(json['daily_template_id'] ?? json['template_id']),
      templateTitle: (template?['title'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      submittedAt: (json['submitted_at'] ?? '').toString(),
      note: noteValue,
      rejectReason: (json['supervisor_comment'] ?? '').toString(),
      templateFileUrl: templateFile,
      studentFileUrl: uploadedFileUrl.isNotEmpty
          ? uploadedFileUrl
          : (nestedStudentFileUrl.isNotEmpty
          ? nestedStudentFileUrl
          : directStudentFileUrl),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  final String title;
  final String initialNote;

  const _ReportSheet({
    required this.title,
    this.initialNote = '',
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  late final TextEditingController _controller;
  PlatformFile? _file;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Izoh yozing',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(_file?.name ?? 'Fayl tanlanmagan'),
              ),
              TextButton(
                onPressed: _pick,
                child: const Text('Fayl tanlash'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _SheetResult(
                    note: _controller.text.trim(),
                    file: _file,
                  ),
                );
              },
              child: const Text('Saqlash'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetResult {
  final String note;
  final PlatformFile? file;

  _SheetResult({
    required this.note,
    required this.file,
  });
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  final s = value.toString().toLowerCase();
  return s == 'true' || s == '1';
}