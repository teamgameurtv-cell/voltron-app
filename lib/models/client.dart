class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int loyaltyPoints;

  const Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.loyaltyPoints,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: (map['name'] as String?)?.isNotEmpty == true ? map['name'] as String : 'Sans nom',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      loyaltyPoints: map['loyalty_points'] as int? ?? 0,
    );
  }
}
