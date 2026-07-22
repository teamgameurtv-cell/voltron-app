import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_models.dart';
import 'auth_provider.dart';

class ProfileNotifier extends StateNotifier<UserProfile> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  ProfileNotifier(this._client)
    : super(const UserProfile(name: '', email: '', phone: '')) {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      _sub = _client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', userId)
          .listen((rows) {
            if (rows.isNotEmpty) state = UserProfile.fromMap(rows.first);
          });
    }
  }

  Future<void> update({
    String? name,
    String? firstName,
    String? email,
    String? phone,
    String? address,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('profiles')
        .update({
          if (name != null) 'name': name,
          if (firstName != null) 'first_name': firstName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        })
        .eq('id', userId);
  }

  Future<void> updateShortcuts(List<String> shortcutIds) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('profiles')
        .update({'quick_shortcuts': shortcutIds})
        .eq('id', userId);
  }

  Future<void> updateNotificationPrefs({
    bool? repairs,
    bool? promos,
    bool? loyalty,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('profiles')
        .update({
          if (repairs != null) 'notif_repairs': repairs,
          if (promos != null) 'notif_promos': promos,
          if (loyalty != null) 'notif_loyalty': loyalty,
        })
        .eq('id', userId);
  }

  /// Envoie la photo de profil choisie dans le stockage Supabase et l'associe au compte.
  Future<void> updateAvatar(Uint8List bytes, String fileExtension) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final path = '$userId/avatar.$fileExtension';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('avatars').getPublicUrl(path);
    await _client
        .from('profiles')
        .update({
          'avatar_url': '$url?t=${DateTime.now().millisecondsSinceEpoch}',
        })
        .eq('id', userId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>((
  ref,
) {
  ref.watch(currentUserProvider);
  return ProfileNotifier(ref.watch(supabaseProvider));
});

class PaymentMethodsNotifier extends StateNotifier<List<PaymentMethod>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  PaymentMethodsNotifier(this._client) : super([]) {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      _sub = _client
          .from('payment_methods')
          .stream(primaryKey: ['id'])
          .eq('client_id', userId)
          .listen((rows) {
            state = rows.map(PaymentMethod.fromMap).toList();
          });
    }
  }

  Future<void> add({
    required String brand,
    required String last4,
    required String expiry,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('payment_methods').insert({
      'client_id': userId,
      'brand': brand,
      'last4': last4,
      'expiry': expiry,
    });
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

final paymentMethodsProvider =
    StateNotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>((ref) {
      ref.watch(currentUserProvider);
      return PaymentMethodsNotifier(ref.watch(supabaseProvider));
    });

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
