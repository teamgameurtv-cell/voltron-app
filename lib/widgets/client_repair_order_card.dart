import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/repair.dart';
import '../theme/voltron_theme.dart';

/// Ligne compacte d'un dossier de réparation dans la liste du client — tape
/// dessus pour ouvrir le suivi complet (voir client_repair_order_screen.dart).
class ClientRepairOrderCard extends StatelessWidget {
  final RepairOrder order;

  const ClientRepairOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isComplete = order.isComplete;
    final badgeColor = isComplete
        ? VoltronColors.success
        : order.isBlockedOnQuote
        ? VoltronColors.warning
        : VoltronColors.electricBlueGlow;
    final badgeLabel = isComplete ? 'Terminée' : order.currentStep.label;

    return GestureDetector(
      onTap: () => context.push('/repairs/order/${order.dbId}'),
      child: Container(
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
                  Text(
                    order.scooterName,
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
      ),
    );
  }
}
