class ChatConversationModel {
  final int id;
  final String? lastMessageAt;

  const ChatConversationModel({
    required this.id,
    this.lastMessageAt,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      lastMessageAt: json['last_message_at']?.toString(),
    );
  }
}

class ChatSupervisorModel {
  final int id;
  final String name;
  final String? username;
  final String? phone;
  final String? email;

  const ChatSupervisorModel({
    required this.id,
    required this.name,
    this.username,
    this.phone,
    this.email,
  });

  factory ChatSupervisorModel.fromJson(Map<String, dynamic> json) {
    return ChatSupervisorModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? 'Rahbar').toString(),
      username: json['username']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class ChatMessageModel {
  final int id;
  final int conversationId;
  final String message;
  final int senderId;
  final String senderType;
  final bool isFromStudent;
  final bool isFromSupervisor;
  final bool isRead;
  final String createdAt;
  final DateTime _sentAt;
  final bool hasAttachment;
  final String? attachmentName;
  final String? attachmentUrl;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.message,
    required this.senderId,
    required this.senderType,
    required this.isFromStudent,
    required this.isFromSupervisor,
    required this.isRead,
    required this.createdAt,
    required DateTime sentAt,
    required this.hasAttachment,
    this.attachmentName,
    this.attachmentUrl,
  }) : _sentAt = sentAt;

  String get formattedTime {
    final h = _sentAt.hour.toString().padLeft(2, '0');
    final m = _sentAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDate {
    final now = DateTime.now();
    if (_sentAt.year == now.year &&
        _sentAt.month == now.month &&
        _sentAt.day == now.day) {
      return 'Bugun';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (_sentAt.year == yesterday.year &&
        _sentAt.month == yesterday.month &&
        _sentAt.day == yesterday.day) {
      return 'Kecha';
    }
    final d = _sentAt.day.toString().padLeft(2, '0');
    final mo = _sentAt.month.toString().padLeft(2, '0');
    return '$d.$mo.${_sentAt.year}';
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['created_at'] ?? '').toString();
    DateTime sentAt;
    try {
      sentAt = DateTime.parse(raw.replaceFirst(' ', 'T')).toLocal();
    } catch (_) {
      sentAt = DateTime.now();
    }
    return ChatMessageModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      conversationId:
          int.tryParse(json['conversation_id']?.toString() ?? '') ?? 0,
      message: (json['message'] ?? '').toString(),
      senderId: int.tryParse(json['sender_id']?.toString() ?? '') ?? 0,
      senderType: (json['sender_type'] ?? '').toString(),
      isFromStudent: json['is_from_student'] == true,
      isFromSupervisor: json['is_from_supervisor'] == true,
      isRead: json['is_read'] == true,
      createdAt: raw,
      sentAt: sentAt,
      hasAttachment: json['has_attachment'] == true,
      attachmentName: json['attachment_name']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
    );
  }
}
