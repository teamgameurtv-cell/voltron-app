import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/repair.dart';
import '../models/repair_order_message.dart';
import '../providers/repair_order_detail_provider.dart';
import '../theme/voltron_theme.dart';

/// Ligne compacte d'un dossier de réparation dans la liste du client — tape
/// dessus pour ouvrir le suivi complet (voir client_repair_order_screen.dart).
class ClientRepairOrderCard extends ConsumerWidget {
  final RepairOrder order;

  const ClientRepairOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnreadMessage =
        ref.watch(
          unreadRepairMessagesCountProvider((
            order.dbId,
            RepairMessageSenderRole.client,
          )),
        ) >
        0;
    final isComplete = order.isComplete;
    final isRefused = order.quote?.status == QuoteStatus.refused;
    final badgeColor = isComplete
        ? VoltronColors.success
        : isRefused
        ? const Color(0xFFFF5C5C)
        : order.isBlockedOnQuote
        ? VoltronColors.warning
        : VoltronColors.electricBlueGlow;
    final badgeLabel = isComplete
        ? 'Terminée'
        : isRefused
        ? 'Devis refusé'
        : order.currentStep.label;

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
            Stack(
              clipBehavior: Clip.none,
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
                if (hasUnreadMessage)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: VoltronColors.electricYellow,
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
