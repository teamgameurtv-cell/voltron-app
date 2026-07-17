import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import 'auth_provider.dart';

class BookingsNotifier extends StateNotifier<List<Booking>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  BookingsNotifier(this._client) : super([]) {
    _sub = _client.from('bookings').stream(primaryKey: ['id']).listen((rows) {
      state = rows.map(Booking.fromMap).toList();
    });
  }

  Future<void> add({
    required String serviceName,
    required String clientName,
    required String day,
    required String time,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('bookings').insert({
      'client_id': userId,
      'service_name': serviceName,
      'client_name': clientName,
      'day': day,
      'time': time,
      'status': 'pending',
    });
  }

  Future<void> updateStatus(String id, BookingStatus status) async {
    await _client.from('bookings').update({'status': status.name}).eq('id', id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final bookingsProvider = StateNotifierProvider<BookingsNotifier, List<Booking>>(
  (ref) => BookingsNotifier(ref.watch(supabaseProvider)),
);
