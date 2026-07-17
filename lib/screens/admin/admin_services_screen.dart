import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/repair.dart';
import '../../providers/repair_services_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

class AdminServicesScreen extends ConsumerWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(repairServicesProvider);

    return AdminShell(
      selected: AdminSection.services,
      title: 'SERVICES DE RÉPARATION',
      actions: ElevatedButton.icon(
        onPressed: () => _showServiceDialog(context, ref),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('AJOUTER'),
      ),
      child: services.isEmpty
          ? const Center(
              child: Text('Aucun service pour le moment.', style: TextStyle(color: VoltronColors.greyText)),
            )
          : ListView.separated(
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final service = services[index];
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
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: VoltronColors.deepBlack,
                          borderRadius: BorderRadius.circular(VoltronRadii.sm),
                        ),
                        child: (service.imageUrl != null && service.imageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(VoltronRadii.sm),
                                child: Image.network(service.imageUrl!, width: 48, height: 48, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.build_rounded, color: VoltronColors.electricYellow),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            if (service.duration.isNotEmpty)
                              Text(service.duration, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                            if ((service.description ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                service.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: VoltronColors.greyText, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(service.priceLabel,
                          style: const TextStyle(color: VoltronColors.electricYellow, fontWeight: FontWeight.w700, fontSize: 12)),
                      IconButton(
                        onPressed: () => _showServiceDialog(context, ref, existing: service),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                      IconButton(
                        onPressed: () => ref.read(repairServicesProvider.notifier).remove(service.id),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF5C5C)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showServiceDialog(BuildContext context, WidgetRef ref, {RepairService? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final durationController = TextEditingController(text: existing?.duration ?? '');
    final priceController = TextEditingController(text: existing?.priceLabel ?? '');
    final descriptionController = TextEditingController(text: existing?.description ?? '');
    String? imageUrl = existing?.imageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: VoltronColors.cardBlack,
          title: Text(existing == null ? 'Nouveau service' : 'Modifier le service'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: isUploading
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              withData: true,
                            );
                            final file = result?.files.firstOrNull;
                            if (file?.bytes == null) return;
                            setDialogState(() => isUploading = true);
                            try {
                              final url = await ref
                                  .read(repairServicesProvider.notifier)
                                  .uploadImage(file!.bytes!, file.name);
                              setDialogState(() {
                                imageUrl = url;
                                isUploading = false;
                              });
                            } catch (e) {
                              setDialogState(() => isUploading = false);
                              if (!dialogContext.mounted) return;
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Échec de l\'envoi de la photo : $e')),
                              );
                            }
                          },
                    child: Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: VoltronColors.deepBlack,
                        borderRadius: BorderRadius.circular(VoltronRadii.md),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: isUploading
                          ? const CircularProgressIndicator(color: VoltronColors.electricYellow)
                          : (imageUrl != null && imageUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                                  child: Image.network(imageUrl!, width: 96, height: 96, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.add_a_photo_outlined, color: VoltronColors.greyText),
                                    SizedBox(height: 6),
                                    Text('Ajouter une photo',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 10, color: VoltronColors.greyText)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Nom du service')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(hintText: 'Durée (ex : 45 min)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(hintText: 'Tarif (ex : 35 €, à partir de 35 €, Sur devis)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Description détaillée du service'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () {
                      if (existing == null) {
                        ref.read(repairServicesProvider.notifier).add(
                              name: nameController.text.trim().isEmpty ? 'Nouveau service' : nameController.text.trim(),
                              duration: durationController.text.trim(),
                              priceLabel: priceController.text.trim(),
                              description: descriptionController.text.trim(),
                              imageUrl: imageUrl,
                            );
                      } else {
                        ref.read(repairServicesProvider.notifier).update(existing.copyWith(
                              name: nameController.text.trim(),
                              duration: durationController.text.trim(),
                              priceLabel: priceController.text.trim(),
                              description: descriptionController.text.trim(),
                              imageUrl: imageUrl,
                            ));
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
}
