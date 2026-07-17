import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

const List<String> _columns = [
  'Rendez-vous pris',
  'Trottinette déposée',
  'Diagnostic en cours',
  'Devis envoyé',
  'Pièces commandées',
  'Réparation en cours',
  'Prête à récupérer',
  'Récupérée',
];

class AdminRepairsBoardScreen extends ConsumerWidget {
  const AdminRepairsBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(repairsProvider);

    return AdminShell(
      selected: AdminSection.repairsBoard,
      title: 'SUIVI RÉPARATIONS',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _columns.map((columnLabel) {
            final columnOrders = orders.where((o) => o.currentStep.label == columnLabel).toList();
            return Container(
              width: 220,
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(12),
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
                        child: Text(columnLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: VoltronColors.deepBlack,
                          borderRadius: BorderRadius.circular(VoltronRadii.pill),
                        ),
                        child: Text('${columnOrders.length}',
                            style: const TextStyle(fontSize: 11, color: VoltronColors.electricYellow, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...columnOrders.map((order) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: VoltronColors.deepBlack,
                          borderRadius: BorderRadius.circular(VoltronRadii.sm),
                          border: order.isBlockedOnQuote
                              ? Border.all(color: VoltronColors.warning.withValues(alpha: 0.6))
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#${order.id}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            Text(order.scooterName, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                            if (order.isBlockedOnQuote)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('En attente devis', style: TextStyle(color: VoltronColors.warning, fontSize: 10)),
                              ),
                          ],
                        ),
                      )),
                  if (columnOrders.isEmpty)
                    const Text('—', style: TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
