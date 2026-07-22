import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/technician.dart';
import 'auth_provider.dart';

/// Annuaire des techniciens — simple liste gérée par l'admin, sans compte de
/// connexion séparé (assignable depuis une liste déroulante sur un dossier).
final techniciansProvider = StreamProvider<List<Technician>>((ref) {
  return ref
      .watch(supabaseProvider)
      .from('technicians')
      .stream(primaryKey: ['id'])
      .map(
        (rows) =>
            rows.map(Technician.fromMap).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );
});

class TechnicianActions {
  final SupabaseClient _client;

  TechnicianActions(this._client);

  Future<String> addTechnician({
    required String name,
    TechnicianStatus status = TechnicianStatus.horsLigne,
  }) async {
    final row = await _client
        .from('technicians')
        .insert({'name': name, 'status': Technician.statusToDb(status)})
        .select()
        .single();
    return row['id'] as String;
  }

  Future<void> updateTechnician(
    String id, {
    String? name,
    TechnicianStatus? status,
  }) async {
    await _client
        .from('technicians')
        .update({
          if (name != null) 'name': name,
          if (status != null) 'status': Technician.statusToDb(status),
        })
        .eq('id', id);
  }

  Future<void> removeTechnician(String id) async {
    await _client.from('technicians').delete().eq('id', id);
  }

  Future<String> uploadAvatar(
    String technicianId,
    Uint8List bytes,
    String fileExtension,
  ) async {
    final path =
        '$technicianId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    await _client.storage
        .from('technician-avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('technician-avatars').getPublicUrl(path);
    await _client
        .from('technicians')
        .update({'avatar_url': url})
        .eq('id', technicianId);
    return url;
  }
}

final technicianActionsProvider = Provider<TechnicianActions>(
  (ref) => TechnicianActions(ref.watch(supabaseProvider)),
);
