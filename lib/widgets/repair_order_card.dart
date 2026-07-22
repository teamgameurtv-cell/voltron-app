import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repair.dart';
import '../providers/repairs_provider.dart';
import '../theme/voltron_theme.dart';

/// Carte détaillée d'un dossier de réparation (statut, devis, notes d'étape),
/// utilisée à la fois dans la liste "Réparations" et dans le détail du kanban.
class RepairOrderCard extends ConsumerWidget {
  final RepairOrder order;

  const RepairOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isComplete = order.steps.last.status == RepairStepStatus.done;
    final atQuoteStep = order.currentStep.label == 'Diagnostic en cours';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Dossier #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (order.quote != null)
                TextButton.icon(
                  onPressed: () => showQuoteDialog(
                    context,
                    ref,
                    order,
                    existing: order.quote,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text(
                    'MODIFIER LE DEVIS',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              if (!isComplete && order.isBlockedOnQuote)
                ElevatedButton(
                  onPressed: () => ref
                      .read(repairsProvider.notifier)
                      .acceptQuote(order.dbId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VoltronColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'VALIDER LE DEVIS (client)',
                    style: TextStyle(fontSize: 11),
                  ),
                )
              else if (!isComplete && atQuoteStep)
                ElevatedButton(
                  onPressed: () => showQuoteDialog(context, ref, order),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'ENVOYER LE DEVIS',
                    style: TextStyle(fontSize: 11),
                  ),
                )
              else if (!isComplete)
                ElevatedButton(
                  onPressed: () => ref
                      .read(repairsProvider.notifier)
                      .advanceStep(order.dbId),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'ÉTAPE SUIVANTE',
                    style: TextStyle(fontSize: 11),
                  ),
                )
              else
                const Text(
                  'TERMINÉ',
                  style: TextStyle(
                    color: VoltronColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (!isComplete && order.isBlockedOnQuote)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'En attente de validation du devis par le client',
                style: TextStyle(color: VoltronColors.warning, fontSize: 11),
              ),
            ),
          Text(
            order.scooterName,
            style: const TextStyle(color: VoltronColors.greyText, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: order.steps.map((step) {
              Color color;
              switch (step.status) {
                case RepairStepStatus.done:
                  color = VoltronColors.success;
                  break;
                case RepairStepStatus.current:
                  color = VoltronColors.warning;
                  break;
                case RepairStepStatus.pending:
                  color = VoltronColors.greyText;
                  break;
              }
              final hasNote = (step.note ?? '').isNotEmpty;
              return GestureDetector(
                onTap: () => showStepNoteDialog(context, ref, step),
                child: Tooltip(
                  message: hasNote ? step.note! : 'Ajouter une note',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(VoltronRadii.pill),
                      border: hasNote ? Border.all(color: color) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasNote) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 12,
                            color: color,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Note d'étape (visible aussi depuis l'écran détail du dossier) — réutilisée
/// telle quelle plutôt que dupliquée.
void showStepNoteDialog(BuildContext context, WidgetRef ref, RepairStep step) {
  final controller = TextEditingController(text: step.note ?? '');
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: VoltronColors.cardBlack,
      title: Text('Note — ${step.label}'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Note interne ou visible par le client',
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
                .read(repairsProvider.notifier)
                .updateStepNote(
                  step.id,
                  controller.text.trim().isEmpty
                      ? null
                      : controller.text.trim(),
                );
            Navigator.of(dialogContext).pop();
          },
          child: const Text('ENREGISTRER'),
        ),
      ],
    ),
  );
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
                    if (existing == null) {
                      ref
                          .read(repairsProvider.notifier)
                          .createQuote(
                            order.dbId,
                            lines: quoteLines,
                            estimatedDelay: delayController.text.trim(),
                            fileUrl: fileUrl,
                          );
                    } else {
                      ref
                          .read(repairsProvider.notifier)
                          .updateQuote(
                            existing.dbId,
                            lines: quoteLines,
                            estimatedDelay: delayController.text.trim(),
                            fileUrl: fileUrl,
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
