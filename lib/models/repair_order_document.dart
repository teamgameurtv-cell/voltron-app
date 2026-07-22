class RepairOrderDocument {
  final String id;
  final String orderId;
  final String label;
  final String url;
  final DateTime createdAt;

  const RepairOrderDocument({
    required this.id,
    required this.orderId,
    required this.label,
    required this.url,
    required this.createdAt,
  });

  factory RepairOrderDocument.fromMap(Map<String, dynamic> map) {
    return RepairOrderDocument(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      label: map['label'] as String,
      url: map['url'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
