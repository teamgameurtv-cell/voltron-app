import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repair_step_task_templates.dart';
import '../../models/repair.dart';
import '../../models/repair_order_part.dart';
import '../../models/repair_step_task.dart';
import '../../models/scooter.dart';
import '../../models/technician.dart';
import '../../providers/admin_crm_provider.dart';
import '../../providers/repair_order_detail_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/technicians_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/care_badge.dart';
import '../../widgets/repair_order_card.dart' show showQuoteDialog;
import '../../widgets/repair_step_tracker.dart';

/// Écran plein cadre du dossier de réparation côté admin — délibérément en
/// dehors de l'AdminShell (pas de sidebar) pour un layout immersif proche du
/// mockup : en-tête avec retour/actions, frise d'étapes, fiches
/// véhicule/client/dépôt/technicien, checklist de l'étape en cours, et une
/// barre d'actions (documents/pièces/messages/historique) en bas.
class AdminRepairOrderScreen extends ConsumerWidget {
  final String orderDbId;

  const AdminRepairOrderScreen({super.key, required this.orderDbId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(repairsProvider);
    RepairOrder? order;
    for (final o in orders) {
      if (o.dbId == orderDbId) {
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  RepairStepTracker(steps: order.steps),
                  const SizedBox(height: 12),
                  _StepGuideCard(order: order),
                  if ((order.quote?.depositAmount ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    _DepositBanner(order: order),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _VehicleCard(order: order)),
                      const SizedBox(width: 12),
                      Expanded(child: _ClientCard(order: order)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _DropoffCard(order: order)),
                      const SizedBox(width: 12),
                      Expanded(child: _TechnicianCard(order: order)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DropoffChecklistCard(order: order),
                  const SizedBox(height: 20),
                  _CurrentStepChecklist(order: order),
                ],
              ),
            ),
            _BottomActionBar(order: order),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final RepairOrder order;

  const _Header({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isComplete = order.isComplete;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Dossier #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (!isComplete) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: VoltronColors.electricYellow,
                      ),
                    ],
                  ],
                ),
                Text(
                  order.scooterName,
                  style: const TextStyle(
                    color: VoltronColors.greyText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: VoltronColors.cardBlack,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'archive') {
                ref
                    .read(repairsProvider.notifier)
                    .setArchived(order.dbId, !order.archived);
              } else if (value == 'edit_quote') {
                showQuoteDialog(context, ref, order, existing: order.quote);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(order.archived ? 'Désarchiver' : 'Archiver'),
              ),
              if (order.quote != null)
                const PopupMenuItem(
                  value: 'edit_quote',
                  child: Text('Modifier le devis'),
                ),
            ],
          ),
          const SizedBox(width: 4),
          _PrimaryActionButton(order: order),
        ],
      ),
    );
  }
}

/// Bouton principal de l'en-tête : reproduit la logique déjà établie dans
/// [RepairOrderCard] (devis à envoyer/valider, sinon étape suivante).
class _PrimaryActionButton extends ConsumerWidget {
  final RepairOrder order;

  const _PrimaryActionButton({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isComplete = order.isComplete;
    final atQuoteStep = order.currentStep.label == 'Diagnostic en cours';

    if (isComplete) {
      return const Text(
        'TERMINÉ',
        style: TextStyle(
          color: VoltronColors.success,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }
    if (order.quote?.status == QuoteStatus.refused) {
      return ElevatedButton(
        onPressed: () =>
            showQuoteDialog(context, ref, order, existing: order.quote),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5C5C),
          foregroundColor: Colors.white,
        ),
        child: const Text('RENVOYER LE DEVIS', style: TextStyle(fontSize: 11)),
      );
    }
    if (order.isBlockedOnQuote) {
      return ElevatedButton(
        onPressed: () =>
            ref.read(repairsProvider.notifier).acceptQuote(order.dbId),
        style: ElevatedButton.styleFrom(
          backgroundColor: VoltronColors.electricBlue,
          foregroundColor: Colors.white,
        ),
        child: const Text('VALIDER LE DEVIS', style: TextStyle(fontSize: 11)),
      );
    }
    if (atQuoteStep) {
      return ElevatedButton(
        onPressed: () => showQuoteDialog(context, ref, order),
        child: const Text('ENVOYER LE DEVIS', style: TextStyle(fontSize: 11)),
      );
    }
    return ElevatedButton(
      onPressed: () =>
          ref.read(repairsProvider.notifier).advanceStep(order.dbId),
      child: const Text('ÉTAPE SUIVANTE', style: TextStyle(fontSize: 11)),
    );
  }
}

/// Instructions en langage clair pour chaque étape — pensées pour qu'un
/// employé qui découvre l'outil sache quoi faire sans avoir à demander,
/// sans se soucier de deviner ce qu'implique une étape technique.
const Map<String, String> _adminStepGuides = {
  'Rendez-vous pris':
      'Le client a réservé un créneau de dépôt. Quand il se présente à '
      'l\'atelier avec sa trottinette, complétez la vérification de dépôt '
      'ci-dessous puis passez à l\'étape suivante.',
  'Trottinette déposée':
      'La trottinette est arrivée à l\'atelier. Terminez la vérification de '
      'dépôt (freins, pneus, état général...) puis passez à l\'étape '
      'Diagnostic.',
  'Diagnostic en cours':
      'Examinez la trottinette et notez le résultat du diagnostic (avec des '
      'photos si besoin) dans la checklist ci-dessous, puis envoyez un devis '
      'au client avec le bouton en haut à droite.',
  'Pièces commandées':
      'Commandez les pièces nécessaires à la réparation (onglet "Pièces" en '
      'bas de l\'écran), puis passez à l\'étape suivante une fois la commande '
      'passée.',
  'Réparation en cours':
      'Effectuez la réparation. Une fois terminée, passez à l\'étape '
      'suivante.',
  'Prête à récupérer':
      'Contactez le client pour qu\'il vienne récupérer sa trottinette en '
      'boutique.',
  'Récupérée':
      'Dossier terminé : la trottinette a été rendue au client. Le dossier '
      'est archivé automatiquement.',
};

/// Carte explicative toujours visible sous la frise : dit clairement où en
/// est le dossier et ce qu'il faut faire — en particulier pour le devis, où
/// le statut (en attente / validé / refusé) change complètement l'action à
/// mener, ce qui n'était pas visible auparavant.
class _StepGuideCard extends StatelessWidget {
  final RepairOrder order;

  const _StepGuideCard({required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.isComplete) return const SizedBox.shrink();
    final step = order.currentStep;
    String text;
    Color color;
    if (step.label == 'Devis envoyé') {
      switch (order.quote?.status) {
        case QuoteStatus.accepted:
          text =
              'Le client a validé le devis ! Vous pouvez passer à l\'étape '
              'suivante.';
          color = VoltronColors.success;
          break;
        case QuoteStatus.refused:
          text =
              'Le client a refusé ce devis. Utilisez le bouton "RENVOYER LE '
              'DEVIS" en haut à droite pour lui proposer une nouvelle offre.';
          color = const Color(0xFFFF5C5C);
          break;
        default:
          text =
              'Le devis a été envoyé, en attente de la réponse du client. '
              'Vous ne pourrez pas avancer tant qu\'il n\'a pas validé (il '
              'peut aussi régler un éventuel acompte directement en '
              'boutique).';
          color = VoltronColors.warning;
      }
    } else {
      text = _adminStepGuides[step.label] ?? '';
      color = VoltronColors.electricBlueGlow;
    }
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VoltronRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rappel visuel du statut de l'acompte, avec l'action manuelle "encaissé en
/// magasin" quand le client a choisi ce mode mais n'a pas encore réglé.
class _DepositBanner extends ConsumerWidget {
  final RepairOrder order;

  const _DepositBanner({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = order.quote!;
    final amountLabel = quote.depositAmount!
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    if (quote.depositStatus == DepositStatus.paid) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: VoltronColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Acompte de $amountLabel € payé ${quote.depositMethod == DepositMethod.online ? 'en ligne' : 'en magasin'}',
              style: const TextStyle(
                color: VoltronColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(
          Icons.hourglass_bottom_rounded,
          size: 14,
          color: VoltronColors.warning,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            quote.depositMethod == DepositMethod.inStore
                ? 'Acompte de $amountLabel € — le client réglera en magasin'
                : 'Acompte de $amountLabel € en attente de paiement',
            style: const TextStyle(
              color: VoltronColors.warning,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => ref
              .read(repairsProvider.notifier)
              .markDepositPaidInStore(order.dbId),
          child: const Text('Marquer payé', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}

Widget _cardWrapper(String title, IconData icon, Widget content) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: VoltronColors.cardBlack,
      borderRadius: BorderRadius.circular(VoltronRadii.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: VoltronColors.electricYellow),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: VoltronColors.greyText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        content,
      ],
    ),
  );
}

class _VehicleCard extends ConsumerWidget {
  final RepairOrder order;

  const _VehicleCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientScooters =
        ref.watch(clientScootersProvider(order.clientId)).valueOrNull ?? [];

    OwnedScooter? scooter;
    if (order.scooterId != null) {
      scooter = ref.watch(scooterByIdProvider(order.scooterId!)).valueOrNull;
    } else {
      // Dossiers créés avant la liaison véhicule : on retrouve le véhicule
      // correspondant chez ce client (par nom, sinon véhicule unique) et on
      // fixe le lien définitivement pour ne plus avoir à le refaire.
      final query = order.scooterName.toLowerCase();
      final matches = clientScooters
          .where(
            (s) =>
                query.contains(s.model.toLowerCase()) ||
                query.contains(s.brand.toLowerCase()),
          )
          .toList();
      if (matches.length == 1) {
        scooter = matches.first;
      } else if (clientScooters.length == 1) {
        scooter = clientScooters.first;
      }
      if (scooter != null) {
        final resolvedId = scooter.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(repairOrderDetailActionsProvider)
              .linkScooter(order.dbId, resolvedId);
        });
      }
    }

    return _cardWrapper(
      'TROTTINETTE',
      Icons.electric_scooter_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scooter != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: VoltronColors.deepBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.sm),
                  ),
                  child:
                      (scooter.imageUrl != null && scooter.imageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(VoltronRadii.sm),
                          child: Image.network(
                            scooter.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.electric_scooter_rounded,
                          color: VoltronColors.electricYellow,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${scooter.brand} ${scooter.model}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (scooter.serialNumber.isNotEmpty)
                        Text(
                          'N° ${scooter.serialNumber}',
                          style: const TextStyle(
                            color: VoltronColors.electricYellow,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          else
            Text(
              order.scooterName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          if (scooter != null) ...[
            const SizedBox(height: 6),
            Text(
              '${scooter.mileageKm} km',
              style: const TextStyle(fontSize: 11),
            ),
            if (scooter.batterySpec.isNotEmpty)
              Text(scooter.batterySpec, style: const TextStyle(fontSize: 11)),
            if (scooter.color.isNotEmpty)
              Text(
                scooter.color,
                style: const TextStyle(
                  color: VoltronColors.greyText,
                  fontSize: 11,
                ),
              ),
          ],
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                context.push('/admin/clients?clientId=${order.clientId}'),
            child: const Text(
              'Voir la fiche complète',
              style: TextStyle(
                color: VoltronColors.electricBlueGlow,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (clientScooters.isNotEmpty)
            GestureDetector(
              onTap: () =>
                  _showLinkScooterDialog(context, ref, order, clientScooters),
              child: Text(
                scooter != null ? 'Changer de véhicule' : 'Lier un véhicule',
                style: const TextStyle(
                  color: VoltronColors.electricBlueGlow,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showLinkScooterDialog(
  BuildContext context,
  WidgetRef ref,
  RepairOrder order,
  List<OwnedScooter> scooters,
) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: VoltronColors.cardBlack,
      title: const Text('Lier un véhicule'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: scooters
              .map(
                (s) => RadioListTile<String?>(
                  value: s.id,
                  groupValue: order.scooterId,
                  activeColor: VoltronColors.electricYellow,
                  title: Text(
                    '${s.brand} ${s.model}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    'N° ${s.serialNumber}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onChanged: (value) {
                    ref
                        .read(repairOrderDetailActionsProvider)
                        .linkScooter(order.dbId, value);
                    Navigator.of(dialogContext).pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

class _ClientCard extends ConsumerWidget {
  final RepairOrder order;

  const _ClientCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientByIdProvider(order.clientId)).valueOrNull;
    final notes =
        ref.watch(clientInternalNotesProvider(order.clientId)).valueOrNull ??
        '';
    final plan = ref
        .watch(clientSubscriptionProvider(order.clientId))
        .valueOrNull;

    return _cardWrapper(
      'CLIENT',
      Icons.person_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  client?.fullName ?? '…',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (plan != null) ...[
                const SizedBox(width: 6),
                CareBadge(plan: plan),
              ],
            ],
          ),
          if ((client?.phone ?? '').isNotEmpty)
            Text(client!.phone, style: const TextStyle(fontSize: 11)),
          if ((client?.email ?? '').isNotEmpty)
            Text(
              client!.email,
              style: const TextStyle(
                color: VoltronColors.greyText,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            ...notes
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .map(
                  (line) => Text(
                    line.trim(),
                    style: const TextStyle(
                      color: VoltronColors.electricYellow,
                      fontSize: 11,
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                context.push('/admin/clients?clientId=${order.clientId}'),
            child: const Text(
              'Voir historique client',
              style: TextStyle(
                color: VoltronColors.electricBlueGlow,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _editClientNotes(context, ref, order.clientId, notes),
            child: const Text(
              'Modifier la note interne',
              style: TextStyle(
                color: VoltronColors.electricBlueGlow,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _editClientNotes(
  BuildContext context,
  WidgetRef ref,
  String clientId,
  String currentNotes,
) {
  final controller = TextEditingController(text: currentNotes);
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: VoltronColors.cardBlack,
      title: const Text('Note interne client'),
      content: SizedBox(
        width: 340,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Ex : Client fidèle, préfère être appelé...',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            ref
                .read(adminCrmActionsProvider)
                .updateInternalNotes(clientId, controller.text.trim());
            Navigator.of(dialogContext).pop();
          },
          child: const Text('ENREGISTRER'),
        ),
      ],
    ),
  );
}

class _DropoffCard extends ConsumerStatefulWidget {
  final RepairOrder order;

  const _DropoffCard({required this.order});

  @override
  ConsumerState<_DropoffCard> createState() => _DropoffCardState();
}

class _DropoffCardState extends ConsumerState<_DropoffCard> {
  bool _uploadingReport = false;

  Future<void> _editDropoffInfo() async {
    final order = widget.order;
    final dropoffDateController = TextEditingController(
      text: order.dropoffDate ?? '',
    );
    final appointmentDayController = TextEditingController(
      text: order.appointmentDay ?? '',
    );
    final appointmentTimeController = TextEditingController(
      text: order.appointmentTime ?? '',
    );
    final conditionController = TextEditingController(
      text: order.arrivalCondition,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: const Text('Informations de dépôt'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dropoffDateController,
                decoration: const InputDecoration(hintText: 'Date de dépôt'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: appointmentDayController,
                decoration: const InputDecoration(
                  hintText: 'Jour du rendez-vous',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: appointmentTimeController,
                decoration: const InputDecoration(
                  hintText: 'Heure du rendez-vous',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conditionController,
                decoration: const InputDecoration(
                  hintText: 'État à l\'arrivée (ex : Bon état, À compléter...)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );
    if (result != true) return;

    final actions = ref.read(repairOrderDetailActionsProvider);
    await actions.updateDropoffAndAppointment(
      order.dbId,
      dropoffDate: dropoffDateController.text.trim().isEmpty
          ? null
          : dropoffDateController.text.trim(),
      appointmentDay: appointmentDayController.text.trim().isEmpty
          ? null
          : appointmentDayController.text.trim(),
      appointmentTime: appointmentTimeController.text.trim().isEmpty
          ? null
          : appointmentTimeController.text.trim(),
    );
    await actions.updateArrivalCondition(
      order.dbId,
      conditionController.text.trim().isEmpty
          ? 'À compléter'
          : conditionController.text.trim(),
    );
  }

  Future<void> _openOrUploadReport() async {
    final url = widget.order.dropoffReportUrl;
    if (url != null) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }
    final result = await FilePicker.platform.pickFiles(withData: true);
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return;
    setState(() => _uploadingReport = true);
    try {
      await ref
          .read(repairOrderDetailActionsProvider)
          .uploadDropoffReport(widget.order.dbId, file!.bytes!, file.name);
    } finally {
      if (mounted) setState(() => _uploadingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isPending = order.arrivalCondition.trim() == 'À compléter';
    return _cardWrapper(
      'DÉPÔT',
      Icons.inventory_2_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.dropoffDate != null)
            Text(order.dropoffDate!, style: const TextStyle(fontSize: 11)),
          if (order.appointmentDay != null)
            Text(
              '${order.appointmentDay} à ${order.appointmentTime ?? ''}',
              style: const TextStyle(fontSize: 11),
            ),
          if (order.dropoffDate == null && order.appointmentDay == null)
            const Text(
              'Aucune information',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 11),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (isPending
                              ? VoltronColors.warning
                              : VoltronColors.success)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(VoltronRadii.pill),
                ),
                child: Text(
                  order.arrivalCondition,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPending
                        ? VoltronColors.warning
                        : VoltronColors.success,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _editDropoffInfo,
                child: const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: VoltronColors.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _uploadingReport ? null : _openOrUploadReport,
            child: _uploadingReport
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VoltronColors.electricYellow,
                    ),
                  )
                : Text(
                    order.dropoffReportUrl != null
                        ? 'Voir le PV dépôt'
                        : 'Ajouter le PV dépôt',
                    style: const TextStyle(
                      color: VoltronColors.electricBlueGlow,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianCard extends ConsumerWidget {
  final RepairOrder order;

  const _TechnicianCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final technicians = ref.watch(techniciansProvider).valueOrNull ?? [];
    Technician? technician;
    for (final t in technicians) {
      if (t.id == order.technicianId) {
        technician = t;
        break;
      }
    }

    return _cardWrapper(
      'TECHNICIEN ASSIGNÉ',
      Icons.engineering_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (technician == null)
            const Text(
              'Aucun technicien',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
            )
          else ...[
            Text(
              technician.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              technician.statusLabel,
              style: TextStyle(
                fontSize: 11,
                color: technician.status == TechnicianStatus.enLigne
                    ? VoltronColors.success
                    : VoltronColors.greyText,
              ),
            ),
          ],
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                _showAssignTechnicianDialog(context, ref, order, technicians),
            child: const Text(
              'Changer de technicien',
              style: TextStyle(
                color: VoltronColors.electricBlueGlow,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showAssignTechnicianDialog(
  BuildContext context,
  WidgetRef ref,
  RepairOrder order,
  List<Technician> technicians,
) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: VoltronColors.cardBlack,
      title: const Text('Assigner un technicien'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              value: null,
              groupValue: order.technicianId,
              activeColor: VoltronColors.electricYellow,
              title: const Text('Aucun', style: TextStyle(fontSize: 13)),
              onChanged: (value) {
                ref
                    .read(repairOrderDetailActionsProvider)
                    .assignTechnician(order.dbId, value);
                Navigator.of(dialogContext).pop();
              },
            ),
            ...technicians.map(
              (t) => RadioListTile<String?>(
                value: t.id,
                groupValue: order.technicianId,
                activeColor: VoltronColors.electricYellow,
                title: Text(t.name, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  t.statusLabel,
                  style: const TextStyle(fontSize: 11),
                ),
                onChanged: (value) {
                  ref
                      .read(repairOrderDetailActionsProvider)
                      .assignTechnician(order.dbId, value);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

/// Checklist rapide, fixe et ordonnée, cochée à la prise en charge du
/// véhicule (freins, accélération, état général, serrage, LED, pression des
/// pneus) — reste visible du client une fois cochée, quelle que soit l'étape
/// atteinte ensuite (contrairement à la checklist de l'étape en cours).
class _DropoffChecklistCard extends ConsumerStatefulWidget {
  final RepairOrder order;

  const _DropoffChecklistCard({required this.order});

  @override
  ConsumerState<_DropoffChecklistCard> createState() =>
      _DropoffChecklistCardState();
}

class _DropoffChecklistCardState extends ConsumerState<_DropoffChecklistCard> {
  bool _seedTriggered = false;

  @override
  Widget build(BuildContext context) {
    final checksAsync = ref.watch(dropoffChecksProvider(widget.order.dbId));
    final checks = checksAsync.valueOrNull ?? [];

    // Dossiers créés avant cette fonctionnalité : on sème la checklist une
    // fois, à la première consultation.
    if (checksAsync.hasValue && checks.isEmpty && !_seedTriggered) {
      _seedTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(repairOrderDetailActionsProvider)
            .ensureDropoffChecks(widget.order.dbId);
      });
    }

    final note = widget.order.dropoffClientNote ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 14,
                color: VoltronColors.electricYellow,
              ),
              SizedBox(width: 6),
              Text(
                'VÉRIFICATION AU DÉPÔT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: VoltronColors.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...checks.map(
            (check) => InkWell(
              onTap: () => ref
                  .read(repairOrderDetailActionsProvider)
                  .toggleDropoffCheck(check.id, !check.done),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      check.done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: check.done
                          ? VoltronColors.success
                          : VoltronColors.greyText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        check.label,
                        style: TextStyle(
                          fontSize: 13,
                          decoration: check.done
                              ? TextDecoration.lineThrough
                              : null,
                          color: check.done
                              ? VoltronColors.greyText
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (note.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                note,
                style: const TextStyle(
                  color: VoltronColors.electricBlueGlow,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          TextButton.icon(
            onPressed: () => _editDropoffClientNote(context, ref, widget.order),
            icon: const Icon(Icons.edit_note_rounded, size: 16),
            label: Text(
              note.trim().isEmpty
                  ? 'Ajouter une note visible par le client'
                  : 'Modifier la note client',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

void _editDropoffClientNote(
  BuildContext context,
  WidgetRef ref,
  RepairOrder order,
) {
  final controller = TextEditingController(text: order.dropoffClientNote ?? '');
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: VoltronColors.cardBlack,
      title: const Text('Note visible par le client'),
      content: SizedBox(
        width: 340,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'Ex : Trottinette en bon état général, pneu avant un peu usé...',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            ref
                .read(repairOrderDetailActionsProvider)
                .updateDropoffClientNote(order.dbId, controller.text.trim());
            Navigator.of(dialogContext).pop();
          },
          child: const Text('ENREGISTRER'),
        ),
      ],
    ),
  );
}

class _CurrentStepChecklist extends ConsumerStatefulWidget {
  final RepairOrder order;

  const _CurrentStepChecklist({required this.order});

  @override
  ConsumerState<_CurrentStepChecklist> createState() =>
      _CurrentStepChecklistState();
}

class _CurrentStepChecklistState extends ConsumerState<_CurrentStepChecklist> {
  String? _seededForStepId;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final tasksAsync = ref.watch(stepTasksProvider(order.dbId));
    final tasks = tasksAsync.valueOrNull ?? [];
    final photos =
        ref.watch(repairOrderPhotosProvider(order.dbId)).valueOrNull ?? [];
    final currentStepId = order.currentStep.id;
    final currentTasks = tasks.where((t) => t.stepId == currentStepId).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    // Étapes créées avant qu'un modèle de checklist n'existe pour elles (ex.
    // "Diagnostic en cours" avant son ajout) : on sème une fois par étape.
    if (tasksAsync.hasValue &&
        currentTasks.isEmpty &&
        _seededForStepId != currentStepId) {
      _seededForStepId = currentStepId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(repairOrderDetailActionsProvider)
            .ensureStepTasks(
              order.dbId,
              currentStepId,
              order.currentStep.label,
            );
      });
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÉTAPE ACTUELLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: VoltronColors.greyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.currentStep.label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (currentTasks.isEmpty)
            const Text(
              'Aucune tâche pour cette étape.',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
            )
          else
            ...currentTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChecklistItem(
                  order: order,
                  task: task,
                  photoCount: photos
                      .where((p) => p.stepTaskId == task.id)
                      .length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends ConsumerStatefulWidget {
  final RepairOrder order;
  final RepairStepTask task;
  final int photoCount;

  const _ChecklistItem({
    required this.order,
    required this.task,
    required this.photoCount,
  });

  @override
  ConsumerState<_ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends ConsumerState<_ChecklistItem> {
  bool _uploading = false;

  Future<void> _editValue() async {
    final controller = TextEditingController(text: widget.task.valueText ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: Text(widget.task.label),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: widget.task.label.toLowerCase().contains('kilométrage')
              ? TextInputType.number
              : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref
        .read(repairOrderDetailActionsProvider)
        .updateStepTaskValue(widget.task.id, result);
    if (widget.order.scooterId != null &&
        widget.task.label.toLowerCase().contains('kilométrage')) {
      final km = int.tryParse(result);
      if (km != null) {
        await ref
            .read(adminCrmActionsProvider)
            .updateScooter(widget.order.scooterId!, mileageKm: km);
      }
    }
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: widget.task.valueText ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: Text(widget.task.label),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref
        .read(repairOrderDetailActionsProvider)
        .updateStepTaskValue(widget.task.id, result);
  }

  Future<void> _pickAccessories() async {
    final selected = {...widget.task.selectedOptions};
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: VoltronColors.cardBlack,
          title: const Text('Accessoires fournis'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: commonAccessories
                  .map(
                    (a) => CheckboxListTile(
                      value: selected.contains(a),
                      title: Text(a, style: const TextStyle(fontSize: 13)),
                      activeColor: VoltronColors.electricYellow,
                      checkColor: VoltronColors.deepBlack,
                      onChanged: (checked) => setDialogState(() {
                        if (checked == true) {
                          selected.add(a);
                        } else {
                          selected.remove(a);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(selected.toList()),
              child: const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    await ref
        .read(repairOrderDetailActionsProvider)
        .updateStepTaskSelectedOptions(widget.task.id, result);
  }

  Future<void> _addPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return;
    setState(() => _uploading = true);
    try {
      await ref
          .read(repairOrderDetailActionsProvider)
          .uploadStepPhoto(
            widget.order.dbId,
            widget.task.id,
            file!.bytes!,
            file.name,
          );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    switch (task.kind) {
      case RepairStepTaskKind.check:
        return InkWell(
          onTap: () => ref
              .read(repairOrderDetailActionsProvider)
              .updateStepTaskCheck(task.id, !task.done),
          child: Row(
            children: [
              Icon(
                task.done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: task.done
                    ? VoltronColors.success
                    : VoltronColors.greyText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.label,
                  style: TextStyle(
                    fontSize: 13,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                    color: task.done ? VoltronColors.greyText : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );

      case RepairStepTaskKind.value:
        return Row(
          children: [
            Icon(
              task.done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: task.done ? VoltronColors.success : VoltronColors.greyText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                (task.valueText ?? '').isEmpty
                    ? task.label
                    : '${task.label} : ${task.valueText}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            IconButton(
              onPressed: _editValue,
              icon: const Icon(Icons.edit_outlined, size: 16),
            ),
          ],
        );

      case RepairStepTaskKind.counter:
        return Row(
          children: [
            Icon(
              widget.photoCount >= task.counterTarget && task.counterTarget > 0
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color:
                  widget.photoCount >= task.counterTarget &&
                      task.counterTarget > 0
                  ? VoltronColors.success
                  : VoltronColors.greyText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${task.label} (${widget.photoCount}/${task.counterTarget})',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VoltronColors.electricYellow,
                    ),
                  )
                : IconButton(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  ),
          ],
        );

      case RepairStepTaskKind.select:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: task.done
                      ? VoltronColors.success
                      : VoltronColors.greyText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(task.label, style: const TextStyle(fontSize: 13)),
                ),
                TextButton(
                  onPressed: _pickAccessories,
                  child: const Text(
                    'Sélectionner',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if (task.selectedOptions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: task.selectedOptions
                      .map(
                        (o) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: VoltronColors.deepBlack,
                            borderRadius: BorderRadius.circular(
                              VoltronRadii.pill,
                            ),
                          ),
                          child: Text(o, style: const TextStyle(fontSize: 11)),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        );

      case RepairStepTaskKind.note:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sticky_note_2_outlined,
                  size: 20,
                  color: VoltronColors.greyText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(task.label, style: const TextStyle(fontSize: 13)),
                ),
                TextButton(
                  onPressed: _editNote,
                  child: Text(
                    (task.valueText ?? '').isEmpty
                        ? 'Ajouter une note'
                        : 'Modifier',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            if ((task.valueText ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 2),
                child: Text(
                  task.valueText!,
                  style: const TextStyle(
                    color: VoltronColors.electricBlueGlow,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
    }
  }
}

class _BottomActionBar extends ConsumerWidget {
  final RepairOrder order;

  const _BottomActionBar({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents =
        ref.watch(repairOrderDocumentsProvider(order.dbId)).valueOrNull ?? [];
    final parts =
        ref.watch(repairOrderPartsProvider(order.dbId)).valueOrNull ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: const BoxDecoration(
        color: VoltronColors.cardBlack,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          _bottomBarItem(
            context,
            Icons.description_outlined,
            'Documents',
            documents.length,
            () => _showDocumentsSheet(context, ref, order),
          ),
          _bottomBarItem(
            context,
            Icons.settings_suggest_outlined,
            'Pièces',
            parts.length,
            () => _showPartsSheet(context, ref, order),
          ),
          _bottomBarItem(
            context,
            Icons.chat_bubble_outline_rounded,
            'Messages',
            null,
            () => context.push('/admin/repairs/${order.dbId}/messages'),
          ),
          _bottomBarItem(
            context,
            Icons.history_rounded,
            'Historique',
            null,
            () => _showHistorySheet(context, ref, order),
          ),
        ],
      ),
    );
  }

  Widget _bottomBarItem(
    BuildContext context,
    IconData icon,
    String label,
    int? count,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: VoltronColors.greyText),
              const SizedBox(height: 2),
              Text(
                count != null ? '$label ($count)' : label,
                style: const TextStyle(
                  color: VoltronColors.greyText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showDocumentsSheet(
  BuildContext context,
  WidgetRef ref,
  RepairOrder order,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: VoltronColors.cardBlack,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, ref, _) {
        final documents =
            ref.watch(repairOrderDocumentsProvider(order.dbId)).valueOrNull ??
            [];
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DOCUMENTS',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        withData: true,
                      );
                      final file = result?.files.firstOrNull;
                      if (file?.bytes == null) return;
                      await ref
                          .read(repairOrderDetailActionsProvider)
                          .addDocument(
                            order.dbId,
                            file!.name,
                            file.bytes!,
                            file.name,
                          );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (documents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Aucun document.',
                    style: TextStyle(color: VoltronColors.greyText),
                  ),
                )
              else
                ...documents.map(
                  (doc) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.insert_drive_file_outlined,
                      color: VoltronColors.electricYellow,
                    ),
                    title: Text(
                      doc.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () => launchUrl(
                      Uri.parse(doc.url),
                      mode: LaunchMode.externalApplication,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Color(0xFFFF5C5C),
                      ),
                      onPressed: () => ref
                          .read(repairOrderDetailActionsProvider)
                          .removeDocument(doc.id),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

void _showPartsSheet(BuildContext context, WidgetRef ref, RepairOrder order) {
  showModalBottomSheet(
    context: context,
    backgroundColor: VoltronColors.cardBlack,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, ref, _) {
        final parts =
            ref.watch(repairOrderPartsProvider(order.dbId)).valueOrNull ?? [];
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PIÈCES',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddPartDialog(context, ref, order),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (parts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Aucune pièce.',
                    style: TextStyle(color: VoltronColors.greyText),
                  ),
                )
              else
                ...parts.map(
                  (part) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${part.label} ×${part.quantity}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      part.statusLabel,
                      style: const TextStyle(
                        color: VoltronColors.electricYellow,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<PartStatus>(
                          color: VoltronColors.cardBlack,
                          icon: const Icon(Icons.more_vert_rounded, size: 18),
                          onSelected: (status) => ref
                              .read(repairOrderDetailActionsProvider)
                              .updatePartStatus(part.id, order.dbId, status),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: PartStatus.pending,
                              child: Text('À commander'),
                            ),
                            PopupMenuItem(
                              value: PartStatus.ordered,
                              child: Text('Commandée'),
                            ),
                            PopupMenuItem(
                              value: PartStatus.received,
                              child: Text('Reçue'),
                            ),
                            PopupMenuItem(
                              value: PartStatus.installed,
                              child: Text('Installée'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFFF5C5C),
                          ),
                          onPressed: () => ref
                              .read(repairOrderDetailActionsProvider)
                              .removePart(part.id),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

void _showAddPartDialog(
  BuildContext context,
  WidgetRef ref,
  RepairOrder order,
) {
  final labelController = TextEditingController();
  final refController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final priceController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: VoltronColors.cardBlack,
      title: const Text('Nouvelle pièce'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(hintText: 'Nom de la pièce'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: refController,
              decoration: const InputDecoration(
                hintText: 'Référence (optionnel)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Quantité'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Prix €'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final label = labelController.text.trim();
            if (label.isEmpty) return;
            ref
                .read(repairOrderDetailActionsProvider)
                .addPart(
                  order.dbId,
                  label: label,
                  reference: refController.text.trim().isEmpty
                      ? null
                      : refController.text.trim(),
                  quantity: int.tryParse(quantityController.text) ?? 1,
                  price:
                      double.tryParse(
                        priceController.text.replaceAll(',', '.'),
                      ) ??
                      0,
                );
            Navigator.of(dialogContext).pop();
          },
          child: const Text('AJOUTER'),
        ),
      ],
    ),
  );
}

void _showHistorySheet(BuildContext context, WidgetRef ref, RepairOrder order) {
  showModalBottomSheet(
    context: context,
    backgroundColor: VoltronColors.cardBlack,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, ref, _) {
        final events =
            ref.watch(repairOrderEventsProvider(order.dbId)).valueOrNull ?? [];
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HISTORIQUE',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Aucune action pour le moment.',
                    style: TextStyle(color: VoltronColors.greyText),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              event.actorRole == 'client'
                                  ? Icons.person_rounded
                                  : Icons.build_circle_outlined,
                              size: 18,
                              color: VoltronColors.electricYellow,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.description,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    '${event.createdAt.toLocal().day.toString().padLeft(2, '0')}/${event.createdAt.toLocal().month.toString().padLeft(2, '0')} à ${event.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${event.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      color: VoltronColors.greyText,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
