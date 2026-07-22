enum BookingStatus { confirmed, pending, cancelled }

const List<String> bookingMonthNames = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

bool isSameBookingDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Reconstruit la date d'une réservation à partir de son affichage ("22 Juillet
/// 2026"), pour pouvoir la placer sur le calendrier admin. Renvoie null si le
/// format est inattendu plutôt que de planter l'écran.
DateTime? parseBookingDay(String day) {
  final parts = day.trim().split(' ');
  if (parts.length != 3) return null;
  final dayNumber = int.tryParse(parts[0]);
  final monthIndex = bookingMonthNames.indexWhere(
    (m) => m.toLowerCase() == parts[1].toLowerCase(),
  );
  final year = int.tryParse(parts[2]);
  if (dayNumber == null || monthIndex == -1 || year == null) return null;
  return DateTime(year, monthIndex + 1, dayNumber);
}

class Booking {
  final String id;
  final String? clientId;
  final String serviceName;
  final String clientName;
  final String day;
  final String time;
  final BookingStatus status;
  final bool archived;
  final String problemDescription;
  final String scooterName;
  final String clientPhone;

  const Booking({
    required this.id,
    this.clientId,
    required this.serviceName,
    required this.clientName,
    required this.day,
    required this.time,
    this.status = BookingStatus.pending,
    this.archived = false,
    this.problemDescription = '',
    this.scooterName = '',
    this.clientPhone = '',
  });

  Booking copyWith({BookingStatus? status, bool? archived}) {
    return Booking(
      id: id,
      clientId: clientId,
      serviceName: serviceName,
      clientName: clientName,
      day: day,
      time: time,
      status: status ?? this.status,
      archived: archived ?? this.archived,
      problemDescription: problemDescription,
      scooterName: scooterName,
      clientPhone: clientPhone,
    );
  }

  DateTime? get parsedDay => parseBookingDay(day);

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      clientId: map['client_id'] as String?,
      serviceName: map['service_name'] as String,
      clientName: map['client_name'] as String,
      day: map['day'] as String,
      time: map['time'] as String,
      status: BookingStatus.values.byName(map['status'] as String),
      archived: map['archived'] as bool? ?? false,
      problemDescription: map['problem_description'] as String? ?? '',
      scooterName: map['scooter_name'] as String? ?? '',
      clientPhone: map['client_phone'] as String? ?? '',
    );
  }
}
