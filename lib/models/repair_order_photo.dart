class RepairOrderPhoto {
  final String id;
  final String orderId;
  final String? stepTaskId;
  final String url;
  final DateTime createdAt;

  const RepairOrderPhoto({
    required this.id,
    required this.orderId,
    this.stepTaskId,
    required this.url,
    required this.createdAt,
  });

  factory RepairOrderPhoto.fromMap(Map<String, dynamic> map) {
    return RepairOrderPhoto(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      stepTaskId: map['step_task_id'] as String?,
      url: map['url'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
