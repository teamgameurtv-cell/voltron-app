enum TicketStatus { open, answered, closed }

class SupportTicket {
  final String id;
  final String clientId;
  final String subject;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.clientId,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      subject: map['subject'] as String,
      status: TicketStatus.values.byName(map['status'] as String? ?? 'open'),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

enum SenderRole { client, admin }

class SupportMessage {
  final String id;
  final String ticketId;
  final SenderRole senderRole;
  final String body;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderRole,
    required this.body,
    this.attachmentUrl,
    this.attachmentType,
    required this.createdAt,
  });

  bool get isImage => attachmentType == 'image';
  bool get isVideo => attachmentType == 'video';

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      senderRole: SenderRole.values.byName(map['sender_role'] as String),
      body: map['body'] as String? ?? '',
      attachmentUrl: map['attachment_url'] as String?,
      attachmentType: map['attachment_type'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
