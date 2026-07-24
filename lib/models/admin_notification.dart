class AdminNotification {
  final String id;
  final String title;
  final String body;
  final String? orderId;
  final bool read;
  final DateTime createdAt;

  const AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    this.orderId,
    this.read = false,
    required this.createdAt,
  });

  factory AdminNotification.fromMap(Map<String, dynamic> map) {
    return AdminNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      orderId: map['order_id'] as String?,
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
