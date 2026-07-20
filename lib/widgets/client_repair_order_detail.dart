import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/repair.dart';
import '../theme/voltron_theme.dart';

/// Détail complet d'un dossier de réparation côté client : étapes, notes, devis.
class ClientRepairOrderDetail extends StatelessWidget {
  final RepairOrder order;

  const ClientRepairOrderDetail({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Dossier #${order.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text(order.scooterName, style: const TextStyle(color: VoltronColors.greyText, fontSize: 13)),
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
                  Text(step.date!, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11))
                else
                  const Text('En attente', style: TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                if ((step.note ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(step.note!, style: const TextStyle(color: VoltronColors.electricBlueGlow, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
