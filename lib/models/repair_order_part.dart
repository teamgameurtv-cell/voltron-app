enum PartStatus { pending, ordered, received, installed }

class RepairOrderPart {
  final String id;
  final String orderId;
  final String label;
  final String? reference;
  final int quantity;
  final double price;
  final PartStatus status;
  final DateTime createdAt;

  const RepairOrderPart({
    required this.id,
    required this.orderId,
    required this.label,
    this.reference,
    this.quantity = 1,
    this.price = 0,
    this.status = PartStatus.pending,
    required this.createdAt,
  });

  String get statusLabel => switch (status) {
    PartStatus.pending => 'À commander',
    PartStatus.ordered => 'Commandée',
    PartStatus.received => 'Reçue',
    PartStatus.installed => 'Installée',
  };

  factory RepairOrderPart.fromMap(Map<String, dynamic> map) {
    return RepairOrderPart(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      label: map['label'] as String,
      reference: map['reference'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      status: PartStatus.values.byName(map['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
