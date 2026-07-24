import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repair.dart';
import '../providers/admin_crm_provider.dart';
import '../providers/repairs_provider.dart';
import '../theme/voltron_theme.dart';

/// Ligne compacte d'un dossier dans la liste "Réparations" : client, véhicule
/// et étape en cours en un coup d'œil — le détail complet (frise, devis,
/// checklist, historique...) vit dans l'écran dédié ouvert au tap
/// (voir admin_repair_order_screen.dart), donc pas d'action ici.
class RepairOrderCard extends ConsumerWidget {
  final RepairOrder order;

  const RepairOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientByIdProvider(order.clientId)).valueOrNull;
    final isComplete = order.isComplete;
    final isRefused = order.quote?.status == QuoteStatus.refused;
    final badgeColor = isComplete
        ? VoltronColors.success
        : isRefused
        ? const Color(0xFFFF5C5C)
        : order.isBlockedOnQuote
        ? VoltronColors.warning
        : VoltronColors.electricBlueGlow;
    final badgeLabel = isComplete
        ? 'Terminée'
        : isRefused
        ? 'Devis refusé'
        : order.currentStep.label;
    final subtitle = [
      client?.fullName,
      order.scooterName,
    ].where((s) => (s ?? '').trim().isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: VoltronColors.deepBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.sm),
            ),
            child: const Icon(
              Icons.electric_scooter_rounded,
              color: VoltronColors.electricYellow,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dossier #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: VoltronColors.greyText,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(VoltronRadii.pill),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: VoltronColors.greyText,
            size: 20,
          ),
        ],
      ),
    );
  }
}

void showQuoteDialog(
  BuildContext context,
  WidgetRef ref,
  RepairOrder order, {
  Quote? existing,
}) {
  final delayController = TextEditingController(
    text: existing?.estimatedDelay ?? '',
  );
  final lines = <(TextEditingController, TextEditingController)>[
    if (existing != null && existing.lines.isNotEmpty)
      for (final l in existing.lines)
        (
          TextEditingController(text: l.label),
          TextEditingController(text: l.price.toStringAsFixed(2)),
        )
    else
      (TextEditingController(), TextEditingController()),
  ];
  final noteController = TextEditingController(text: existing?.note ?? '');
  final depositController = TextEditingController(
    text: existing?.depositAmount != null && existing!.depositAmount! > 0
        ? existing.depositAmount!.toStringAsFixed(2)
        : '',
  );
  String? fileUrl = existing?.fileUrl;
  bool isUploading = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: Text(existing == null ? 'Nouveau devis' : 'Modifier le devis'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: delayController,
                  decoration: const InputDecoration(
                    hintText: 'Délai estimé (ex : 3-5 jours)',
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'LIGNES DU DEVIS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: VoltronColors.greyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...lines.asMap().entries.map((entry) {
                  final (labelCtrl, priceCtrl) = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: labelCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Intitulé',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Prix €',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setDialogState(() => lines.removeAt(entry.key)),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: VoltronColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setDialogState(
                    () => lines.add((
                      TextEditingController(),
                      TextEditingController(),
                    )),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter une ligne'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'EXPLICATION (visible par le client)',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: VoltronColors.greyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Ex : la batterie est défaillante et doit être remplacée...',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ACOMPTE (facultatif)',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: VoltronColors.greyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: depositController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Montant en € à demander avant intervention',
                    prefixIcon: Icon(Icons.euro_rounded, size: 16),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'PIÈCE JOINTE (facultatif)',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: VoltronColors.greyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              final result = await FilePicker.platform
                                  .pickFiles(withData: true);
                              final file = result?.files.firstOrNull;
                              if (file?.bytes == null) return;
                              setDialogState(() => isUploading = true);
                              try {
                                final url = await ref
                                    .read(repairsProvider.notifier)
                                    .uploadQuoteFile(file!.bytes!, file.name);
                                setDialogState(() {
                                  fileUrl = url;
                                  isUploading = false;
                                });
                              } catch (e) {
                                setDialogState(() => isUploading = false);
                                if (!dialogContext.mounted) return;
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text('Échec de l\'envoi : $e'),
                                  ),
                                );
                              }
                            },
                      icon: isUploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: VoltronColors.electricYellow,
                              ),
                            )
                          : const Icon(Icons.attach_file, size: 16),
                      label: Text(
                        isUploading
                            ? 'Envoi...'
                            : (fileUrl != null
                                  ? 'Remplacer le fichier'
                                  : 'Joindre un fichier'),
                      ),
                    ),
                    if (fileUrl != null) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.check_circle,
                        color: VoltronColors.success,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: isUploading
                ? null
                : () {
                    final quoteLines = lines
                        .where((l) => l.$1.text.trim().isNotEmpty)
                        .map(
                          (l) => QuoteLine(
                            l.$1.text.trim(),
                            double.tryParse(l.$2.text.replaceAll(',', '.')) ??
                                0,
                          ),
                        )
                        .toList();
                    final depositAmount = double.tryParse(
                      depositController.text.trim().replaceAll(',', '.'),
                    );
                    if (existing == null) {
                      ref
                          .read(repairsProvider.notifier)
                          .createQuote(
                            order.dbId,
                            lines: quoteLines,
                            estimatedDelay: delayController.text.trim(),
                            fileUrl: fileUrl,
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                            depositAmount: depositAmount,
                          );
                    } else {
                      ref
                          .read(repairsProvider.notifier)
                          .updateQuote(
                            existing.dbId,
                            lines: quoteLines,
                            estimatedDelay: delayController.text.trim(),
                            fileUrl: fileUrl,
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                            depositAmount: depositAmount,
                          );
                    }
                    Navigator.of(dialogContext).pop();
                  },
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    ),
  );
}
