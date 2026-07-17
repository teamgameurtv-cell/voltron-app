import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/garage_provider.dart';
import '../../theme/voltron_theme.dart';

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scooters = ref.watch(garageProvider);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('MON GARAGE'),
        actions: [
          IconButton(
            onPressed: () => _showAddDialog(context, ref),
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: VoltronColors.electricYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: VoltronColors.deepBlack, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: scooters.isEmpty
            ? const Center(
                child: Text('Aucune trottinette enregistrée.', style: TextStyle(color: VoltronColors.greyText)),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: scooters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final scooter = scooters[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VoltronColors.cardBlack,
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: VoltronColors.deepBlack,
                                borderRadius: BorderRadius.circular(VoltronRadii.sm),
                              ),
                              child: const Icon(Icons.electric_scooter_rounded, color: VoltronColors.electricYellow),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${scooter.brand} ${scooter.model}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('N° de série : ${scooter.serialNumber}',
                                      style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                                  Text('Achetée le ${scooter.formattedPurchaseDate}',
                                      style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref.read(garageProvider.notifier).removeScooter(scooter.id),
                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF5C5C)),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        _ReminderRow(
                          icon: Icons.build_circle_outlined,
                          text: 'Prochaine révision conseillée : ${scooter.formattedNextRevisionDate}',
                        ),
                        const SizedBox(height: 8),
                        const _ReminderRow(
                          icon: Icons.tire_repair,
                          text: 'Contrôle pression des pneus chaque semaine',
                          badge: 'GRATUIT',
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final serialController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: const Text('Ajouter une trottinette'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: brandController, decoration: const InputDecoration(hintText: 'Marque')),
              const SizedBox(height: 12),
              TextField(controller: modelController, decoration: const InputDecoration(hintText: 'Modèle')),
              const SizedBox(height: 12),
              TextField(controller: serialController, decoration: const InputDecoration(hintText: 'Numéro de série')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(garageProvider.notifier).addScooter(
                    brand: brandController.text.trim().isEmpty ? 'Trottinette' : brandController.text.trim(),
                    model: modelController.text.trim(),
                    serialNumber: serialController.text.trim().isEmpty ? '-' : serialController.text.trim(),
                  );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trottinette ajoutée à ton garage')),
              );
            },
            child: const Text('AJOUTER'),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? badge;

  const _ReminderRow({required this.icon, required this.text, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: VoltronColors.electricBlueGlow),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white70))),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: VoltronColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(VoltronRadii.pill),
            ),
            child: Text(badge!, style: const TextStyle(color: VoltronColors.success, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }
}
