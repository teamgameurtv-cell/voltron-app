enum TechnicianStatus { enLigne, horsLigne, absent }

class Technician {
  final String id;
  final String name;
  final String? avatarUrl;
  final TechnicianStatus status;
  final DateTime createdAt;

  const Technician({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.status = TechnicianStatus.horsLigne,
    required this.createdAt,
  });

  String get statusLabel => switch (status) {
    TechnicianStatus.enLigne => 'En ligne',
    TechnicianStatus.horsLigne => 'Hors ligne',
    TechnicianStatus.absent => 'Absent',
  };

  factory Technician.fromMap(Map<String, dynamic> map) {
    return Technician(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      status: _statusFromDb(map['status'] as String? ?? 'hors_ligne'),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static TechnicianStatus _statusFromDb(String value) => switch (value) {
    'en_ligne' => TechnicianStatus.enLigne,
    'absent' => TechnicianStatus.absent,
    _ => TechnicianStatus.horsLigne,
  };

  static String statusToDb(TechnicianStatus status) => switch (status) {
    TechnicianStatus.enLigne => 'en_ligne',
    TechnicianStatus.horsLigne => 'hors_ligne',
    TechnicianStatus.absent => 'absent',
  };
}
