class RepairOrderEvent {
  final String id;
  final String orderId;
  final String actorRole;
  final String eventType;
  final String description;
  final DateTime createdAt;

  const RepairOrderEvent({
    required this.id,
    required this.orderId,
    required this.actorRole,
    required this.eventType,
    required this.description,
    required this.createdAt,
  });

  factory RepairOrderEvent.fromMap(Map<String, dynamic> map) {
    return RepairOrderEvent(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      actorRole: map['actor_role'] as String,
      eventType: map['event_type'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
