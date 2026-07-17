enum BookingStatus { confirmed, pending, cancelled }

class Booking {
  final String id;
  final String serviceName;
  final String clientName;
  final String day;
  final String time;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.serviceName,
    required this.clientName,
    required this.day,
    required this.time,
    this.status = BookingStatus.pending,
  });

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      serviceName: serviceName,
      clientName: clientName,
      day: day,
      time: time,
      status: status ?? this.status,
    );
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      serviceName: map['service_name'] as String,
      clientName: map['client_name'] as String,
      day: map['day'] as String,
      time: map['time'] as String,
      status: BookingStatus.values.byName(map['status'] as String),
    );
  }
}
