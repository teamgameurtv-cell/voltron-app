import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';
import '../models/booking.dart';
import 'auth_provider.dart';
import 'notifications_provider.dart';

class BookingsNotifier extends StateNotifier<List<Booking>> {
  final Ref ref;
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  BookingsNotifier(this.ref, this._client) : super([]) {
    _sub = _client.from('bookings').stream(primaryKey: ['id']).listen((rows) {
      state = rows.map(Booking.fromMap).toList();
    });
  }

  Future<void> add({
    required String serviceName,
    required String clientName,
    required String day,
    required String time,
    String problemDescription = '',
    String scooterName = '',
    String clientPhone = '',
  }) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('bookings').insert({
      'client_id': userId,
      'service_name': serviceName,
      'client_name': clientName,
      'day': day,
      'time': time,
      'status': 'pending',
      'problem_description': problemDescription,
      'scooter_name': scooterName,
      'client_phone': clientPhone,
    });
  }

  /// Horaires déjà réservés (hors annulées) pour un jour donné, tous clients
  /// confondus — pour empêcher un client de réserver un créneau déjà pris,
  /// sans exposer les réservations des autres (contourné via une fonction
  /// security definer, la RLS limitant chacun à ses propres réservations).
  Future<List<String>> bookedTimesForDay(String day) async {
    final result = await _client.rpc(
      'get_booked_times',
      params: {'p_day': day},
    );
    return (result as List).map((e) => e as String).toList();
  }

  Future<void> updateStatus(String id, BookingStatus status) async {
    await _client.from('bookings').update({'status': status.name}).eq('id', id);
  }

  Future<void> setArchived(String id, bool archived) async {
    await _client.from('bookings').update({'archived': archived}).eq('id', id);
  }

  /// Confirme le rendez-vous et prévient le client — utilisé côté admin.
  Future<void> confirmBooking(String id) async {
    final booking = state.firstWhere((b) => b.id == id);
    await _client.from('bookings').update({'status': 'confirmed'}).eq('id', id);
    if (booking.clientId == null) return;
    await ref
        .read(notificationsProvider.notifier)
        .notifyClient(
          booking.clientId!,
          type: NotificationType.order,
          title: 'Rendez-vous confirmé',
          body:
              'Ton rendez-vous du ${booking.day} à ${booking.time} (${booking.serviceName}) est confirmé.',
        );
  }

  /// Annule le rendez-vous et prévient le client — utilisé côté admin.
  Future<void> cancelBooking(String id) async {
    final booking = state.firstWhere((b) => b.id == id);
    await _client.from('bookings').update({'status': 'cancelled'}).eq('id', id);
    if (booking.clientId == null) return;
    await ref
        .read(notificationsProvider.notifier)
        .notifyClient(
          booking.clientId!,
          type: NotificationType.order,
          title: 'Rendez-vous annulé',
          body:
              'Ton rendez-vous du ${booking.day} à ${booking.time} (${booking.serviceName}) a été annulé.',
        );
  }

  /// Propose un nouveau créneau au client (repasse en attente le temps que ce
  /// soit validé) et le prévient, avec la raison si elle est renseignée.
  Future<void> rescheduleBooking(
    String id, {
    required String day,
    required String time,
    String? reason,
  }) async {
    final booking = state.firstWhere((b) => b.id == id);
    await _client
        .from('bookings')
        .update({'day': day, 'time': time, 'status': 'pending'})
        .eq('id', id);
    if (booking.clientId == null) return;
    final reasonText = (reason != null && reason.trim().isNotEmpty)
        ? ' Raison : ${reason.trim()}.'
        : '';
    await ref
        .read(notificationsProvider.notifier)
        .notifyClient(
          booking.clientId!,
          type: NotificationType.order,
          title: 'Nouveau créneau proposé',
          body:
              'Ton rendez-vous (${booking.serviceName}) est proposé pour le $day à $time.$reasonText',
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final bookingsProvider = StateNotifierProvider<BookingsNotifier, List<Booking>>(
  (ref) => BookingsNotifier(ref, ref.watch(supabaseProvider)),
);
