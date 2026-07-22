import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/repair.dart';
import '../theme/voltron_theme.dart';

/// Détail complet d'un dossier de réparation côté client : étapes, notes, devis.
/// Si [collapsible] est vrai, seul l'en-tête (numéro, véhicule, étape en cours)
/// est visible tant qu'on ne tape pas dessus pour déplier le reste.
class ClientRepairOrderDetail extends StatelessWidget {
  final RepairOrder order;
  final bool collapsible;

  const ClientRepairOrderDetail({
    super.key,
    required this.order,
    this.collapsible = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...order.steps.map((step) => _TimelineTile(step: step)),
        const SizedBox(height: 8),
        if (order.quote != null)
          ElevatedButton(
            onPressed: () => context.push('/repairs/quote/${order.dbId}'),
            child: const Text('VOIR LE DEVIS'),
          ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => context.push('/repairs/messages/${order.dbId}'),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
          label: const Text('Message à l\'atelier'),
        ),
      ],
    );

    if (!collapsible) {
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
            Text(
              'Dossier #${order.id}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              order.scooterName,
              style: const TextStyle(
                color: VoltronColors.greyText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      );
    }

    final isComplete = order.isComplete;
    Color statusColor;
    if (isComplete) {
      statusColor = VoltronColors.success;
    } else if (order.isBlockedOnQuote) {
      statusColor = VoltronColors.warning;
    } else {
      statusColor = VoltronColors.electricBlueGlow;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
          iconColor: VoltronColors.electricYellow,
          collapsedIconColor: VoltronColors.greyText,
          title: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                'Dossier #${order.id}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          subtitle: Text(
            order.scooterName,
            style: const TextStyle(color: VoltronColors.greyText, fontSize: 12),
          ),
          children: [content],
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
                    color: step.status == RepairStepStatus.pending
                        ? VoltronColors.greyText
                        : Colors.white,
                  ),
                ),
                if (step.date != null)
                  Text(
                    step.date!,
                    style: const TextStyle(
                      color: VoltronColors.greyText,
                      fontSize: 11,
                    ),
                  )
                else
                  const Text(
                    'En attente',
                    style: TextStyle(
                      color: VoltronColors.greyText,
                      fontSize: 11,
                    ),
                  ),
                if ((step.note ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      step.note!,
                      style: const TextStyle(
                        color: VoltronColors.electricBlueGlow,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
