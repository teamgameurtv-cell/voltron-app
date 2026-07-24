import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/repair.dart';
import '../../models/repair_order_photo.dart';
import '../../models/repair_step_task.dart';
import '../../models/scooter.dart';
import '../../models/technician.dart';
import '../../providers/admin_crm_provider.dart';
import '../../providers/repair_order_detail_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/technicians_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/repair_step_tracker.dart';

/// Texte rassurant, en langage clair, associé à chaque étape — affiché sur la
/// carte "Étape actuelle" pour que le client comprenne où en est son dossier
/// sans avoir à interpréter la frise.
const Map<String, String> _stepDescriptions = {
  'Rendez-vous pris':
      'Votre rendez-vous est confirmé, présentez-vous à l\'atelier à la date prévue.',
  'Trottinette déposée':
      'Votre trottinette a bien été prise en charge par notre équipe. '
      'Nous allons commencer le diagnostic.',
  'Diagnostic en cours':
      'Notre technicien examine votre trottinette pour identifier les réparations nécessaires.',
  'Devis envoyé':
      'Un devis vous a été envoyé, merci de le consulter pour valider la réparation.',
  'Pièces commandées':
      'Les pièces nécessaires à la réparation ont été commandées.',
  'Réparation en cours':
      'Votre trottinette est en cours de réparation par notre équipe.',
  'Prête à récupérer':
      'Votre trottinette est prête ! Vous pouvez venir la récupérer en boutique.',
  'Récupérée':
      'Dossier clôturé, votre trottinette vous a été remise. Merci de votre confiance !',
};

/// Écran plein cadre du suivi de dossier côté client — reprend la maquette :
/// en-tête avec statut et contact, infos de dépôt/estimation/technicien,
/// frise d'étapes, étape actuelle détaillée, fiche véhicule, historique et
/// accès rapide à la messagerie avec l'atelier.
class ClientRepairOrderScreen extends ConsumerWidget {
  final String orderId;

  const ClientRepairOrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(repairsProvider);
    RepairOrder? order;
    for (final o in orders) {
      if (o.dbId == orderId) {
        order = o;
        break;
      }
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: VoltronColors.deepBlack,
        appBar: AppBar(
          backgroundColor: VoltronColors.deepBlack,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: const Center(
          child: Text(
            'Dossier introuvable.',
            style: TextStyle(color: VoltronColors.greyText),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            _Header(order: order),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _InfoRow(order: order),
                  const SizedBox(height: 24),
                  const Text(
                    'SUIVI DE VOTRE DOSSIER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: VoltronColors.greyText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RepairStepTracker(steps: order.steps),
                  const SizedBox(height: 20),
                  _CurrentStepCard(order: order),
                  const SizedBox(height: 16),
                  _VehicleInfoCard(order: order),
                  const SizedBox(height: 16),
                  _HistoryCard(order: order),
                  const SizedBox(height: 16),
                  _HelpCard(orderId: order.dbId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final RepairOrder order;

  const _Header({required this.order});

  @override
  Widget build(BuildContext context) {
    final isComplete = order.isComplete;
    final Color statusColor;
    final String statusLabel;
    if (isComplete) {
      statusColor = VoltronColors.success;
      statusLabel = 'Terminée';
    } else if (order.isBlockedOnQuote) {
      statusColor = VoltronColors.warning;
      statusLabel = 'Devis en attente';
    } else {
      statusColor = VoltronColors.electricBlueGlow;
      statusLabel = 'En cours';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              Flexible(
                child: Text(
                  'Dossier #${order.id}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(VoltronRadii.pill),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    order.scooterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: VoltronColors.greyText,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () =>
                      context.push('/repairs/messages/${order.dbId}'),
                  icon: const Icon(Icons.storefront_rounded, size: 14),
                  label: const Text(
                    'Contacter le magasin',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vignette véhicule + statistiques disponibles (dépôt, estimation du devis,
/// technicien assigné) — chaque statistique n'apparaît que si la donnée
/// correspondante existe réellement, sans rien inventer.
class _InfoRow extends ConsumerWidget {
  final RepairOrder order;

  const _InfoRow({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scooter = _resolveScooter(ref, order);

    Technician? technician;
    if (order.technicianId != null) {
      final technicians = ref.watch(techniciansProvider).valueOrNull ?? [];
      for (final t in technicians) {
        if (t.id == order.technicianId) {
          technician = t;
          break;
        }
      }
    }

    final stats = <Widget>[];
    if (order.dropoffDate != null) {
      stats.add(_InfoStat(label: 'Dépôt', value: order.dropoffDate!));
    } else if (order.appointmentDay != null) {
      stats.add(
        _InfoStat(
          label: 'Rendez-vous',
          value: order.appointmentTime != null
              ? '${order.appointmentDay} à ${order.appointmentTime}'
              : order.appointmentDay!,
        ),
      );
    }
    if ((order.quote?.estimatedDelay ?? '').isNotEmpty) {
      stats.add(
        _InfoStat(label: 'Estimation', value: order.quote!.estimatedDelay),
      );
    }
    if (technician != null) {
      stats.add(
        _InfoStat(
          label: 'Technicien',
          value: technician.name,
          statusLabel: technician.statusLabel,
          statusColor: technician.status == TechnicianStatus.enLigne
              ? VoltronColors.success
              : VoltronColors.greyText,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: VoltronColors.deepBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.sm),
            ),
            child: (scooter?.imageUrl ?? '').isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(VoltronRadii.sm),
                    child: Image.network(
                      scooter!.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.electric_scooter_rounded,
                    color: VoltronColors.electricYellow,
                    size: 26,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: stats.isEmpty
                ? const Text(
                    'Informations à venir',
                    style: TextStyle(
                      color: VoltronColors.greyText,
                      fontSize: 12,
                    ),
                  )
                : Wrap(spacing: 18, runSpacing: 10, children: stats),
          ),
        ],
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  final String? statusLabel;
  final Color? statusColor;

  const _InfoStat({
    required this.label,
    required this.value,
    this.statusLabel,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: VoltronColors.greyText,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        if (statusLabel != null)
          Text(
            statusLabel!,
            style: TextStyle(fontSize: 11, color: statusColor),
          ),
      ],
    );
  }
}

/// Repère le véhicule enregistré correspondant à ce dossier — même logique
/// que côté admin (par id si lié, sinon par nom), mais sans jamais persister
/// le lien : seul l'admin a le droit d'écrire sur repair_orders (RLS).
OwnedScooter? _resolveScooter(WidgetRef ref, RepairOrder order) {
  if (order.scooterId != null) {
    return ref.watch(scooterByIdProvider(order.scooterId!)).valueOrNull;
  }
  final clientScooters =
      ref.watch(clientScootersProvider(order.clientId)).valueOrNull ?? [];
  final query = order.scooterName.toLowerCase();
  final matches = clientScooters
      .where(
        (s) =>
            query.contains(s.model.toLowerCase()) ||
            query.contains(s.brand.toLowerCase()),
      )
      .toList();
  if (matches.length == 1) return matches.first;
  if (clientScooters.length == 1) return clientScooters.first;
  return null;
}

class _CurrentStepCard extends ConsumerWidget {
  final RepairOrder order;

  const _CurrentStepCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = order.currentStep;
    final tasks =
        ref
            .watch(stepTasksProvider(order.dbId))
            .valueOrNull
            ?.where((t) => t.stepId == step.id)
            .toList() ??
        [];
    final noteTasks = tasks
        .where(
          (t) =>
              t.kind == RepairStepTaskKind.note &&
              (t.valueText ?? '').trim().isNotEmpty,
        )
        .toList();
    final photoTaskIds = tasks
        .where((t) => t.kind == RepairStepTaskKind.counter)
        .map((t) => t.id)
        .toSet();
    final photos = photoTaskIds.isEmpty
        ? const <RepairOrderPhoto>[]
        : (ref.watch(repairOrderPhotosProvider(order.dbId)).valueOrNull ?? [])
              .where((p) => photoTaskIds.contains(p.stepTaskId))
              .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoltronColors.electricYellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VoltronRadii.md),
        border: Border.all(
          color: VoltronColors.electricYellow.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: VoltronColors.electricYellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stepIcons[step.label] ?? Icons.circle_outlined,
                  color: VoltronColors.electricYellow,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'ÉTAPE ACTUELLE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: VoltronColors.electricYellow,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _stepDescriptions[step.label] ?? '',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          if (noteTasks.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...noteTasks.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${t.label} : ${t.valueText}',
                  style: const TextStyle(
                    color: VoltronColors.electricBlueGlow,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(VoltronRadii.sm),
                  child: Image.network(
                    photos[index].url,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          if (order.quote != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/repairs/quote/${order.dbId}'),
              child: const Text(
                'VOIR LE DEVIS',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VehicleInfoCard extends ConsumerWidget {
  final RepairOrder order;

  const _VehicleInfoCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scooter = _resolveScooter(ref, order);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INFORMATIONS SUR VOTRE TROTTINETTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: VoltronColors.greyText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (scooter != null) ...[
            _InfoLine('Marque / Modèle', '${scooter.brand} ${scooter.model}'),
            if (scooter.serialNumber.isNotEmpty)
              _InfoLine('N° de série', scooter.serialNumber),
            _InfoLine('Kilométrage', '${scooter.mileageKm} km'),
            if (scooter.batterySpec.isNotEmpty)
              _InfoLine('Batterie', scooter.batterySpec),
            if (scooter.color.isNotEmpty) _InfoLine('Couleur', scooter.color),
          ] else
            _InfoLine('Véhicule', order.scooterName),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/account/garage'),
            child: const Text(
              'Voir la fiche complète',
              style: TextStyle(
                color: VoltronColors.electricBlueGlow,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: VoltronColors.greyText, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Historique réel du dossier : uniquement les étapes déjà atteintes (celles
/// qui ont une date), du plus récent au plus ancien — [RepairStep.date] est
/// posé automatiquement quand une étape devient active, donc rien n'est
/// reconstitué artificiellement.
class _HistoryCard extends StatelessWidget {
  final RepairOrder order;

  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final reached = order.steps
        .where((s) => s.date != null)
        .toList()
        .reversed
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HISTORIQUE DU DOSSIER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: VoltronColors.greyText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          if (reached.isEmpty)
            const Text(
              'Aucun évènement pour le moment.',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
            )
          else
            ...reached.map(
              (step) => _HistoryRow(
                orderId: order.dbId,
                step: step,
                isCurrent: step.id == order.currentStep.id,
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  final String orderId;
  final RepairStep step;
  final bool isCurrent;

  const _HistoryRow({
    required this.orderId,
    required this.step,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = isCurrent
        ? VoltronColors.electricYellow
        : VoltronColors.success;
    final noteTasks =
        ref
            .watch(stepTasksProvider(orderId))
            .valueOrNull
            ?.where(
              (t) =>
                  t.stepId == step.id &&
                  t.kind == RepairStepTaskKind.note &&
                  (t.valueText ?? '').trim().isNotEmpty,
            )
            .toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        step.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: VoltronColors.electricYellow.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(
                            VoltronRadii.pill,
                          ),
                        ),
                        child: const Text(
                          'Étape actuelle',
                          style: TextStyle(
                            fontSize: 9,
                            color: VoltronColors.electricYellow,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  step.date ?? '',
                  style: const TextStyle(
                    color: VoltronColors.greyText,
                    fontSize: 11,
                  ),
                ),
                if ((step.note ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      step.note!,
                      style: const TextStyle(
                        color: VoltronColors.electricBlueGlow,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ...noteTasks.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${t.label} : ${t.valueText}',
                      style: const TextStyle(
                        color: VoltronColors.electricBlueGlow,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final String orderId;

  const _HelpCard({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Besoin d\'aide ?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Notre équipe est à votre disposition pour répondre à toutes vos questions.',
            style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/repairs/messages/$orderId'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text('Envoyer un message'),
          ),
        ],
      ),
    );
  }
}
