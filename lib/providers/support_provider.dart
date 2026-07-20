import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_ticket.dart';
import 'auth_provider.dart';

/// Tickets du client connecté (utilisé côté app client).
final myTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return Stream.value(const <SupportTicket>[]);
  return ref
      .watch(supabaseProvider)
      .from('support_tickets')
      .stream(primaryKey: ['id'])
      .eq('client_id', userId)
      .map((rows) => rows.map(SupportTicket.fromMap).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
});

/// Tous les tickets, tous clients confondus (utilisé côté panel admin, RLS réserve ça aux admins).
final allTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  return ref.watch(supabaseProvider).from('support_tickets').stream(primaryKey: ['id']).map(
      (rows) => rows.map(SupportTicket.fromMap).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
});

final ticketMessagesProvider = StreamProvider.family<List<SupportMessage>, String>((ref, ticketId) {
  return ref
      .watch(supabaseProvider)
      .from('support_messages')
      .stream(primaryKey: ['id'])
      .eq('ticket_id', ticketId)
      .map((rows) => rows.map(SupportMessage.fromMap).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
});

class SupportActions {
  final SupabaseClient _client;

  SupportActions(this._client);

  Future<String> createTicket({required String subject, required String firstMessage}) async {
    final userId = _client.auth.currentUser?.id;
    final row = await _client
        .from('support_tickets')
        .insert({'client_id': userId, 'subject': subject})
        .select()
        .single();
    final ticketId = row['id'] as String;
    await sendMessage(ticketId: ticketId, senderRole: SenderRole.client, body: firstMessage);
    return ticketId;
  }

  Future<void> sendMessage({
    required String ticketId,
    required SenderRole senderRole,
    required String body,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    await _client.from('support_messages').insert({
      'ticket_id': ticketId,
      'sender_role': senderRole.name,
      'body': body,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
    });
    await _client.from('support_tickets').update({
      'updated_at': DateTime.now().toIso8601String(),
      if (senderRole == SenderRole.admin) 'status': 'answered',
      if (senderRole == SenderRole.client) 'status': 'open',
    }).eq('id', ticketId);
  }

  Future<void> updateStatus(String ticketId, TicketStatus status) async {
    await _client.from('support_tickets').update({'status': status.name}).eq('id', ticketId);
  }

  /// Envoie une photo/vidéo dans le stockage et retourne son URL + type ('image'/'video').
  Future<(String, String)> uploadAttachment(Uint8List bytes, String fileName) async {
    final ext = fileName.split('.').last.toLowerCase();
    const videoExts = {'mp4', 'mov', 'avi', 'webm', 'mkv'};
    final type = videoExts.contains(ext) ? 'video' : 'image';
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('support-attachments').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final url = _client.storage.from('support-attachments').getPublicUrl(path);
    return (url, type);
  }
}

final supportActionsProvider = Provider<SupportActions>((ref) => SupportActions(ref.watch(supabaseProvider)));
