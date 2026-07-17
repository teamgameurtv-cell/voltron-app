import 'dart:async';
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
                  label: s['label'] as String,
                  status: RepairStepStatus.values.byName(s['status'] as String),
                  date: s['step_date'] as String?,
                  position: s['position'] as int,
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
