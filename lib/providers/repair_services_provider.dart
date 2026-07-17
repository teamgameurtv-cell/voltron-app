import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repair.dart';
import 'auth_provider.dart';

class RepairServicesNotifier extends StateNotifier<List<RepairService>> {
  final SupabaseClient _client;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  RepairServicesNotifier(this._client) : super([]) {
    _sub = _client.from('repair_services').stream(primaryKey: ['id']).listen((rows) {
      final services = rows.map(RepairService.fromMap).toList()..sort((a, b) => a.name.compareTo(b.name));
      state = services;
    });
  }

  Future<void> add({
    required String name,
    required String duration,
    required String priceLabel,
    String? description,
    String? imageUrl,
  }) async {
    await _client.from('repair_services').insert({
      'name': name,
      'duration': duration,
      'price_label': priceLabel,
      'description': description,
      'image_url': imageUrl,
    });
  }

  Future<void> update(RepairService service) async {
    await _client.from('repair_services').update({
      'name': service.name,
      'duration': service.duration,
      'price_label': service.priceLabel,
      'description': service.description,
      'image_url': service.imageUrl,
    }).eq('id', service.id);
  }

  Future<void> remove(String id) async {
    await _client.from('repair_services').delete().eq('id', id);
  }

  /// Envoie la photo choisie dans le stockage Supabase et retourne son URL publique.
  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('service-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('service-images').getPublicUrl(path);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final repairServicesProvider = StateNotifierProvider<RepairServicesNotifier, List<RepairService>>(
  (ref) => RepairServicesNotifier(ref.watch(supabaseProvider)),
);
