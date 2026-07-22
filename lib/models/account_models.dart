class UserProfile {
  final String name;
  final String firstName;
  final String email;
  final String phone;
  final String address;
  final DateTime? dateOfBirth;
  final int loyaltyPoints;
  final String? avatarUrl;
  final List<String> quickShortcuts;
  final bool notifRepairs;
  final bool notifPromos;
  final bool notifLoyalty;

  const UserProfile({
    required this.name,
    this.firstName = '',
    required this.email,
    required this.phone,
    this.address = '',
    this.dateOfBirth,
    this.loyaltyPoints = 0,
    this.avatarUrl,
    this.quickShortcuts = const ['book', 'shop', 'garage', 'care'],
    this.notifRepairs = true,
    this.notifPromos = true,
    this.notifLoyalty = true,
  });

  UserProfile copyWith({
    String? name,
    String? firstName,
    String? email,
    String? phone,
    String? address,
    String? avatarUrl,
    List<String>? quickShortcuts,
    bool? notifRepairs,
    bool? notifPromos,
    bool? notifLoyalty,
  }) {
    return UserProfile(
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth,
      loyaltyPoints: loyaltyPoints,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      quickShortcuts: quickShortcuts ?? this.quickShortcuts,
      notifRepairs: notifRepairs ?? this.notifRepairs,
      notifPromos: notifPromos ?? this.notifPromos,
      notifLoyalty: notifLoyalty ?? this.notifLoyalty,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? '',
      firstName: map['first_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'] as String)
          : null,
      loyaltyPoints: map['loyalty_points'] as int? ?? 0,
      avatarUrl: map['avatar_url'] as String?,
      quickShortcuts:
          (map['quick_shortcuts'] as List?)?.map((e) => e as String).toList() ??
          const ['book', 'shop', 'garage', 'care'],
      notifRepairs: map['notif_repairs'] as bool? ?? true,
      notifPromos: map['notif_promos'] as bool? ?? true,
      notifLoyalty: map['notif_loyalty'] as bool? ?? true,
    );
  }
}

class PaymentMethod {
  final String id;
  final String brand;
  final String last4;
  final String expiry;

  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as String,
      brand: map['brand'] as String,
      last4: map['last4'] as String,
      expiry: map['expiry'] as String,
    );
  }
}

class Invoice {
  final String id;
  final String date;
  final String label;
  final double amount;
  final String? fileUrl;
  final int pointsCredited;

  const Invoice({
    required this.id,
    required this.date,
    required this.label,
    required this.amount,
    this.fileUrl,
    this.pointsCredited = 0,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      date: map['invoice_date'] as String,
      label: map['label'] as String,
      amount: (map['amount'] as num).toDouble(),
      fileUrl: map['file_url'] as String?,
      pointsCredited: map['points_credited'] as int? ?? 0,
    );
  }
}
