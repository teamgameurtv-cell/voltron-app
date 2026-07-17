import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_models.dart';
import 'auth_provider.dart';

class ProfileNotifier extends StateNotifier<UserProfile> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  ProfileNotifier(this._client) : super(const UserProfile(name: '', email: '', phone: '')) {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      _sub = _client.from('profiles').stream(primaryKey: ['id']).eq('id', userId).listen((rows) {
        if (rows.isNotEmpty) state = UserProfile.fromMap(rows.first);
      });
    }
  }

  Future<void> update({String? name, String? email, String? phone}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update({
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    }).eq('id', userId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) {
    ref.watch(currentUserProvider);
    return ProfileNotifier(ref.watch(supabaseProvider));
  },
);

class AddressesNotifier extends StateNotifier<List<Address>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  AddressesNotifier(this._client) : super([]) {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      _sub = _client.from('addresses').stream(primaryKey: ['id']).eq('client_id', userId).listen((rows) {
        state = rows.map(Address.fromMap).toList();
      });
    }
  }

  Future<void> add(String label, String details) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('addresses').insert({'client_id': userId, 'label': label, 'details': details});
  }

  Future<void> remove(String id) async {
    await _client.from('addresses').delete().eq('id', id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final addressesProvider = StateNotifierProvider<AddressesNotifier, List<Address>>(
  (ref) {
    ref.watch(currentUserProvider);
    return AddressesNotifier(ref.watch(supabaseProvider));
  },
);

class PaymentMethodsNotifier extends StateNotifier<List<PaymentMethod>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  PaymentMethodsNotifier(this._client) : super([]) {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      _sub = _client.from('payment_methods').stream(primaryKey: ['id']).eq('client_id', userId).listen((rows) {
        state = rows.map(PaymentMethod.fromMap).toList();
      });
    }
  }

  Future<void> add({required String brand, required String last4, required String expiry}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('payment_methods')
        .insert({'client_id': userId, 'brand': brand, 'last4': last4, 'expiry': expiry});
  }

  Future<void> remove(String id) async {
    await _client.from('payment_methods').delete().eq('id', id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final paymentMethodsProvider = StateNotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>(
  (ref) {
    ref.watch(currentUserProvider);
    return PaymentMethodsNotifier(ref.watch(supabaseProvider));
  },
);

/// Préférences de notifications : locales pour l'instant (pas encore de table dédiée).
class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier() : super(const NotificationPrefs());

  void update({bool? repairs, bool? promos, bool? loyalty}) {
    state = state.copyWith(repairs: repairs, promos: promos, loyalty: loyalty);
  }
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>((ref) => NotificationPrefsNotifier());

final invoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return const Stream.empty();
  return ref
      .watch(supabaseProvider)
      .from('invoices')
      .stream(primaryKey: ['id'])
      .eq('client_id', userId)
      .map((rows) => rows.map(Invoice.fromMap).toList());
});
