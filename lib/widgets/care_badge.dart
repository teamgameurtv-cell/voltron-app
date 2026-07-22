import 'package:flutter/material.dart';
import '../models/reward.dart';
import '../theme/voltron_theme.dart';

/// Petit badge "logo" Voltron Care (Essentiel/Plus), à afficher à côté d'un
/// client abonné — fiche client, liste de tickets support, etc.
class CareBadge extends StatelessWidget {
  final CarePlan plan;

  const CareBadge({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Abonné Voltron Care ${plan.name}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: VoltronColors.blueGlow,
          borderRadius: BorderRadius.circular(VoltronRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'CARE ${plan.name}',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
