class Client {
  final String id;
  final String name;
  final String firstName;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final int loyaltyPoints;
  final String? avatarUrl;

  const Client({
    required this.id,
    required this.name,
    this.firstName = '',
    required this.email,
    required this.phone,
    this.dateOfBirth,
    required this.loyaltyPoints,
    this.avatarUrl,
  });

  String get fullName => [firstName, name].where((s) => s.isNotEmpty).join(' ');

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: (map['name'] as String?)?.isNotEmpty == true
          ? map['name'] as String
          : 'Sans nom',
      firstName: map['first_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'] as String)
          : null,
      loyaltyPoints: map['loyalty_points'] as int? ?? 0,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
