import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/repair.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';

class RepairsHistoryScreen extends ConsumerWidget {
  const RepairsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    final orders = ref.watch(repairsProvider).where((o) => o.clientId == userId).toList();

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        title: const Text('HISTORIQUE RÉPARATIONS'),
      ),
      body: SafeArea(
        child: orders.isEmpty
            ? const Center(child: Text('Aucun dossier.', style: TextStyle(color: VoltronColors.greyText)))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final isComplete = order.steps.last.status == RepairStepStatus.done;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VoltronColors.cardBlack,
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: VoltronColors.deepBlack,
                            borderRadius: BorderRadius.circular(VoltronRadii.sm),
                          ),
                          child: const Icon(Icons.build_rounded, color: VoltronColors.electricYellow, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dossier #${order.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(order.scooterName, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(
                          isComplete ? 'Terminée' : order.currentStep.label,
                          style: TextStyle(
                            color: isComplete ? VoltronColors.success : VoltronColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
}
