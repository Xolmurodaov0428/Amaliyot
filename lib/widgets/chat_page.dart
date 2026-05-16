import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_config.dart';
import '../constants/app_colors.dart';
import '../models/chat_models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final http.Client _httpClient = http.Client();
  Timer? _pollTimer;

  bool _isLoading = true;
  bool _isSendingMessage = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  PlatformFile? _selectedAttachment;

  ChatConversationModel? _conversation;
  ChatSupervisorModel? _supervisor;
  List<ChatMessageModel> _messages = [];
  final Set<int> _deletingMessageIds = <int>{};

  int _currentPage = 1;
  int _totalPages = 1;
  static const int _perPage = 30;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadChat();
    _markMessageNotificationsRead();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadChat(showLoader: false),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _httpClient.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 0 &&
        _currentPage < _totalPages &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMoreMessages();
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _markMessageNotificationsRead() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;
      await _httpClient.post(
        ApiConfig.uri('notifications/read-all', {'type': 'message'}),
        headers: _authHeaders(token),
      );
    } catch (_) {}
  }

  Uri _buildUri(String path) => ApiConfig.uri(path);

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

  String _extractApiMessage(Map<String, dynamic> body,
      {String fallback = 'Xatolik yuz berdi.'}) {
    final message = body['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    final errors = body['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first.toString().trim();
          if (first.isNotEmpty) return first;
        }
      }
    }
    return fallback;
  }

  Future<void> _loadChat({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _totalPages = 1;
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

      final response = await _httpClient.get(
        ApiConfig.uri('messages', {'page': '1', 'per_page': '$_perPage'}),
        headers: _authHeaders(token),
      );
      final body = _safeJsonMap(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(body['data'])
            : <String, dynamic>{};

        final conversationRaw = data['conversation'];
        final supervisorRaw = data['supervisor'];
        final messagesRaw = data['messages'];
        final meta = data['meta'] is Map<String, dynamic>
            ? data['meta'] as Map<String, dynamic>
            : data['pagination'] is Map<String, dynamic>
                ? data['pagination'] as Map<String, dynamic>
                : <String, dynamic>{};

        setState(() {
          _conversation = conversationRaw is Map<String, dynamic>
              ? ChatConversationModel.fromJson(conversationRaw)
              : null;
          _supervisor = supervisorRaw is Map<String, dynamic>
              ? ChatSupervisorModel.fromJson(supervisorRaw)
              : null;
          _messages = messagesRaw is List
              ? messagesRaw
                  .whereType<Map>()
                  .map((e) =>
                      ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
                  .toList()
              : [];
          _currentPage = 1;
          _totalPages = int.tryParse(
                  (meta['last_page'] ?? meta['total_pages'] ?? 1).toString()) ??
              1;
          _isLoading = false;
          _errorMessage = null;
        });

        _scrollToBottom();
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Sessiya tugagan. Qayta login qiling.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = _extractApiMessage(body,
              fallback: 'Chatni yuklashda xato: ${response.statusCode}');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Chatni yuklashda xato: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() => _isLoadingMore = true);

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty || !mounted) return;

      final nextPage = _currentPage + 1;
      final response = await _httpClient.get(
        ApiConfig.uri('messages',
            {'page': '$nextPage', 'per_page': '$_perPage'}),
        headers: _authHeaders(token),
      );
      final body = _safeJsonMap(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(body['data'])
            : <String, dynamic>{};

        final messagesRaw = data['messages'];
        final older = messagesRaw is List
            ? messagesRaw
                .whereType<Map>()
                .map((e) =>
                    ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : <ChatMessageModel>[];

        final prevOffset = _scrollController.hasClients
            ? _scrollController.position.maxScrollExtent
            : 0.0;

        setState(() {
          _messages = [...older, ..._messages];
          _currentPage = nextPage;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final newMax = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(newMax - prevOffset);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      setState(() => _selectedAttachment = result.files.first);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fayl tanlashda xato: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Xabar matni majburiy.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_isSendingMessage) return;
    setState(() => _isSendingMessage = true);

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Token topilmadi. Qayta login qiling.'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      final request = http.MultipartRequest('POST', _buildUri('messages'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['message'] = text;

      final attachment = _selectedAttachment;
      if (attachment != null) {
        if (attachment.path != null && attachment.path!.trim().isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath(
            'attachment',
            attachment.path!,
            filename: attachment.name,
          ));
        } else if (attachment.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'attachment',
            attachment.bytes!,
            filename: attachment.name,
          ));
        }
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = _safeJsonMap(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _messageController.clear();
        setState(() => _selectedAttachment = null);
        await _loadChat(showLoader: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_extractApiMessage(body,
              fallback: 'Xabar yuborilmadi: ${response.statusCode}')),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Xabar yuborishda xato: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  Future<void> _confirmDeleteMessage(ChatMessageModel message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xabarni o'chirish"),
        content: const Text("O'zingiz yuborgan xabarni o'chirmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteMessage(message.id);
  }

  Future<void> _deleteMessage(int messageId) async {
    if (_deletingMessageIds.contains(messageId)) return;
    setState(() => _deletingMessageIds.add(messageId));

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Token topilmadi. Qayta login qiling.'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      final response = await _httpClient.delete(
        _buildUri('messages/$messageId'),
        headers: _authHeaders(token),
      );
      final body = _safeJsonMap(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        setState(() => _messages.removeWhere((m) => m.id == messageId));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_extractApiMessage(body,
              fallback: "Xabar o'chirilmadi: ${response.statusCode}")),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Xabar o'chirishda xato: $e"),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _deletingMessageIds.remove(messageId));
    }
  }

  Future<void> _openAttachment(ChatMessageModel message) async {
    final url = message.attachmentUrl;
    if (url == null || url.trim().isEmpty) return;

    final opened =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Biriktirma ochilmadi.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final supervisorName =
        _supervisor != null && _supervisor!.name.isNotEmpty
            ? _supervisor!.name
            : 'Rahbar';
    final supervisorSubtitle = _supervisor?.email ??
        _supervisor?.username ??
        'Supervisor bilan yozishma';
    final supervisorInitial =
        supervisorName.isNotEmpty ? supervisorName[0].toUpperCase() : 'R';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(
                supervisorInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supervisorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    supervisorSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _loadChat(showLoader: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yangilash',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_conversation?.lastMessageAt != null)
            // Container(
            //   width: double.infinity,
            //   padding:
            //       const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            //   color: AppColors.lightBlue,
            //   // child: Text(
            //   //   'Oxirgi xabar: ${_conversation!.lastMessageAt}',
            //   //   style: const TextStyle(
            //   //     fontSize: 12,
            //   //     color: AppColors.textSecondary,
            //   //   ),
            //   //   textAlign: TextAlign.center,
            //   // ),
            // ),
          Expanded(child: _buildBody()),
          _buildInputBar(),
        ],
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
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.dangerRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _loadChat(showLoader: true),
                child: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Hozircha xabarlar yo'q.\nBirinchi bo'lib yozishingiz mumkin.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (_isLoadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final msgIndex = _isLoadingMore ? index - 1 : index;
        return _buildMessage(_messages[msgIndex]);
      },
    );
  }

  Widget _buildMessage(ChatMessageModel message) {
    final isMine = message.isFromStudent;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: _deletingMessageIds.contains(message.id)
                      ? null
                      : () => _confirmDeleteMessage(message),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_deletingMessageIds.contains(message.id))
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.dangerRed,
                            ),
                          )
                        else
                          const Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppColors.dangerRed),
                        const SizedBox(width: 4),
                        const Text(
                          "O'chirish",
                          style: TextStyle(
                            color: AppColors.dangerRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMine
                    ? AppColors.primaryBlue
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: isMine
                    ? null
                    : Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.message.trim().isNotEmpty)
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isMine
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  if (message.hasAttachment)
                    Padding(
                      padding: EdgeInsets.only(
                          top: message.message.trim().isNotEmpty ? 10 : 0),
                      child: GestureDetector(
                        onTap: () => _openAttachment(message),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Colors.white.withValues(alpha: 0.14)
                                : AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_file_rounded,
                                size: 16,
                                color: isMine
                                    ? Colors.white
                                    : AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  message.attachmentName ?? 'Biriktirma',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isMine
                                        ? Colors.white
                                        : AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '${message.formattedDate}  ${message.formattedTime}',
                    style: TextStyle(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.75)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedAttachment != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded,
                      size: 18, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAttachment!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _selectedAttachment = null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Olib tashlash',
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Rahbarga xabar yozing...',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: _isSendingMessage ? null : _pickAttachment,
                  icon: const Icon(Icons.attach_file_rounded,
                      color: AppColors.primaryBlue),
                  tooltip: 'Fayl biriktirish',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSendingMessage ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _isSendingMessage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
