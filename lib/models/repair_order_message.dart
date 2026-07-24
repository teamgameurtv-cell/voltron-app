/// Distinct de [SenderRole] (models/support_ticket.dart) : ce fil de messages
/// est propre à un dossier de réparation, indépendant du support client général.
enum RepairMessageSenderRole { client, admin }

class RepairOrderMessage {
  final String id;
  final String orderId;
  final RepairMessageSenderRole senderRole;
  final String body;
  final String? attachmentUrl;
  final String? attachmentType;
  final bool read;
  final DateTime createdAt;

  const RepairOrderMessage({
    required this.id,
    required this.orderId,
    required this.senderRole,
    required this.body,
    this.attachmentUrl,
    this.attachmentType,
    this.read = false,
    required this.createdAt,
  });

  bool get isImage => attachmentType == 'image';
  bool get isVideo => attachmentType == 'video';

  factory RepairOrderMessage.fromMap(Map<String, dynamic> map) {
    return RepairOrderMessage(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      senderRole: RepairMessageSenderRole.values.byName(
        map['sender_role'] as String,
      ),
      body: map['body'] as String? ?? '',
      attachmentUrl: map['attachment_url'] as String?,
      attachmentType: map['attachment_type'] as String?,
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
