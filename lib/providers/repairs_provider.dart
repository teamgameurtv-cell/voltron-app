import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';
import '../models/repair.dart';
import 'auth_provider.dart';
import 'notifications_provider.dart';

const List<String> repairStepLabels = [
  'Rendez-vous pris',
  'Trottinette déposée',
  'Diagnostic en cours',
  'Devis envoyé',
  'Pièces commandées',
  'Réparation en cours',
  'Prête à récupérer',
  'Récupérée',
];

class RepairsNotifier extends StateNotifier<List<RepairOrder>> {
  final Ref ref;
  final SupabaseClient _client;
  StreamSubscription? _ordersSub;
  StreamSubscription? _stepsSub;
  StreamSubscription? _quotesSub;
  StreamSubscription? _quoteLinesSub;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _steps = [];
  List<Map<String, dynamic>> _quotes = [];
  List<Map<String, dynamic>> _quoteLines = [];

  RepairsNotifier(this.ref, this._client) : super([]) {
    _ordersSub = _client.from('repair_orders').stream(primaryKey: ['id']).listen((rows) {
      _orders = rows;
      _rebuild();
    });
    _stepsSub = _client.from('repair_steps').stream(primaryKey: ['id']).listen((rows) {
      _steps = rows;
      _rebuild();
    });
    _quotesSub = _client.from('quotes').stream(primaryKey: ['id']).listen((rows) {
      _quotes = rows;
      _rebuild();
    });
    _quoteLinesSub = _client.from('quote_lines').stream(primaryKey: ['id']).listen((rows) {
      _quoteLines = rows;
      _rebuild();
    });
  }

  void _rebuild() {
    state = _orders.where((o) => _steps.any((s) => s['order_id'] == o['id'])).map((o) {
      final steps = _steps.where((s) => s['order_id'] == o['id']).toList()
        ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
      Map<String, dynamic>? quoteMap;
      for (final q in _quotes) {
        if (q['order_id'] == o['id']) {
          quoteMap = q;
          break;
        }
      }
      Quote? quote;
      if (quoteMap != null) {
        final lines = _quoteLines
            .where((l) => l['quote_id'] == quoteMap!['id'])
            .map((l) => QuoteLine(l['label'] as String, (l['price'] as num).toDouble()))
            .toList();
        quote = Quote(
          dbId: quoteMap['id'] as String,
          id: quoteMap['display_id'] as String,
          date: quoteMap['quote_date'] as String,
          estimatedDelay: quoteMap['estimated_delay'] as String? ?? '',
          status: QuoteStatus.values.byName(quoteMap['status'] as String),
          fileUrl: quoteMap['file_url'] as String?,
          lines: lines,
        );
      }
      return RepairOrder(
        dbId: o['id'] as String,
        id: o['display_id'] as String,
        scooterName: o['scooter_name'] as String,
        clientId: o['client_id'] as String,
        steps: steps
            .map((s) => RepairStep(
                  id: s['id'] as String,
                  label: s['label'] as String,
                  status: RepairStepStatus.values.byName(s['status'] as String),
                  date: s['step_date'] as String?,
                  position: s['position'] as int,
                  note: s['note'] as String?,
                ))
            .toList(),
        quote: quote,
      );
    }).toList()
      ..sort((a, b) => b.dbId.compareTo(a.dbId));
  }

  Future<void> addOrder({
    required String displayId,
    required String scooterName,
    required String clientId,
  }) async {
    final orderRow = await _client
        .from('repair_orders')
        .insert({'display_id': displayId, 'scooter_name': scooterName, 'client_id': clientId})
        .select()
        .single();

    await _client.from('repair_steps').insert([
      for (var i = 0; i < repairStepLabels.length; i++)
        {
          'order_id': orderRow['id'],
          'label': repairStepLabels[i],
          'status': i == 0 ? 'current' : 'pending',
          'step_date': i == 0 ? 'Aujourd\'hui' : null,
          'position': i,
        },
    ]);
  }

  Future<void> advanceStep(String orderDbId) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    if (order.isBlockedOnQuote) return;

    final currentIndex = order.steps.indexWhere((s) => s.status == RepairStepStatus.current);
    if (currentIndex == -1 || currentIndex >= order.steps.length - 1) return;

    final stepsRows = _steps.where((s) => s['order_id'] == orderDbId).toList()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

    await _client.from('repair_steps').update({'status': 'done'}).eq('id', stepsRows[currentIndex]['id']);
    await _client.from('repair_steps').update({
      'status': 'current',
      'step_date': 'Aujourd\'hui',
    }).eq('id', stepsRows[currentIndex + 1]['id']);

    ref.read(notificationsProvider.notifier).push(
          type: NotificationType.repair,
          title: 'Réparation #${order.id}',
          body: 'Nouvelle étape : ${order.steps[currentIndex + 1].label}.',
        );
  }

  /// Envoie un devis (lignes détaillées et/ou fichier joint) et fait avancer le
  /// dossier de "Diagnostic en cours" à "Devis envoyé".
  Future<void> createQuote(
    String orderDbId, {
    required List<QuoteLine> lines,
    required String estimatedDelay,
    String? fileUrl,
  }) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    final displayId = '${1000 + DateTime.now().millisecond}';
    final quoteRow = await _client
        .from('quotes')
        .insert({
          'order_id': orderDbId,
          'display_id': displayId,
          'quote_date': 'Aujourd\'hui',
          'estimated_delay': estimatedDelay,
          'file_url': fileUrl,
          'status': 'pendingApproval',
        })
        .select()
        .single();

    if (lines.isNotEmpty) {
      await _client.from('quote_lines').insert([
        for (final line in lines) {'quote_id': quoteRow['id'], 'label': line.label, 'price': line.price},
      ]);
    }

    await advanceStep(orderDbId);
    ref.read(notificationsProvider.notifier).push(
          type: NotificationType.repair,
          title: 'Réparation #${order.id}',
          body: 'Ton devis est disponible, consulte-le pour valider la réparation.',
        );
  }

  /// Modifie un devis déjà envoyé (lignes et/ou fichier joint).
  Future<void> updateQuote(
    String quoteDbId, {
    required List<QuoteLine> lines,
    required String estimatedDelay,
    String? fileUrl,
  }) async {
    await _client.from('quotes').update({
      'estimated_delay': estimatedDelay,
      'file_url': fileUrl,
    }).eq('id', quoteDbId);

    await _client.from('quote_lines').delete().eq('quote_id', quoteDbId);
    if (lines.isNotEmpty) {
      await _client.from('quote_lines').insert([
        for (final line in lines) {'quote_id': quoteDbId, 'label': line.label, 'price': line.price},
      ]);
    }
  }

  Future<String> uploadQuoteFile(Uint8List bytes, String fileName) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('quote-files').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('quote-files').getPublicUrl(path);
  }

  Future<void> updateStepNote(String stepId, String? note) async {
    await _client.from('repair_steps').update({'note': note}).eq('id', stepId);
  }

  Future<void> acceptQuote(String orderDbId) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    if (order.quote == null) return;
    await _client.from('quotes').update({'status': 'accepted'}).eq('id', order.quote!.dbId);
    await advanceStep(orderDbId);
  }

  Future<void> refuseQuote(String orderDbId) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    if (order.quote == null) return;
    await _client.from('quotes').update({'status': 'refused'}).eq('id', order.quote!.dbId);
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _stepsSub?.cancel();
    _quotesSub?.cancel();
    _quoteLinesSub?.cancel();
    super.dispose();
  }
}

final repairsProvider = StateNotifierProvider<RepairsNotifier, List<RepairOrder>>(
  (ref) => RepairsNotifier(ref, ref.watch(supabaseProvider)),
);
