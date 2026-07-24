import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repair_step_task_templates.dart';
import '../models/app_notification.dart';
import '../models/booking.dart';
import '../models/repair.dart';
import 'admin_notifications_provider.dart';
import 'auth_provider.dart';
import 'notifications_provider.dart';
import 'repair_order_events_log.dart';

String _today() {
  final now = DateTime.now();
  return '${now.day} ${bookingMonthNames[now.month - 1]} ${now.year}';
}

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
    _ordersSub = _client
        .from('repair_orders')
        .stream(primaryKey: ['id'])
        .listen((rows) {
          _orders = rows;
          _rebuild();
        });
    _stepsSub = _client.from('repair_steps').stream(primaryKey: ['id']).listen((
      rows,
    ) {
      _steps = rows;
      _rebuild();
    });
    _quotesSub = _client.from('quotes').stream(primaryKey: ['id']).listen((
      rows,
    ) {
      _quotes = rows;
      _rebuild();
    });
    _quoteLinesSub = _client
        .from('quote_lines')
        .stream(primaryKey: ['id'])
        .listen((rows) {
          _quoteLines = rows;
          _rebuild();
        });
  }

  void _rebuild() {
    state =
        _orders.where((o) => _steps.any((s) => s['order_id'] == o['id'])).map((
          o,
        ) {
          final steps = _steps.where((s) => s['order_id'] == o['id']).toList()
            ..sort(
              (a, b) => (a['position'] as int).compareTo(b['position'] as int),
            );
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
                .map(
                  (l) => QuoteLine(
                    l['label'] as String,
                    (l['price'] as num).toDouble(),
                  ),
                )
                .toList();
            quote = Quote(
              dbId: quoteMap['id'] as String,
              id: quoteMap['display_id'] as String,
              date: quoteMap['quote_date'] as String,
              estimatedDelay: quoteMap['estimated_delay'] as String? ?? '',
              status: QuoteStatus.values.byName(quoteMap['status'] as String),
              fileUrl: quoteMap['file_url'] as String?,
              note: quoteMap['note'] as String?,
              lines: lines,
              depositAmount: (quoteMap['deposit_amount'] as num?)?.toDouble(),
              depositStatus: DepositStatus.values.byName(
                quoteMap['deposit_status'] as String? ?? 'none',
              ),
              depositMethod: switch (quoteMap['deposit_method'] as String?) {
                'online' => DepositMethod.online,
                'in_store' => DepositMethod.inStore,
                _ => null,
              },
              depositPaidAt: quoteMap['deposit_paid_at'] as String?,
            );
          }
          return RepairOrder(
            dbId: o['id'] as String,
            id: o['display_id'] as String,
            scooterName: o['scooter_name'] as String,
            clientId: o['client_id'] as String,
            archived: o['archived'] as bool? ?? false,
            scooterId: o['scooter_id'] as String?,
            technicianId: o['technician_id'] as String?,
            dropoffDate: o['dropoff_date'] as String?,
            appointmentDay: o['appointment_day'] as String?,
            appointmentTime: o['appointment_time'] as String?,
            arrivalCondition:
                o['arrival_condition'] as String? ?? 'À compléter',
            dropoffReportUrl: o['dropoff_report_url'] as String?,
            dropoffClientNote: o['dropoff_client_note'] as String?,
            steps: steps
                .map(
                  (s) => RepairStep(
                    id: s['id'] as String,
                    label: s['label'] as String,
                    status: RepairStepStatus.values.byName(
                      s['status'] as String,
                    ),
                    date: s['step_date'] as String?,
                    position: s['position'] as int,
                    note: s['note'] as String?,
                  ),
                )
                .toList(),
            quote: quote,
          );
        }).toList()..sort((a, b) => b.dbId.compareTo(a.dbId));
  }

  Future<void> addOrder({
    required String displayId,
    required String scooterName,
    required String clientId,
    String? note,
    String? scooterId,
    String? dropoffDate,
    String? appointmentDay,
    String? appointmentTime,
  }) async {
    final orderRow = await _client
        .from('repair_orders')
        .insert({
          'display_id': displayId,
          'scooter_name': scooterName,
          'client_id': clientId,
          'scooter_id': scooterId,
          'dropoff_date': dropoffDate,
          'appointment_day': appointmentDay,
          'appointment_time': appointmentTime,
        })
        .select()
        .single();

    final stepRows = await _client.from('repair_steps').insert([
      for (var i = 0; i < repairStepLabels.length; i++)
        {
          'order_id': orderRow['id'],
          'label': repairStepLabels[i],
          'status': i == 0 ? 'current' : 'pending',
          'step_date': i == 0 ? _today() : null,
          'position': i,
          if (i == 0 && note != null && note.trim().isNotEmpty)
            'note': note.trim(),
        },
    ]).select();

    // Sème la checklist de chaque étape à partir du modèle — comme les 8
    // repair_steps ci-dessus, tout est créé d'un coup pour que la checklist
    // de l'étape courante soit toujours prête, quelle que soit l'étape.
    final taskRows = <Map<String, dynamic>>[];
    for (final stepRow in stepRows) {
      final label = stepRow['label'] as String;
      final template = templateForStep(label);
      for (var i = 0; i < template.length; i++) {
        final t = template[i];
        taskRows.add({
          'order_id': orderRow['id'],
          'step_id': stepRow['id'],
          'kind': t.kind.name,
          'label': t.label,
          'position': i,
          'counter_target': t.counterTarget,
        });
      }
    }
    if (taskRows.isNotEmpty) {
      await _client.from('repair_order_step_tasks').insert(taskRows);
    }

    // Sème la checklist fixe de vérification au dépôt (freins, accélération...).
    await _client.from('repair_order_dropoff_checks').insert([
      for (var i = 0; i < dropoffCheckTemplate.length; i++)
        {
          'order_id': orderRow['id'],
          'key': dropoffCheckTemplate[i].$1,
          'label': dropoffCheckTemplate[i].$2,
          'position': i,
        },
    ]);

    await logRepairOrderEvent(
      _client,
      orderId: orderRow['id'] as String,
      actorRole: 'admin',
      eventType: 'created',
      description: 'Dossier créé',
    );
  }

  Future<void> advanceStep(String orderDbId) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    if (order.isBlockedOnQuote) return;

    final currentIndex = order.steps.indexWhere(
      (s) => s.status == RepairStepStatus.current,
    );
    if (currentIndex == -1) return;

    final stepsRows = _steps.where((s) => s['order_id'] == orderDbId).toList()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

    await _client
        .from('repair_steps')
        .update({'status': 'done'})
        .eq('id', stepsRows[currentIndex]['id']);

    // Dernière étape validée ("Récupérée") : le dossier est terminé, on
    // l'archive automatiquement pour qu'il quitte la liste/le kanban actifs.
    if (currentIndex >= order.steps.length - 1) {
      await _client
          .from('repair_orders')
          .update({'archived': true})
          .eq('id', orderDbId);
      await logRepairOrderEvent(
        _client,
        orderId: orderDbId,
        actorRole: 'admin',
        eventType: 'step_advanced',
        description: 'Dossier clôturé (${order.steps.last.label})',
      );
      ref
          .read(notificationsProvider.notifier)
          .notifyClient(
            order.clientId,
            type: NotificationType.repair,
            title: 'Réparation #${order.id}',
            body: 'Dossier clôturé. Merci de votre confiance !',
          );
      return;
    }

    await _client
        .from('repair_steps')
        .update({'status': 'current', 'step_date': _today()})
        .eq('id', stepsRows[currentIndex + 1]['id']);

    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'admin',
      eventType: 'step_advanced',
      description: 'Étape suivante : ${order.steps[currentIndex + 1].label}',
    );

    ref
        .read(notificationsProvider.notifier)
        .notifyClient(
          order.clientId,
          type: NotificationType.repair,
          title: 'Réparation #${order.id}',
          body: 'Nouvelle étape : ${order.steps[currentIndex + 1].label}.',
        );
  }

  Future<void> setArchived(String orderDbId, bool archived) async {
    await _client
        .from('repair_orders')
        .update({'archived': archived})
        .eq('id', orderDbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'admin',
      eventType: archived ? 'archived' : 'unarchived',
      description: archived ? 'Dossier archivé' : 'Dossier désarchivé',
    );
  }

  /// Envoie un devis (lignes détaillées et/ou fichier joint) et fait avancer le
  /// dossier de "Diagnostic en cours" à "Devis envoyé".
  Future<void> createQuote(
    String orderDbId, {
    required List<QuoteLine> lines,
    required String estimatedDelay,
    String? fileUrl,
    String? note,
    double? depositAmount,
  }) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    final displayId = '${1000 + DateTime.now().millisecond}';
    final quoteRow = await _client
        .from('quotes')
        .insert({
          'order_id': orderDbId,
          'display_id': displayId,
          'quote_date': _today(),
          'estimated_delay': estimatedDelay,
          'file_url': fileUrl,
          'note': note,
          'status': 'pendingApproval',
          'deposit_amount': depositAmount,
          'deposit_status': (depositAmount ?? 0) > 0 ? 'pending' : 'none',
        })
        .select()
        .single();

    if (lines.isNotEmpty) {
      await _client.from('quote_lines').insert([
        for (final line in lines)
          {
            'quote_id': quoteRow['id'],
            'label': line.label,
            'price': line.price,
          },
      ]);
    }

    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'admin',
      eventType: 'quote_sent',
      description: 'Devis envoyé au client',
    );
    await advanceStep(orderDbId);
    ref
        .read(notificationsProvider.notifier)
        .notifyClient(
          order.clientId,
          type: NotificationType.repair,
          title: 'Réparation #${order.id}',
          body:
              'Ton devis est disponible, consulte-le pour valider la réparation.',
        );
  }

  /// Modifie un devis déjà envoyé (lignes et/ou fichier joint). Si le client
  /// l'avait refusé, le renvoyer le remet "en attente" et le client est
  /// prévenu — sinon un devis refusé resterait bloqué sans aucun moyen de
  /// le corriger depuis l'app.
  Future<void> updateQuote(
    String quoteDbId, {
    required List<QuoteLine> lines,
    required String estimatedDelay,
    String? fileUrl,
    String? note,
    double? depositAmount,
  }) async {
    final order = state.firstWhere((o) => o.quote?.dbId == quoteDbId);
    final existingQuote = order.quote;
    // Un acompte déjà payé ne doit pas repasser "en attente" si l'admin
    // modifie juste le devis ensuite (délai, pièce jointe...).
    final alreadyPaid = existingQuote?.depositStatus == DepositStatus.paid;
    final wasRefused = existingQuote?.status == QuoteStatus.refused;
    await _client
        .from('quotes')
        .update({
          'estimated_delay': estimatedDelay,
          'file_url': fileUrl,
          'note': note,
          'deposit_amount': depositAmount,
          'deposit_status': (depositAmount ?? 0) <= 0
              ? 'none'
              : (alreadyPaid ? 'paid' : 'pending'),
          if (wasRefused) 'status': 'pendingApproval',
        })
        .eq('id', quoteDbId);

    await _client.from('quote_lines').delete().eq('quote_id', quoteDbId);
    if (lines.isNotEmpty) {
      await _client.from('quote_lines').insert([
        for (final line in lines)
          {'quote_id': quoteDbId, 'label': line.label, 'price': line.price},
      ]);
    }

    if (wasRefused) {
      await logRepairOrderEvent(
        _client,
        orderId: order.dbId,
        actorRole: 'admin',
        eventType: 'quote_resent',
        description: 'Devis révisé renvoyé après refus',
      );
      ref
          .read(notificationsProvider.notifier)
          .notifyClient(
            order.clientId,
            type: NotificationType.repair,
            title: 'Réparation #${order.id}',
            body: 'Un devis révisé est disponible, merci de le consulter.',
          );
    }
  }

  Future<String> uploadQuoteFile(Uint8List bytes, String fileName) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage
        .from('quote-files')
        .uploadBinary(
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
    await _client
        .from('quotes')
        .update({'status': 'accepted'})
        .eq('id', order.quote!.dbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'client',
      eventType: 'quote_accepted',
      description: 'Devis accepté par le client',
    );
    await notifyAdmin(
      _client,
      orderId: orderDbId,
      title: 'Devis validé — Dossier #${order.id}',
      body: 'Le client a validé le devis, la réparation peut démarrer.',
    );
    await advanceStep(orderDbId);
  }

  Future<void> refuseQuote(String orderDbId) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    if (order.quote == null) return;
    await _client
        .from('quotes')
        .update({'status': 'refused'})
        .eq('id', order.quote!.dbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'client',
      eventType: 'quote_refused',
      description: 'Devis refusé par le client',
    );
    await notifyAdmin(
      _client,
      orderId: orderDbId,
      title: 'Devis refusé — Dossier #${order.id}',
      body:
          'Le client a refusé le devis. Modifiez-le pour lui renvoyer une nouvelle proposition.',
    );
  }

  /// Le client paie l'acompte directement dans l'app (paiement simulé, comme
  /// Voltron Care) : marqué payé immédiatement et l'admin en est informé.
  Future<void> payDepositOnline(String orderDbId) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    final quote = order.quote;
    if (quote == null) return;
    await _client
        .from('quotes')
        .update({
          'deposit_status': 'paid',
          'deposit_method': 'online',
          'deposit_paid_at': DateTime.now().toIso8601String(),
        })
        .eq('id', quote.dbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'client',
      eventType: 'deposit_paid',
      description:
          'Acompte de ${quote.depositAmount?.toStringAsFixed(2)} € payé en ligne',
    );
    await notifyAdmin(
      _client,
      orderId: orderDbId,
      title: 'Acompte payé — Dossier #${order.id}',
      body:
          '${quote.depositAmount?.toStringAsFixed(2)} € réglés en ligne par le client.',
    );
  }

  /// Le client choisit de régler l'acompte en boutique : l'admin devra le
  /// marquer comme reçu une fois le paiement effectué en magasin.
  Future<void> chooseDepositInStore(String orderDbId) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    final quote = order.quote;
    if (quote == null) return;
    await _client
        .from('quotes')
        .update({'deposit_method': 'in_store'})
        .eq('id', quote.dbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'client',
      eventType: 'deposit_choice_in_store',
      description: 'Le client réglera l\'acompte en boutique',
    );
  }

  /// Action admin : encaissement de l'acompte constaté en magasin.
  Future<void> markDepositPaidInStore(String orderDbId) async {
    final order = state.firstWhere((o) => o.dbId == orderDbId);
    final quote = order.quote;
    if (quote == null) return;
    await _client
        .from('quotes')
        .update({
          'deposit_status': 'paid',
          'deposit_method': 'in_store',
          'deposit_paid_at': DateTime.now().toIso8601String(),
        })
        .eq('id', quote.dbId);
    await logRepairOrderEvent(
      _client,
      orderId: orderDbId,
      actorRole: 'admin',
      eventType: 'deposit_paid',
      description:
          'Acompte de ${quote.depositAmount?.toStringAsFixed(2)} € encaissé en magasin',
    );
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

final repairsProvider =
    StateNotifierProvider<RepairsNotifier, List<RepairOrder>>(
      (ref) => RepairsNotifier(ref, ref.watch(supabaseProvider)),
    );
