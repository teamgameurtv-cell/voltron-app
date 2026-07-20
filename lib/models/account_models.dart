class UserProfile {
  final String name;
  final String firstName;
  final String email;
  final String phone;
  final int loyaltyPoints;
  final String? avatarUrl;
  final List<String> quickShortcuts;

  const UserProfile({
    required this.name,
    this.firstName = '',
    required this.email,
    required this.phone,
    this.loyaltyPoints = 0,
    this.avatarUrl,
    this.quickShortcuts = const ['book', 'shop', 'garage', 'care'],
  });

  UserProfile copyWith({
    String? name,
    String? firstName,
    String? email,
    String? phone,
    String? avatarUrl,
    List<String>? quickShortcuts,
  }) {
    return UserProfile(
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      loyaltyPoints: loyaltyPoints,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      quickShortcuts: quickShortcuts ?? this.quickShortcuts,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? '',
      firstName: map['first_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      loyaltyPoints: map['loyalty_points'] as int? ?? 0,
      avatarUrl: map['avatar_url'] as String?,
      quickShortcuts: (map['quick_shortcuts'] as List?)?.map((e) => e as String).toList() ??
          const ['book', 'shop', 'garage', 'care'],
    );
  }
}

class Address {
  final String id;
  final String label;
  final String details;

  const Address({required this.id, required this.label, required this.details});

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(id: map['id'] as String, label: map['label'] as String, details: map['details'] as String);
  }
}

class PaymentMethod {
  final String id;
  final String brand;
  final String last4;
  final String expiry;

  const PaymentMethod({required this.id, required this.brand, required this.last4, required this.expiry});

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as String,
      brand: map['brand'] as String,
      last4: map['last4'] as String,
      expiry: map['expiry'] as String,
    );
  }
}

class NotificationPrefs {
  final bool repairs;
  final bool promos;
  final bool loyalty;

  const NotificationPrefs({this.repairs = true, this.promos = true, this.loyalty = true});

  NotificationPrefs copyWith({bool? repairs, bool? promos, bool? loyalty}) {
    return NotificationPrefs(
      repairs: repairs ?? this.repairs,
      promos: promos ?? this.promos,
      loyalty: loyalty ?? this.loyalty,
    );
  }
}

class Invoice {
  final String id;
  final String date;
  final String label;
  final double amount;

  const Invoice({required this.id, required this.date, required this.label, required this.amount});

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      date: map['invoice_date'] as String,
      label: map['label'] as String,
      amount: (map['amount'] as num).toDouble(),
    );
  }
}
