class OwnedScooter {
  final String id;
  final String brand;
  final String model;
  final String serialNumber;
  final DateTime purchaseDate;

  const OwnedScooter({
    required this.id,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.purchaseDate,
  });

  String get formattedPurchaseDate =>
      '${purchaseDate.day.toString().padLeft(2, '0')}/${purchaseDate.month.toString().padLeft(2, '0')}/${purchaseDate.year}';

  /// Révision conseillée tous les 6 mois à partir de l'achat.
  DateTime get nextRevisionDate {
    var next = DateTime(purchaseDate.year, purchaseDate.month + 6, purchaseDate.day);
    final now = DateTime.now();
    while (next.isBefore(now)) {
      next = DateTime(next.year, next.month + 6, next.day);
    }
    return next;
  }

  String get formattedNextRevisionDate =>
      '${nextRevisionDate.day.toString().padLeft(2, '0')}/${nextRevisionDate.month.toString().padLeft(2, '0')}/${nextRevisionDate.year}';

  factory OwnedScooter.fromMap(Map<String, dynamic> map) {
    return OwnedScooter(
      id: map['id'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      serialNumber: map['serial_number'] as String? ?? '',
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
    );
  }
}
