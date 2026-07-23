import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repair_step_task_templates.dart';
import '../models/repair_order_document.dart';
import '../models/repair_order_dropoff_check.dart';
import '../models/repair_order_event.dart';
import '../models/repair_order_message.dart';
import '../models/repair_order_part.dart';
import '../models/repair_order_photo.dart';
import '../models/repair_step_task.dart';
import 'auth_provider.dart';
import 'repair_order_events_log.dart';

final stepTasksProvider = StreamProvider.family<List<RepairStepTask>, String>((
  ref,
  orderId,
) {
  return ref
      .watch(supabaseProvider)
      .from('repair_order_step_tasks')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .map(
        (rows) =>
            rows.map(RepairStepTask.fromMap).toList()
              ..sort((a, b) => a.position.compareTo(b.position)),
      );
});

final repairOrderPhotosProvider =
    StreamProvider.family<List<RepairOrderPhoto>, String>((ref, orderId) {
      return ref
          .watch(supabaseProvider)
          .from('repair_order_photos')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .map((rows) => rows.map(RepairOrderPhoto.fromMap).toList());
    });

final repairOrderDocumentsProvider =
    StreamProvider.family<List<RepairOrderDocument>, String>((ref, orderId) {
      return ref
          .watch(supabaseProvider)
          .from('repair_order_documents')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .map(
            (rows) =>
                rows.map(RepairOrderDocument.fromMap).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          );
    });

final repairOrderPartsProvider =
    StreamProvider.family<List<RepairOrderPart>, String>((ref, orderId) {
      return ref
          .watch(supabaseProvider)
          .from('repair_order_parts')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .map(
            (rows) =>
                rows.map(RepairOrderPart.fromMap).toList()
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
          );
    });

final repairOrderMessagesProvider =
    StreamProvider.family<List<RepairOrderMessage>, String>((ref, orderId) {
      return ref
          .watch(supabaseProvider)
          .from('repair_order_messages')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .map(
            (rows) =>
                rows.map(RepairOrderMessage.fromMap).toList()
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
          );
    });

final dropoffChecksProvider =
    StreamProvider.family<List<RepairOrderDropoffCheck>, String>((
      ref,
      orderId,
    ) {
      return ref
          .watch(supabaseProvider)
          .from('repair_order_dropoff_checks')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .map(
            (rows) =>
                rows.map(RepairOrderDropoffCheck.fromMap).toList()
                  ..sort((a, b) => a.position.compareTo(b.position)),
          );
    });

final repairOrderEventsProvider =
    StreamProvider.family<List<RepairOrderEvent>, String>((ref, orderId) {
      return ref
          .watch(supabaseProvider)
          .from('repair_order_events')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .map(
            (rows) =>
                rows.map(RepairOrderEvent.fromMap).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          );
    });

class RepairOrderDetailActions {
  final SupabaseClient _client;

  RepairOrderDetailActions(this._client);

  Future<void> updateStepTaskCheck(String taskId, bool done) async {
    await _client
        .from('repair_order_step_tasks')
        .update({'done': done, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', taskId);
  }

  Future<void> updateStepTaskValue(String taskId, String valueText) async {
    await _client
        .from('repair_order_step_tasks')
        .update({
          'value_text': valueText,
          'done': valueText.trim().isNotEmpty,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', taskId);
  }

  Future<void> updateStepTaskSelectedOptions(
    String taskId,
    List<String> options,
  ) async {
    await _client
        .from('repair_order_step_tasks')
        .update({
          'selected_options': options,
          'done': options.isNotEmpty,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', taskId);
  }

  /// Ajoute une photo liée à une tâche de checklist (le compteur "0/4 photos"
  /// est dérivé du nombre de lignes ici, jamais stocké séparément).
  Future<void> uploadStepPhoto(
    String orderId,
    String taskId,
    Uint8List bytes,
    String fileName,
  ) async {
    final path = '$orderId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage
        .from('repair-order-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('repair-order-photos').getPublicUrl(path);
    await _client.from('repair_order_photos').insert({
      'order_id': orderId,
      'step_task_id': taskId,
      'url': url,
    });
  }

  Future<void> addDocument(
    String orderId,
    String label,
    Uint8List bytes,
    String fileName,
  ) async {
    final path = '$orderId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage
        .from('repair-order-documents')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage
        .from('repair-order-documents')
        .getPublicUrl(path);
    await _client.from('repair_order_documents').insert({
      'order_id': orderId,
      'label': label,
      'url': url,
    });
  }

  Future<void> removeDocument(String id) async {
    await _client.from('repair_order_documents').delete().eq('id', id);
  }

  Future<void> addPart(
    String orderId, {
    required String label,
    String? reference,
    int quantity = 1,
    double price = 0,
  }) async {
    await _client.from('repair_order_parts').insert({
      'order_id': orderId,
      'label': label,
      'reference': reference,
      'quantity': quantity,
      'price': price,
    });
  }

  Future<void> updatePartStatus(
    String id,
    String orderId,
    PartStatus status,
  ) async {
    await _client
        .from('repair_order_parts')
        .update({'status': status.name})
        .eq('id', id);
    if (status == PartStatus.received || status == PartStatus.installed) {
      await logRepairOrderEvent(
        _client,
        orderId: orderId,
        actorRole: 'admin',
        eventType: 'part_status',
        description: status == PartStatus.received
            ? 'Pièce reçue'
            : 'Pièce installée',
      );
    }
  }

  Future<void> removePart(String id) async {
    await _client.from('repair_order_parts').delete().eq('id', id);
  }

  Future<void> sendMessage({
    required String orderId,
    required RepairMessageSenderRole senderRole,
    required String body,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    await _client.from('repair_order_messages').insert({
      'order_id': orderId,
      'sender_role': senderRole.name,
      'body': body,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
    });
  }

  Future<(String, String)> uploadMessageAttachment(
    String orderId,
    Uint8List bytes,
    String fileName,
  ) async {
    final ext = fileName.split('.').last.toLowerCase();
    const videoExts = {'mp4', 'mov', 'avi', 'webm', 'mkv'};
    final type = videoExts.contains(ext) ? 'video' : 'image';
    final path = '$orderId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage
        .from('repair-order-attachments')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage
        .from('repair-order-attachments')
        .getPublicUrl(path);
    return (url, type);
  }

  Future<void> assignTechnician(String orderDbId, String? technicianId) async {
    await _client
        .from('repair_orders')
        .update({'technician_id': technicianId})
        .eq('id', orderDbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'admin',
      eventType: 'technician_assigned',
      description: technicianId == null
          ? 'Technicien retiré du dossier'
          : 'Technicien assigné au dossier',
    );
  }

  Future<void> updateArrivalCondition(
    String orderDbId,
    String condition,
  ) async {
    await _client
        .from('repair_orders')
        .update({'arrival_condition': condition})
        .eq('id', orderDbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'admin',
      eventType: 'arrival_condition',
      description: 'État à l\'arrivée mis à jour : $condition',
    );
  }

  Future<void> updateDropoffAndAppointment(
    String orderDbId, {
    String? dropoffDate,
    String? appointmentDay,
    String? appointmentTime,
  }) async {
    await _client
        .from('repair_orders')
        .update({
          'dropoff_date': dropoffDate,
          'appointment_day': appointmentDay,
          'appointment_time': appointmentTime,
        })
        .eq('id', orderDbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'admin',
      eventType: 'dropoff_updated',
      description: 'Informations de dépôt mises à jour',
    );
  }

  Future<String> uploadDropoffReport(
    String orderDbId,
    Uint8List bytes,
    String fileName,
  ) async {
    final path =
        '$orderDbId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage
        .from('dropoff-reports')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('dropoff-reports').getPublicUrl(path);
    await _client
        .from('repair_orders')
        .update({'dropoff_report_url': url})
        .eq('id', orderDbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'admin',
      eventType: 'dropoff_report',
      description: 'PV de dépôt ajouté',
    );
    return url;
  }

  Future<void> linkScooter(String orderDbId, String? scooterId) async {
    await _client
        .from('repair_orders')
        .update({'scooter_id': scooterId})
        .eq('id', orderDbId);
  }

  Future<void> toggleDropoffCheck(String checkId, bool done) async {
    await _client
        .from('repair_order_dropoff_checks')
        .update({'done': done, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', checkId);
  }

  Future<void> updateDropoffClientNote(String orderDbId, String note) async {
    await _client
        .from('repair_orders')
        .update({'dropoff_client_note': note})
        .eq('id', orderDbId);
  }

  /// Sème la checklist de vérification au dépôt pour un dossier créé avant
  /// l'existence de cette fonctionnalité (les nouveaux dossiers l'ont déjà via
  /// `addOrder`). Ne fait rien si des lignes existent déjà.
  Future<void> ensureDropoffChecks(String orderDbId) async {
    final existing = await _client
        .from('repair_order_dropoff_checks')
        .select('id')
        .eq('order_id', orderDbId)
        .limit(1);
    if ((existing as List).isNotEmpty) return;
    await _client.from('repair_order_dropoff_checks').insert([
      for (var i = 0; i < dropoffCheckTemplate.length; i++)
        {
          'order_id': orderDbId,
          'key': dropoffCheckTemplate[i].$1,
          'label': dropoffCheckTemplate[i].$2,
          'position': i,
        },
    ]);
  }

  /// Sème la checklist d'une étape précise pour un dossier créé avant que
  /// cette étape n'ait de modèle détaillé (ex. "Diagnostic en cours" avant
  /// l'ajout de son template) — ne fait rien si des tâches existent déjà.
  Future<void> ensureStepTasks(
    String orderDbId,
    String stepId,
    String stepLabel,
  ) async {
    final existing = await _client
        .from('repair_order_step_tasks')
        .select('id')
        .eq('step_id', stepId)
        .limit(1);
    if ((existing as List).isNotEmpty) return;
    final template = templateForStep(stepLabel);
    if (template.isEmpty) return;
    await _client.from('repair_order_step_tasks').insert([
      for (var i = 0; i < template.length; i++)
        {
          'order_id': orderDbId,
          'step_id': stepId,
          'kind': template[i].kind.name,
          'label': template[i].label,
          'position': i,
          'counter_target': template[i].counterTarget,
        },
    ]);
  }
}

final repairOrderDetailActionsProvider = Provider<RepairOrderDetailActions>(
  (ref) => RepairOrderDetailActions(ref.watch(supabaseProvider)),
);
