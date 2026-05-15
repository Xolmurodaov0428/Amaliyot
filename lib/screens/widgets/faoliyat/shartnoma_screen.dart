import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ShartnomaScreen extends StatefulWidget {
  const ShartnomaScreen({super.key});

  @override
  State<ShartnomaScreen> createState() => _ShartnomaScreenState();
}

class _ShartnomaScreenState extends State<ShartnomaScreen> {
  static const String _baseUrl = 'https://shaxa.mycoder.uz/api/student/documents';

  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;
  List<StudentDocumentModel> documents = [];

  @override
  void initState() {
    super.initState();
    fetchDocuments();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token;
  }

  String _todayDate() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> fetchDocuments() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final token = await _getToken();

      if (token == null) {
        setState(() {
          errorMessage = 'Token topilmadi. Qaytadan login qiling.';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final List data = jsonData['data'] ?? [];

        setState(() {
          documents = data
              .map((e) => StudentDocumentModel.fromJson(e as Map<String, dynamic>))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Hujjatlarni olishda xatolik: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Xatolik yuz berdi: $e';
        isLoading = false;
      });
    }
  }

  String getFileName(String path) {
    if (path.trim().isEmpty) return 'Noma’lum fayl';
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  String formatDate(String raw) {
    if (raw.trim().isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '$d.$m.$y';
    } catch (_) {
      return raw;
    }
  }

  Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path!;
    }
    return null;
  }

  Future<void> openFileUrl(String fileUrl) async {
    if (fileUrl.trim().isEmpty) {
      _showSnack('Fayl manzili topilmadi.', isError: true);
      return;
    }

    final uri = Uri.tryParse(fileUrl);
    if (uri == null) {
      _showSnack('Noto‘g‘ri fayl manzili.', isError: true);
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showSnack('Faylni ochib bo‘lmadi.', isError: true);
    }
  }

  Future<void> uploadDocument({
    String? contractPath,
    String? orderPath,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        _showSnack('Token topilmadi. Qaytadan login qiling.', isError: true);
        return;
      }

      setState(() {
        isSubmitting = true;
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_baseUrl),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['document_date'] = _todayDate();

      if (contractPath != null && contractPath.trim().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('contract_file', contractPath),
        );
      }

      if (orderPath != null && orderPath.trim().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('order_file', orderPath),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack('Hujjat muvaffaqiyatli yuklandi.');
        await fetchDocuments();
      } else {
        _showSnack(
          'Yuklashda xatolik: ${response.statusCode}\n$body',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Upload xatoligi: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> updateDocument({
    required int id,
    String? contractPath,
    String? orderPath,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        _showSnack('Token topilmadi. Qaytadan login qiling.', isError: true);
        return;
      }

      setState(() {
        isSubmitting = true;
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/$id'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT';
      request.fields['document_date'] = _todayDate();

      if (contractPath != null && contractPath.trim().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('contract_file', contractPath),
        );
      }

      if (orderPath != null && orderPath.trim().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('order_file', orderPath),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _showSnack('Hujjat muvaffaqiyatli yangilandi.');
        await fetchDocuments();
      } else {
        _showSnack(
          'Yangilashda xatolik: ${response.statusCode}\n$body',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Update xatoligi: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      final token = await _getToken();

      if (token == null) {
        _showSnack('Token topilmadi. Qaytadan login qiling.', isError: true);
        return;
      }

      setState(() {
        isSubmitting = true;
      });

      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSnack('Hujjat o‘chirildi.');
        await fetchDocuments();
      } else {
        _showSnack(
          'O‘chirishda xatolik: ${response.statusCode}\n${response.body}',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Delete xatoligi: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> showAddDocumentDialog() async {
    String? contractPath;
    String? orderPath;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Hujjat qo‘shish'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.15)),
                      ),
                      child: Text(
                        'Sana avtomatik yuboriladi: ${formatDate(_todayDate())}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilePickBox(
                      title: 'Shartnoma fayli',
                      filePath: contractPath,
                      onPick: () async {
                        final picked = await pickFile();
                        if (picked != null) {
                          setLocalState(() => contractPath = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _FilePickBox(
                      title: 'Buyruq fayli',
                      filePath: orderPath,
                      onPick: () async {
                        final picked = await pickFile();
                        if (picked != null) {
                          setLocalState(() => orderPath = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Bekor qilish'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    if (contractPath == null ||
                        contractPath!.trim().isEmpty) {
                      _showSnack(
                        'Shartnoma faylini tanlang.',
                        isError: true,
                      );
                      return;
                    }

                    if (orderPath == null || orderPath!.trim().isEmpty) {
                      _showSnack(
                        'Buyruq faylini tanlang.',
                        isError: true,
                      );
                      return;
                    }

                    Navigator.pop(context);

                    await uploadDocument(
                      contractPath: contractPath,
                      orderPath: orderPath,
                    );
                  },
                  child: const Text('Saqlash'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showEditDocumentDialog(StudentDocumentModel doc) async {
    String? contractPath;
    String? orderPath;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Hujjatni tahrirlash'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.15)),
                      ),
                      child: Text(
                        'Yangilanganda sana avtomatik bugungi sana bo‘ladi: ${formatDate(_todayDate())}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilePickBox(
                      title: 'Yangi shartnoma fayli',
                      filePath: contractPath,
                      currentFileName: doc.contractFile.isNotEmpty
                          ? getFileName(doc.contractFile)
                          : null,
                      onPick: () async {
                        final picked = await pickFile();
                        if (picked != null) {
                          setLocalState(() => contractPath = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _FilePickBox(
                      title: 'Yangi buyruq fayli',
                      filePath: orderPath,
                      currentFileName:
                      doc.orderFile.isNotEmpty ? getFileName(doc.orderFile) : null,
                      onPick: () async {
                        final picked = await pickFile();
                        if (picked != null) {
                          setLocalState(() => orderPath = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Bekor qilish'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    if (contractPath == null ||
                        contractPath!.trim().isEmpty) {
                      _showSnack(
                        'Yangi shartnoma faylini tanlang.',
                        isError: true,
                      );
                      return;
                    }

                    if (orderPath == null || orderPath!.trim().isEmpty) {
                      _showSnack(
                        'Yangi buyruq faylini tanlang.',
                        isError: true,
                      );
                      return;
                    }

                    Navigator.pop(context);

                    await updateDocument(
                      id: doc.id,
                      contractPath: contractPath,
                      orderPath: orderPath,
                    );
                  },
                  child: const Text('Yangilash'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<void> showDeleteDialog(StudentDocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hujjatni o‘chirish'),
          content: Text(
            'ID ${doc.id} bo‘lgan hujjatni o‘chirmoqchimisiz?',
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
        );
      },
    );

    if (confirmed == true) {
      await deleteDocument(doc.id);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Widget _buildFileCard({
    required String title,
    required String filePath,
    required String fileUrl,
    required IconData icon,
    required Color color,
  }) {
    final hasFile = filePath.trim().isNotEmpty && fileUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasFile ? getFileName(filePath) : 'Fayl mavjud emas',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                if (hasFile) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => openFileUrl(fileUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Ochish'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return RefreshIndicator(
        onRefresh: fetchDocuments,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 500,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 52,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchDocuments,
                        child: const Text('Qayta urinish'),
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

    if (documents.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchDocuments,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 500,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 56,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Hujjatlar topilmadi',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.folder_copy_outlined,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Shartnoma va Buyruq',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await showEditDocumentDialog(doc);
                        } else if (value == 'delete') {
                          await showDeleteDialog(doc);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Tahrirlash'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('O‘chirish'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Sana: ${formatDate(doc.documentDate)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                // Text(
                //   'Talaba ID: ${doc.studentId}',
                //   style: const TextStyle(
                //     fontSize: 13,
                //     color: Colors.black54,
                //   ),
                // ),
                _buildFileCard(
                  title: 'Shartnoma',
                  filePath: doc.contractFile,
                  fileUrl: doc.contractFileUrl,
                  icon: Icons.description_outlined,
                  color: Colors.blue,
                ),
                _buildFileCard(
                  title: 'Buyruq',
                  filePath: doc.orderFile,
                  fileUrl: doc.orderFileUrl,
                  icon: Icons.article_outlined,
                  color: Colors.orange,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBody(),
          if (isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.12),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isSubmitting ? null : showAddDocumentDialog,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class StudentDocumentModel {
  final int id;
  final int studentId;
  final String contractFile;
  final String contractFileUrl;
  final String orderFile;
  final String orderFileUrl;
  final String documentDate;
  final String createdAt;
  final String updatedAt;

  StudentDocumentModel({
    required this.id,
    required this.studentId,
    required this.contractFile,
    required this.contractFileUrl,
    required this.orderFile,
    required this.orderFileUrl,
    required this.documentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentDocumentModel.fromJson(Map<String, dynamic> json) {
    return StudentDocumentModel(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      contractFile: json['contract_file'] ?? '',
      contractFileUrl: json['contract_file_url'] ?? '',
      orderFile: json['order_file'] ?? '',
      orderFileUrl: json['order_file_url'] ?? '',
      documentDate: json['document_date'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class _FilePickBox extends StatelessWidget {
  final String title;
  final String? filePath;
  final String? currentFileName;
  final VoidCallback onPick;

  const _FilePickBox({
    required this.title,
    required this.filePath,
    required this.onPick,
    this.currentFileName,
  });

  String _name(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  @override
  Widget build(BuildContext context) {
    final selectedName =
    filePath != null && filePath!.trim().isNotEmpty ? _name(filePath!) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (currentFileName != null && currentFileName!.trim().isNotEmpty)
            Text(
              'Joriy: $currentFileName',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          if (selectedName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Tanlandi: $selectedName',
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.attach_file_rounded),
            label: const Text('Fayl tanlash'),
          ),
        ],
      ),
    );
  }
}