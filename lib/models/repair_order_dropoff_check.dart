/// Point de vérification rapide à la prise en charge du véhicule (freins,
/// accélération...) — contrairement à [RepairStepTask], rattaché au dossier
/// entier (pas à une étape précise) et reste visible du client une fois coché.
class RepairOrderDropoffCheck {
  final String id;
  final String orderId;
  final String key;
  final String label;
  final int position;
  final bool done;
  final DateTime updatedAt;

  const RepairOrderDropoffCheck({
    required this.id,
    required this.orderId,
    required this.key,
    required this.label,
    this.position = 0,
    this.done = false,
    required this.updatedAt,
  });

  factory RepairOrderDropoffCheck.fromMap(Map<String, dynamic> map) {
    return RepairOrderDropoffCheck(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      key: map['key'] as String,
      label: map['label'] as String,
      position: map['position'] as int? ?? 0,
      done: map['done'] as bool? ?? false,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
