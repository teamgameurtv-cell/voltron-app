import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/repair.dart';
import '../../providers/auth_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';

class RepairsScreen extends ConsumerWidget {
  const RepairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    final orders = ref.watch(repairsProvider).where((o) => o.clientId == userId).toList();

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('RÉPARATIONS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ElevatedButton(
                  onPressed: () => context.push('/repairs/book'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: const Text('RÉSERVER', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (orders.isEmpty)
              const Text('Aucun dossier en cours.', style: TextStyle(color: VoltronColors.greyText))
            else
              ...orders.map((order) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VoltronColors.cardBlack,
                        borderRadius: BorderRadius.circular(VoltronRadii.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dossier #${order.id}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(order.scooterName,
                              style: const TextStyle(color: VoltronColors.greyText, fontSize: 13)),
                          const SizedBox(height: 16),
                          ...order.steps.map((step) => _TimelineTile(step: step)),
                          const SizedBox(height: 8),
                          if (order.quote != null)
                            ElevatedButton(
                              onPressed: () => context.push('/repairs/quote/${order.dbId}'),
                              child: const Text('VOIR LE DEVIS'),
                            ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final RepairStep step;

  const _TimelineTile({required this.step});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (step.status) {
      case RepairStepStatus.done:
        color = VoltronColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case RepairStepStatus.current:
        color = VoltronColors.warning;
        icon = Icons.radio_button_checked_rounded;
        break;
      case RepairStepStatus.pending:
        color = VoltronColors.greyText;
        icon = Icons.radio_button_unchecked_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: step.status == RepairStepStatus.pending ? VoltronColors.greyText : Colors.white,
                  ),
                ),
                if (step.date != null)
                  Text(step.date!,
                      style: const TextStyle(color: VoltronColors.greyText, fontSize: 11))
                else
                  const Text('En attente',
                      style: TextStyle(color: VoltronColors.greyText, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
