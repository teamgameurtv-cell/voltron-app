import 'package:flutter/material.dart';
import '../models/repair.dart';
import '../theme/voltron_theme.dart';

/// Icône associée à chaque étape — partagée avec l'écran de suivi client
/// pour l'icône mise en avant sur la carte "Étape actuelle".
const Map<String, IconData> stepIcons = {
  'Rendez-vous pris': Icons.event_available_rounded,
  'Trottinette déposée': Icons.electric_scooter,
  'Diagnostic en cours': Icons.troubleshoot_rounded,
  'Devis envoyé': Icons.request_quote_rounded,
  'Pièces commandées': Icons.local_shipping_rounded,
  'Réparation en cours': Icons.build_rounded,
  'Prête à récupérer': Icons.done_all_rounded,
  'Récupérée': Icons.assignment_turned_in_rounded,
};

/// Frise horizontale des 8 étapes d'un dossier, avec une icône distincte par
/// étape et une ligne de progression colorée selon le statut (fait/en
/// cours/à venir).
class RepairStepTracker extends StatelessWidget {
  final List<RepairStep> steps;
  final ValueChanged<RepairStep>? onTapStep;

  const RepairStepTracker({super.key, required this.steps, this.onTapStep});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepNode(
              step: steps[i],
              number: i + 1,
              onTap: onTapStep == null ? null : () => onTapStep!(steps[i]),
            ),
            if (i < steps.length - 1)
              Container(
                width: 22,
                height: 2,
                color: steps[i].status == RepairStepStatus.done
                    ? VoltronColors.success
                    : VoltronColors.greyText.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final RepairStep step;
  final int number;
  final VoidCallback? onTap;

  const _StepNode({required this.step, required this.number, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (step.status) {
      RepairStepStatus.done => VoltronColors.success,
      RepairStepStatus.current => VoltronColors.electricYellow,
      RepairStepStatus.pending => VoltronColors.greyText,
    };
    final icon = stepIcons[step.label] ?? Icons.circle_outlined;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.status == RepairStepStatus.pending
                    ? Colors.transparent
                    : color.withValues(alpha: 0.15),
                border: Border.all(
                  color: color,
                  width: step.status == RepairStepStatus.current ? 2 : 1,
                ),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              '$number',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
