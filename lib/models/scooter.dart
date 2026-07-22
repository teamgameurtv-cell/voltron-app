class OwnedScooter {
  final String id;
  final String ownerId;
  final String brand;
  final String model;
  final String serialNumber;
  final DateTime purchaseDate;
  final String? imageUrl;
  final int mileageKm;
  final String batterySpec;
  final String color;

  const OwnedScooter({
    required this.id,
    this.ownerId = '',
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.purchaseDate,
    this.imageUrl,
    this.mileageKm = 0,
    this.batterySpec = '',
    this.color = '',
  });

  String get formattedPurchaseDate =>
      '${purchaseDate.day.toString().padLeft(2, '0')}/${purchaseDate.month.toString().padLeft(2, '0')}/${purchaseDate.year}';

  /// Révision conseillée tous les 6 mois à partir de l'achat.
  DateTime get nextRevisionDate {
    var next = DateTime(
      purchaseDate.year,
      purchaseDate.month + 6,
      purchaseDate.day,
    );
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
      ownerId: map['owner_id'] as String? ?? '',
      brand: map['brand'] as String,
      model: map['model'] as String,
      serialNumber: map['serial_number'] as String? ?? '',
      purchaseDate: DateTime.parse(map['purchase_date'] as String),
      imageUrl: map['image_url'] as String?,
      mileageKm: map['mileage_km'] as int? ?? 0,
      batterySpec: map['battery_spec'] as String? ?? '',
      color: map['color'] as String? ?? '',
    );
  }
}
