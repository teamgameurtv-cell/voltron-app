import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/repair.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

class AdminRepairsScreen extends ConsumerWidget {
  const AdminRepairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repairs = ref.watch(repairsProvider);

    return AdminShell(
      selected: AdminSection.repairs,
      title: 'RÉPARATIONS',
      child: ListView.separated(
        itemCount: repairs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final order = repairs[index];
          final isComplete = order.steps.last.status == RepairStepStatus.done;

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
                    Text('Dossier #${order.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (!isComplete && order.isBlockedOnQuote)
                      ElevatedButton(
                        onPressed: () => ref.read(repairsProvider.notifier).acceptQuote(order.dbId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VoltronColors.electricBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('VALIDER LE DEVIS (client)', style: TextStyle(fontSize: 11)),
                      )
                    else if (!isComplete)
                      ElevatedButton(
                        onPressed: () => ref.read(repairsProvider.notifier).advanceStep(order.dbId),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                        child: const Text('ÉTAPE SUIVANTE', style: TextStyle(fontSize: 11)),
                      )
                    else
                      const Text('TERMINÉ', style: TextStyle(color: VoltronColors.success, fontWeight: FontWeight.w700)),
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
                Text(order.scooterName, style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
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
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(VoltronRadii.pill),
                      ),
                      child: Text(step.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
