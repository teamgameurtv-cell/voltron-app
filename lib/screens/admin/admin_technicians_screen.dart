import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/technician.dart';
import '../../providers/technicians_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

/// Annuaire simple des techniciens : pas de compte de connexion, juste un nom,
/// une photo et un statut, assignables à un dossier de réparation.
class AdminTechniciansScreen extends ConsumerWidget {
  const AdminTechniciansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techniciansAsync = ref.watch(techniciansProvider);

    return AdminShell(
      selected: AdminSection.technicians,
      title: 'TECHNICIENS',
      actions: ElevatedButton.icon(
        onPressed: () => _showTechnicianDialog(context, ref),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('AJOUTER'),
      ),
      child: techniciansAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: VoltronColors.electricYellow),
        ),
        error: (err, _) => Text(
          'Erreur : $err',
          style: const TextStyle(color: VoltronColors.greyText),
        ),
        data: (technicians) => technicians.isEmpty
            ? const Center(
                child: Text(
                  'Aucun technicien pour le moment.',
                  style: TextStyle(color: VoltronColors.greyText),
                ),
              )
            : ListView.separated(
                itemCount: technicians.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final tech = technicians[index];
                  final statusColor = switch (tech.status) {
                    TechnicianStatus.enLigne => VoltronColors.success,
                    TechnicianStatus.absent => VoltronColors.warning,
                    TechnicianStatus.horsLigne => VoltronColors.greyText,
                  };
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VoltronColors.cardBlack,
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: VoltronColors.deepBlack,
                              backgroundImage:
                                  (tech.avatarUrl != null &&
                                      tech.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(tech.avatarUrl!)
                                  : null,
                              child:
                                  (tech.avatarUrl == null ||
                                      tech.avatarUrl!.isEmpty)
                                  ? const Icon(
                                      Icons.engineering_rounded,
                                      color: VoltronColors.electricYellow,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: VoltronColors.cardBlack,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tech.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                tech.statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showTechnicianDialog(
                            context,
                            ref,
                            existing: tech,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          onPressed: () => ref
                              .read(technicianActionsProvider)
                              .removeTechnician(tech.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFFF5C5C),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showTechnicianDialog(
    BuildContext context,
    WidgetRef ref, {
    Technician? existing,
  }) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    TechnicianStatus status = existing?.status ?? TechnicianStatus.horsLigne;
    String? avatarUrl = existing?.avatarUrl;
    PlatformFile? pickedFile;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: VoltronColors.cardBlack,
          title: Text(
            existing == null ? 'Nouveau technicien' : 'Modifier le technicien',
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      final file = result?.files.firstOrNull;
                      if (file?.bytes == null) return;
                      setDialogState(() => pickedFile = file);
                    },
                    child: Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: VoltronColors.deepBlack,
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(44),
                        child: pickedFile != null
                            ? Image.memory(
                                pickedFile!.bytes!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              )
                            : (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? Image.network(
                                avatarUrl,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.add_a_photo_outlined,
                                color: VoltronColors.greyText,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Nom complet'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TechnicianStatus>(
                    value: status,
                    dropdownColor: VoltronColors.cardBlack,
                    items: const [
                      DropdownMenuItem(
                        value: TechnicianStatus.enLigne,
                        child: Text('En ligne'),
                      ),
                      DropdownMenuItem(
                        value: TechnicianStatus.horsLigne,
                        child: Text('Hors ligne'),
                      ),
                      DropdownMenuItem(
                        value: TechnicianStatus.absent,
                        child: Text('Absent'),
                      ),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => status = v ?? status),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => isSaving = true);
                      final actions = ref.read(technicianActionsProvider);
                      try {
                        String technicianId;
                        if (existing == null) {
                          technicianId = await actions.addTechnician(
                            name: name,
                            status: status,
                          );
                        } else {
                          technicianId = existing.id;
                          await actions.updateTechnician(
                            technicianId,
                            name: name,
                            status: status,
                          );
                        }
                        if (pickedFile != null) {
                          final ext = pickedFile!.name.split('.').last;
                          await actions.uploadAvatar(
                            technicianId,
                            pickedFile!.bytes!,
                            ext,
                          );
                        }
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VoltronColors.deepBlack,
                      ),
                    )
                  : const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }
}
