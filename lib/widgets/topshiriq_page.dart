import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ─────────────────────────────────────────────
// ENUM
// ─────────────────────────────────────────────

enum SubmissionStatus {
  submitted,
  pending,
  unknown;

  static SubmissionStatus fromString(String? value) {
    switch (value) {
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'pending':
        return SubmissionStatus.pending;
      default:
        return SubmissionStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case SubmissionStatus.submitted:
        return 'Topshirildi';
      case SubmissionStatus.pending:
        return 'Kutilmoqda';
      case SubmissionStatus.unknown:
        return 'Noma\'lum';
    }
  }

  Color get color {
    switch (this) {
      case SubmissionStatus.submitted:
        return const Color(0xFF16A34A);
      case SubmissionStatus.pending:
        return const Color(0xFFF59E0B);
      case SubmissionStatus.unknown:
        return const Color(0xFF64748B);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case SubmissionStatus.submitted:
        return const Color(0xFFDCFCE7);
      case SubmissionStatus.pending:
        return const Color(0xFFFEF3C7);
      case SubmissionStatus.unknown:
        return const Color(0xFFE2E8F0);
    }
  }

  IconData get icon {
    switch (this) {
      case SubmissionStatus.submitted:
        return Icons.check_circle_rounded;
      case SubmissionStatus.pending:
        return Icons.schedule_rounded;
      case SubmissionStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }
}

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────

class AppConstants {
  static const String baseUrl = 'https://shaxa.mycoder.uz/api';
  static const String tokenKey = 'token';
  static const int maxFileSizeBytes = 10 * 1024 * 1024;
  static const String storageBaseUrl = 'https://shaxa.mycoder.uz/storage';
}

// ─────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────

class AppColors {
  static const darkBg      = Color(0xFF07111D);
  static const darkSurface = Color(0xFF0F2336);
  static const darkCard    = Color(0xFF091825);
  static const darkBorder  = Color(0xFF1A3047);
  static const darkSubtext = Color(0xFF4E7A9B);
  static const accent      = Color(0xFF2D7DD2);
  static const accentLight = Color(0xFF5B9FE8);
  static const pageBg      = Color(0xFFF1F5F9);
  static const green       = Color(0xFF16A34A);
  static const greenBg     = Color(0xFFDCFCE7);
  static const amber       = Color(0xFFF59E0B);
  static const amberBg     = Color(0xFFFEF3C7);
}

// ─────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────

class TopshiriqlarPage extends StatefulWidget {
  const TopshiriqlarPage({super.key});

  @override
  State<TopshiriqlarPage> createState() => _TopshiriqlarPageState();
}

class _TopshiriqlarPageState extends State<TopshiriqlarPage> {

  Future<String?> downloadAndCacheFile(String url) async {
    try {
      if (url.trim().isEmpty) {
        _showSnack('Fayl manzili topilmadi.', Colors.red);
        return null;
      }

      _showSnack('Fayl tekshirilmoqda...', AppColors.accent);

      final dir = await getApplicationDocumentsDirectory();
      final fileName = Uri.parse(url).pathSegments.isNotEmpty
          ? Uri.parse(url).pathSegments.last
          : 'file';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        _showSnack('Fayl oldin yuklangan. Ochilmoqda...', AppColors.green);
        return filePath;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': '*/*'},
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        _showSnack('Fayl yuklab olindi ✅', AppColors.green);
        return filePath;
      }

      _showSnack(
        'Yuklab bo‘lmadi. Status: ${response.statusCode}',
        Colors.red,
      );
      return null;
    } catch (e) {
      _showSnack('Yuklashda xato: $e', Colors.red);
      return null;
    }
  }

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _error = '';
  List<StudentTask> _tasks = [];
  String? _downloadedTaskFilePath;
  String? _downloadedSubmissionPath;
  final http.Client _httpClient = http.Client();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }


  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<bool> _requestDownloadPermission() async {
    if (!mounted) return false;
    if (Theme.of(context).platform == TargetPlatform.android) {
      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;
      final manage = await Permission.manageExternalStorage.request();
      if (manage.isGranted) return true;
      if (storage.isPermanentlyDenied || manage.isPermanentlyDenied) {
        _showSnack('Permission rad etilgan. Settings ichidan ruxsat bering.', Colors.red);
        await openAppSettings();
      }
      return false;
    }
    return true;
  }

  String? _buildFileUrl(String? filePath) {
    if (filePath == null || filePath.trim().isEmpty) return null;
    final path = filePath.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${AppConstants.storageBaseUrl}/$path';
  }

  String _extractFileName(String path) {
    final parts = path.replaceAll('\\', '/').split('/');
    return parts.isNotEmpty ? parts.last : 'file';
  }
  Future<String?> _downloadFile(String? filePath) async {
    final url = _buildFileUrl(filePath);
    if (url == null) {
      _showSnack('Fayl manzili topilmadi.', Colors.red);
      return null;
    }

    final allowed = await _requestDownloadPermission();
    if (!allowed) {
      _showSnack('Yuklab olish uchun ruxsat kerak.', Colors.red);
      return null;
    }

    try {
      _showSnack('Fayl yuklab olinmoqda...', AppColors.accent);

      final completer = Completer<String?>();

      FileDownloader.downloadFile(
        url: url,
        name: _extractFileName(filePath ?? url),
        downloadDestination: DownloadDestinations.appFiles,
        notificationType: NotificationType.all,
        onProgress: (name, progress) {
          debugPrint('Downloading $name : ${progress.toStringAsFixed(0)}%');
        },
        onDownloadCompleted: (path) async {
          _showSnack('Fayl yuklab olindi ✅', AppColors.green);
          completer.complete(path);
        },
        onDownloadError: (err) {
          _showSnack('Yuklab olishda xato: $err', Colors.red);
          completer.complete(null);
        },
      );

      return await completer.future;
    } catch (e) {
      _showSnack('Yuklab olishda xato: $e', Colors.red);
      return null;
    }
  }
  // Future<void> _downloadFile(String? filePath) async {
  //   final url = _buildFileUrl(filePath);
  //   if (url == null) {
  //     _showSnack('Fayl manzili topilmadi.', Colors.red);
  //     return;
  //   }
  //   final allowed = await _requestDownloadPermission();
  //   if (!allowed) {
  //     _showSnack('Yuklab olish uchun ruxsat kerak.', Colors.red);
  //     return;
  //   }
  //   try {
  //     _showSnack('Fayl yuklab olinmoqda...', AppColors.accent);
  //     FileDownloader.downloadFile(
  //       url: url,
  //       name: _extractFileName(filePath ?? url),
  //       downloadDestination: DownloadDestinations.appFiles,
  //       notificationType: NotificationType.all,
  //       onProgress: (name, progress) =>
  //           debugPrint('Downloading $name : ${progress.toStringAsFixed(0)}%'),
  //       onDownloadCompleted: (path) async {
  //         _showSnack('Fayl yuklab olindi ✅', AppColors.green);
  //         if (path.isNotEmpty) await OpenFilex.open(path);
  //       },
  //       onDownloadError: (err) =>
  //           _showSnack('Yuklab olishda xato: $err', Colors.red),
  //     );
  //   } catch (e) {
  //     _showSnack('Yuklab olishda xato: $e', Colors.red);
  //   }
  // }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = ''; });
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        _setError('Token topilmadi. Qayta login qiling.');
        return;
      }
      final response = await _httpClient.get(
        Uri.parse('${AppConstants.baseUrl}/student/tasks'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as List<dynamic>? ?? [];
        setState(() {
          _tasks = data
              .map((e) => StudentTask.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _setError('Sessiya tugagan. Qayta login qiling.');
      } else {
        _setError('Topshiriqlarni yuklashda xato: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      _setError('Tarmoq xatosi: ${e.message}');
    } catch (e) {
      _setError('Kutilmagan xato: $e');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() { _error = message; _isLoading = false; });
  }
  Future<PlatformFile?> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        withData: true, // MUHIM
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;

      if (file.size <= 0) {
        _showSnack('Fayl bo‘sh yoki noto‘g‘ri.', Colors.red);
        return null;
      }

      if (file.size > AppConstants.maxFileSizeBytes) {
        final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(2);
        _showSnack('Fayl juda katta: $sizeMb MB. Maks. 10 MB.', Colors.red);
        return null;
      }

      return file;
    } catch (e) {
      _showSnack('Fayl tanlashda xato: $e', Colors.red);
      return null;
    }
  }
  // Future<PlatformFile?> _pickFile() async {
  //   try {
  //     final result = await FilePicker.platform.pickFiles(
  //       type: FileType.custom,
  //       allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
  //       withData: false,
  //       withReadStream: false,
  //     );
  //     if (result == null || result.files.isEmpty) return null;
  //     final file = result.files.first;
  //     if (file.path == null || file.path!.isEmpty) {
  //       _showSnack('Fayl yo\'li topilmadi.', Colors.red);
  //       return null;
  //     }
  //     if (file.size <= 0) {
  //       _showSnack('Fayl bo\'sh yoki noto\'g\'ri.', Colors.red);
  //       return null;
  //     }
  //     if (file.size > AppConstants.maxFileSizeBytes) {
  //       final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(2);
  //       _showSnack('Fayl juda katta: $sizeMb MB. Maks. 10 MB.', Colors.red);
  //       return null;
  //     }
  //     return file;
  //   } catch (e) {
  //     _showSnack('Fayl tanlashda xato: $e', Colors.red);
  //     return null;
  //   }
  // }

  Future<void> _openSubmitDialog(StudentTask task) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => _TaskDetailBottomSheet(
        task: task,
        isSubmitting: _isSubmitting,
        maxFileSizeBytes: AppConstants.maxFileSizeBytes,
        onPickFile: _pickFile,
        onSubmit: ({required String feedback, PlatformFile? file}) async {
          Navigator.of(ctx).pop();
          await _submitTask(taskId: task.id, feedback: feedback, file: file);
        },
        onDownloadTaskFile: () => _downloadFile(task.taskFilePath),
        onDownloadSubmissionFile: () => _downloadFile(task.submissionFilePath),
        // onDownloadTaskFile: () {
        //   final url = _buildFileUrl(task.taskFilePath);
        //   if (url == null) {
        //     _showSnack('Topshiriq fayli topilmadi.', Colors.red);
        //     return Future.value(null);
        //   }
        //   return downloadAndCacheFile(url);
        // },
        //
        // onDownloadSubmissionFile: () {
        //   final url = _buildFileUrl(task.submissionFilePath);
        //   if (url == null) {
        //     _showSnack('Yuborilgan fayl topilmadi.', Colors.red);
        //     return Future.value(null);
        //   }
        //   return downloadAndCacheFile(url);
        // },
        // onDownloadTaskFile: () => downloadAndCacheFile(task.taskFilePath!),
        // onDownloadSubmissionFile: () => downloadAndCacheFile(task.submissionFilePath!),

        showSnack: _showSnack,
        formatDate: _formatDate,
      ),
    );
  }
  Future<void> _submitTask({
    required int taskId,
    required String feedback,
    PlatformFile? file,
  }) async {
    if (!mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        _showSnack('Token topilmadi.', Colors.red);
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/student/tasks'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['task_id'] = taskId.toString()
        ..fields['feedback'] = feedback.trim();

      if (file != null) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              file.bytes!,
              filename: file.name,
            ),
          );
        } else {
          _showSnack('Fayl bytes topilmadi.', Colors.red);
          return;
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('POST status: ${response.statusCode}');
      debugPrint('POST body: ${response.body}');

      if (!mounted) return;

      switch (response.statusCode) {
        case 200:
        case 201:
          _showSnack('Topshiriq muvaffaqiyatli yuborildi ✅', AppColors.green);
          await _loadTasks();
          return;
        case 401:
          _showSnack('Sessiya tugagan. Qayta login qiling.', Colors.red);
          return;
        case 413:
          _showSnack('Server faylni qabul qilmadi. 10 MB dan kichik fayl yuboring.', Colors.red);
          return;
        case 422:
          _showSnack(_parse422(response.body), Colors.red);
          return;
        default:
          _showSnack(_parseErrorMessage(response.body, response.statusCode), Colors.red);
      }
    } on http.ClientException catch (e) {
      _showSnack('Tarmoq xatosi: ${e.message}', Colors.red);
    } catch (e) {
      _showSnack('Kutilmagan xato: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  // Future<void> _submitTask({
  //   required int taskId,
  //   required String feedback,
  //   PlatformFile? file,
  // }) async {
  //   if (!mounted) return;
  //   if (file != null) {
  //     if (file.path == null || file.path!.isEmpty) {
  //       _showSnack('Fayl yo\'li topilmadi.', Colors.red);
  //       return;
  //     }
  //     if (file.size <= 0) {
  //       _showSnack('Fayl noto\'g\'ri yoki bo\'sh.', Colors.red);
  //       return;
  //     }
  //     if (file.size > AppConstants.maxFileSizeBytes) {
  //       final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(2);
  //       _showSnack('Fayl juda katta: $sizeMb MB. Maks. 10 MB.', Colors.red);
  //       return;
  //     }
  //   }
  //
  //   setState(() => _isSubmitting = true);
  //
  //   try {
  //     final token = await _getToken();
  //     if (token == null || token.isEmpty) {
  //       _showSnack('Token topilmadi.', Colors.red);
  //       return;
  //     }
  //
  //     final request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse('${AppConstants.baseUrl}/student/tasks'),
  //     )
  //       ..headers['Authorization'] = 'Bearer $token'
  //       ..headers['Accept'] = 'application/json'
  //       ..fields['task_id'] = taskId.toString()
  //       ..fields['feedback'] = feedback;
  //
  //     if (file != null && file.path != null) {
  //       request.files.add(await http.MultipartFile.fromPath(
  //         'file', file.path!, filename: file.name,
  //       ));
  //     }
  //
  //     final response = await http.Response.fromStream(
  //       await _httpClient.send(request),
  //     );
  //
  //     if (!mounted) return;
  //
  //     switch (response.statusCode) {
  //       case 200:
  //       case 201:
  //         _showSnack('Topshiriq muvaffaqiyatli yuborildi ✅', AppColors.green);
  //         await _loadTasks();
  //         return;
  //       case 401:
  //         _showSnack('Sessiya tugagan. Qayta login qiling.', Colors.red);
  //         return;
  //       case 413:
  //         _showSnack('Server faylni qabul qilmadi. 10 MB dan kichik fayl yuboring.', Colors.red);
  //         return;
  //       case 422:
  //         _showSnack(_parse422(response.body), Colors.red);
  //         return;
  //       default:
  //         _showSnack(_parseErrorMessage(response.body, response.statusCode), Colors.red);
  //     }
  //   } on http.ClientException catch (e) {
  //     _showSnack('Tarmoq xatosi: ${e.message}', Colors.red);
  //   } catch (e) {
  //     _showSnack('Kutilmagan xato: $e', Colors.red);
  //   } finally {
  //     if (mounted) setState(() => _isSubmitting = false);
  //   }
  // }

  String _parse422(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['errors'] is Map<String, dynamic>) {
        final errors = json['errors'] as Map<String, dynamic>;
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
      return json['message']?.toString() ?? 'Ma\'lumotlarda xato bor.';
    } catch (_) {
      return 'Ma\'lumotlarda xato bor.';
    }
  }

  String _parseErrorMessage(String body, int code) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message']?.toString() ?? 'Yuborishda xato: $code';
    } catch (_) {
      return 'Yuborishda xato: $code';
    }
  }

  void _showSnack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw.replaceFirst(' ', 'T'));
      return '${dt.day.toString().padLeft(2, '0')}.'
          '${dt.month.toString().padLeft(2, '0')}.'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, size: 32, color: Colors.red),
                ),
                const SizedBox(height: 16),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loadTasks,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Qayta urinish'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Topshiriqlar mavjud emas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Rahbaringiz topshiriq yuklaganida\nbu yerda ko\'rinadi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
            ),
          ],
        ),
      );
    }

    final submittedCount = _tasks
        .where((t) => SubmissionStatus.fromString(t.submissionStatus) == SubmissionStatus.submitted)
        .length;
    final pendingCount = _tasks
        .where((t) => SubmissionStatus.fromString(t.submissionStatus) == SubmissionStatus.pending)
        .length;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadTasks,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Topshiriqlar',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_tasks.length} ta',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: Row(
                children: [
                  _StatChip(
                    label: 'Topshirildi',
                    count: submittedCount,
                    color: AppColors.green,
                    bg: AppColors.greenBg,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Kutilmoqda',
                    count: pendingCount,
                    color: AppColors.amber,
                    bg: AppColors.amberBg,
                    icon: Icons.schedule_rounded,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final task = _tasks[index];
                  return _SimpleTaskCard(
                    task: task,
                    index: index,
                    formatDate: _formatDate,
                    onViewTask: () => _openSubmitDialog(task),
                  );
                },
                childCount: _tasks.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STAT CHIP
// ─────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TASK CARD
// ─────────────────────────────────────────────

class _SimpleTaskCard extends StatelessWidget {
  const _SimpleTaskCard({
    required this.task,
    required this.index,
    required this.formatDate,
    required this.onViewTask,
  });

  final StudentTask task;
  final int index;
  final String Function(String?) formatDate;
  final VoidCallback onViewTask;

  @override
  Widget build(BuildContext context) {
    final status = SubmissionStatus.fromString(task.submissionStatus);

    bool isUrgent = false;
    if (task.dueDate != null) {
      try {
        final due = DateTime.parse(task.dueDate!.replaceFirst(' ', 'T'));
        final diff = due.difference(DateTime.now());
        isUrgent = !diff.isNegative && diff.inHours <= 24;
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent
              ? AppColors.amber.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10, top: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                          if (task.groupName != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              task.groupName!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: status.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, size: 12, color: status.color),
                          const SizedBox(width: 4),
                          Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: status.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetaItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Muddat',
                      value: formatDate(task.dueDate),
                      urgent: isUrgent,
                    ),
                    if (task.supervisorName != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MetaItem(
                          icon: Icons.person_rounded,
                          label: 'Rahbar',
                          value: task.supervisorName!,
                        ),
                      ),
                    ],
                  ],
                ),
                if (task.score != null) ...[
                  const SizedBox(height: 8),
                  _MetaItem(
                    icon: Icons.star_rounded,
                    label: 'Ball',
                    value: task.score!,
                    iconColor: AppColors.amber,
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: onViewTask,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Topshiriqni ko\'rish',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    task.createdAt != null ? 'Berilgan: ${formatDate(task.createdAt)}' : '',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
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

// ─────────────────────────────────────────────
// META ITEM
// ─────────────────────────────────────────────

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
    this.urgent = false,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool urgent;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = urgent ? AppColors.amber : (iconColor ?? const Color(0xFF94A3B8));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: urgent ? AppColors.amber : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM SHEET
// ─────────────────────────────────────────────
class _TaskDetailBottomSheet extends StatefulWidget {
  const _TaskDetailBottomSheet({
    required this.task,
    required this.isSubmitting,
    required this.maxFileSizeBytes,
    required this.onPickFile,
    required this.onSubmit,
    required this.onDownloadTaskFile,
    required this.onDownloadSubmissionFile,
    required this.showSnack,
    required this.formatDate,
  });

  final StudentTask task;
  final bool isSubmitting;
  final int maxFileSizeBytes;
  final Future<PlatformFile?> Function() onPickFile;
  final Future<void> Function({
  required String feedback,
  PlatformFile? file,
  }) onSubmit;

  // IKKALASI HAM endi path qaytaradi
  final Future<String?> Function() onDownloadTaskFile;
  final Future<String?> Function() onDownloadSubmissionFile;

  final void Function(String text, Color color) showSnack;
  final String Function(String?) formatDate;

  @override
  State<_TaskDetailBottomSheet> createState() =>
      _TaskDetailBottomSheetState();
}

class _TaskDetailBottomSheetState extends State<_TaskDetailBottomSheet> {
  late final TextEditingController _feedbackController;

  PlatformFile? _selectedFile;
  String? _downloadedTaskFilePath;
  String? _downloadedSubmissionPath;

  bool _isTaskExpired(String? dueDate) {
    if (dueDate == null || dueDate.trim().isEmpty) return false;

    try {
      final due = DateTime.parse(dueDate.replaceFirst(' ', 'T')).toLocal();
      return DateTime.now().isAfter(due);
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
  Future<void> _openDownloadedFile(String path) async {
    try {
      final result = await OpenFilex.open(path);

      if (result.type != ResultType.done) {
        widget.showSnack(
          'Faylni ochib bo‘lmadi: ${result.message}',
          Colors.red,
        );
      }
    } catch (e) {
      widget.showSnack('Faylni ochishda xato: $e', Colors.red);
    }
  }
  Future<void> _handleDownloadTaskFile() async {
    final path = await widget.onDownloadTaskFile();
    if (!mounted) return;

    if (path != null && path.isNotEmpty) {
      setState(() {
        _downloadedTaskFilePath = path;
      });
    }
  }

  Future<void> _handleDownloadSubmissionFile() async {
    final path = await widget.onDownloadSubmissionFile();
    if (!mounted) return;

    if (path != null && path.isNotEmpty) {
      setState(() {
        _downloadedSubmissionPath = path;
      });
    }
  }

  Future<void> _handlePickFile() async {
    final bool isExpired = _isTaskExpired(widget.task.dueDate);

    if (isExpired) {
      widget.showSnack(
        'Topshiriq muddati o‘tgan. Fayl biriktirib bo‘lmaydi.',
        Colors.red,
      );
      return;
    }

    final file = await widget.onPickFile();
    if (!mounted) return;

    if (file != null) {
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _handleSubmit() async {
    final bool isExpired = _isTaskExpired(widget.task.dueDate);

    if (isExpired) {
      widget.showSnack(
        'Topshiriq muddati o‘tgan. Endi yuborib bo‘lmaydi.',
        Colors.red,
      );
      return;
    }

    final file = _selectedFile;

    if (file != null && file.size > widget.maxFileSizeBytes) {
      widget.showSnack(
        'Fayl 10 MB dan katta bo‘lmasligi kerak.',
        Colors.red,
      );
      return;
    }

    await widget.onSubmit(
      feedback: _feedbackController.text.trim(),
      file: file,
    );

    if (!mounted) return;

    setState(() {
      _selectedFile = null;
      _feedbackController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = _isTaskExpired(widget.task.dueDate);
    final status = SubmissionStatus.fromString(widget.task.submissionStatus);

    final selectedFileText = _selectedFile == null
        ? (isExpired ? 'Muddati o‘tgan' : 'Fayl biriktirish')
        : '${_selectedFile!.name}  •  ${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB';

    final hasFeedback =
        widget.task.feedback != null && widget.task.feedback!.trim().isNotEmpty;

    final hasSubmissionFile =
        widget.task.submissionFilePath != null &&
            widget.task.submissionFilePath!.trim().isNotEmpty;

    final hasTaskFile =
        widget.task.taskFilePath != null &&
            widget.task.taskFilePath!.trim().isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.supervisorName ?? 'Rahbar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (widget.task.groupName != null)
                          Text(
                            widget.task.groupName!,
                            style: const TextStyle(
                              color: AppColors.darkSubtext,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status.backgroundColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: status.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.icon, size: 12, color: status.color),
                        const SizedBox(width: 4),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (widget.task.dueDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpired
                            ? Icons.lock_clock_rounded
                            : Icons.access_time_rounded,
                        size: 15,
                        color: isExpired
                            ? Colors.redAccent
                            : AppColors.darkSubtext,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isExpired
                            ? 'Muddat tugagan: '
                            : 'Topshirish muddati: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired
                              ? Colors.redAccent
                              : AppColors.darkSubtext,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.formatDate(widget.task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isExpired
                                ? Colors.redAccent
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ChatBubble(
                        isRight: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if (widget.task.description != null &&
                                widget.task.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.task.description!,
                                style: const TextStyle(
                                  color: Color(0xFF93B8D4),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                widget.formatDate(widget.task.createdAt),
                                style: const TextStyle(
                                  color: AppColors.darkSubtext,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasTaskFile) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _ChatFileBubble(
                            fileName: _fileNameFromPath(widget.task.taskFilePath!),
                            caption: 'Topshiriq fayli',
                            isRight: false,
                            onTap: _handleDownloadTaskFile,
                            showOpenButton: _downloadedTaskFilePath != null,
                            onOpen: _downloadedTaskFilePath != null
                                ? () async => _openDownloadedFile(_downloadedTaskFilePath!)
                                : null,
                          ),
                        ),
                      ],


                      if (hasFeedback || hasSubmissionFile) ...[
                        const SizedBox(height: 16),

                        if (hasFeedback)
                          Align(
                            alignment: Alignment.centerRight,
                            child: _ChatBubble(
                              isRight: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.task.feedback!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      widget.formatDate(widget.task.submittedAt),
                                      style: const TextStyle(
                                        color: Color(0xFF93C5FD),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (hasSubmissionFile) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _ChatFileBubble(
                              fileName: _fileNameFromPath(widget.task.submissionFilePath!),
                              caption: _downloadedSubmissionPath != null
                                  ? 'Yuborilgan fayl'
                                  : 'Yuborilgan fayl',
                              isRight: true,
                              onTap: _handleDownloadSubmissionFile,
                              showOpenButton: _downloadedSubmissionPath != null,
                              onOpen: _downloadedSubmissionPath != null
                                  ? () async => _openDownloadedFile(_downloadedSubmissionPath!)
                                  : null,
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(top: BorderSide(color: AppColors.darkBorder)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _feedbackController,
                    enabled: !isExpired && !widget.isSubmitting,
                    maxLines: 3,
                    minLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: isExpired
                          ? 'Topshiriq muddati o‘tgan'
                          : 'Izoh yozing...',
                      hintStyle: const TextStyle(
                        color: AppColors.darkSubtext,
                      ),
                      filled: true,
                      fillColor: AppColors.darkCard,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.darkBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: (isExpired || widget.isSubmitting)
                        ? null
                        : _handlePickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedFile != null
                              ? AppColors.accent.withValues(alpha: 0.5)
                              : AppColors.darkBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedFile != null
                                ? Icons.insert_drive_file_rounded
                                : Icons.attach_file_rounded,
                            color: _selectedFile != null
                                ? AppColors.accent
                                : AppColors.darkSubtext,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedFileText,
                              style: TextStyle(
                                color: _selectedFile != null
                                    ? Colors.white
                                    : AppColors.darkSubtext,
                                fontSize: 13,
                                fontWeight: _selectedFile != null
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedFile != null)
                            GestureDetector(
                              onTap: () => setState(() => _selectedFile = null),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: (widget.isSubmitting || isExpired)
                          ? null
                          : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor: isExpired
                            ? Colors.redAccent.withValues(alpha: 0.35)
                            : null,
                      ),
                      child: widget.isSubmitting
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        isExpired
                            ? 'Muddati o‘tgan'
                            : 'Topshiriq yuborish',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fileNameFromPath(String path) {
    final parts = path.replaceAll('\\', '/').split('/');
    return parts.isNotEmpty ? parts.last : path;
  }
}
// ─────────────────────────────────────────────
// CHAT BUBBLE
// ─────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.isRight, required this.child});

  final bool isRight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRight ? const Color(0xFF1E4D7B) : AppColors.darkSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isRight ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isRight ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _ChatFileBubble extends StatelessWidget {
  const _ChatFileBubble({
    required this.fileName,
    required this.caption,
    required this.isRight,
    required this.onTap,
    this.showOpenButton = false,
    this.onOpen,
  });

  final String fileName;
  final String caption;
  final bool isRight;
  final VoidCallback onTap;
  final bool showOpenButton;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isRight ? const Color(0xFF214F86) : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRight
              ? const Color(0xFF3166A7)
              : AppColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isRight
                    ? const Color(0xFF2D5E99)
                    : AppColors.darkCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Color(0xFF7DB7FF),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: const TextStyle(
                    color: AppColors.darkSubtext,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (showOpenButton && onOpen != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onOpen,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.visibility_rounded,
                  color: Color(0xFFC7DCFF),
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHAT FILE BUBBLE
// ─────────────────────────────────────────────

// class _ChatFileBubble extends StatelessWidget {
//   const _ChatFileBubble({
//     required this.fileName,
//     required this.caption,
//     required this.isRight,
//     required this.onTap,
//   });
//
//   final String fileName;
//   final String caption;
//   final bool isRight;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isRight ? const Color(0xFF1E4D7B) : AppColors.darkSurface,
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(16),
//             topRight: const Radius.circular(16),
//             bottomLeft: isRight ? const Radius.circular(16) : const Radius.circular(4),
//             bottomRight: isRight ? const Radius.circular(4) : const Radius.circular(16),
//           ),
//           border: Border.all(color: AppColors.darkBorder),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 38, height: 38,
//               decoration: BoxDecoration(
//                 color: AppColors.accent.withValues(alpha: 0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.download_rounded, color: AppColors.accentLight, size: 20),
//             ),
//             const SizedBox(width: 10),
//             Flexible(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     fileName,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     caption,
//                     style: const TextStyle(color: AppColors.darkSubtext, fontSize: 11),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────

class StudentTask {
  final int id;
  final String title;
  final String? description;
  final String? dueDate;
  final String? createdAt;
  final String taskStatus;
  final String? taskFilePath;
  final String submissionStatus;
  final String? submissionFilePath;
  final String? score;
  final String? feedback;
  final String? submittedAt;
  final String? supervisorName;
  final String? groupName;

  const StudentTask({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.createdAt,
    required this.taskStatus,
    this.taskFilePath,
    required this.submissionStatus,
    this.submissionFilePath,
    this.score,
    this.feedback,
    this.submittedAt,
    this.supervisorName,
    this.groupName,
  });

  factory StudentTask.fromJson(Map<String, dynamic> json) {
    final supervisor = json['supervisor'] as Map<String, dynamic>?;
    final group = json['group'] as Map<String, dynamic>?;

    return StudentTask(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      dueDate: json['due_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      taskStatus: json['task_status']?.toString() ?? '',
      taskFilePath: json['task_file_path']?.toString(),
      submissionStatus: json['submission_status']?.toString() ?? 'pending',
      submissionFilePath: json['submission_file_path']?.toString(),
      score: json['score']?.toString(),
      feedback: json['feedback']?.toString(),
      submittedAt: json['submitted_at']?.toString(),
      supervisorName: supervisor?['name']?.toString(),
      groupName: group?['name']?.toString(),
    );
  }
}