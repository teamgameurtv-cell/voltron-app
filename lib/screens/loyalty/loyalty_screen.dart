import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/account_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../theme/voltron_theme.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    final loyaltyPoints = ref.watch(profileProvider).loyaltyPoints;
    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text('FIDÉLITÉ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(VoltronRadii.lg),
                gradient: VoltronColors.blueGlow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MES POINTS',
                      style: TextStyle(fontSize: 11, letterSpacing: 1, color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$loyaltyPoints',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(width: 6),
                      const Text('pts', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Voir mon historique', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('RÉCOMPENSES DISPONIBLES',
                style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: VoltronColors.greyText)),
            const SizedBox(height: 12),
            ...rewards.map((reward) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                        child: Icon(reward.icon, color: VoltronColors.electricYellow, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reward.label,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('${reward.points} points',
                                style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: VoltronColors.electricYellow,
                          foregroundColor: VoltronColors.deepBlack,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(VoltronRadii.pill),
                          ),
                        ),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${reward.label} échangé')),
                        ),
                        child: const Text('Échanger', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/loyalty/qr'),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('MON QR CODE FIDÉLITÉ'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VoltronColors.cardBlack,
                borderRadius: BorderRadius.circular(VoltronRadii.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('VOLTRON CARE',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: VoltronColors.electricBlueGlow)),
                        SizedBox(height: 4),
                        Text('Prenez soin de votre trottinette en toute sérénité.',
                            style: TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/loyalty/care'),
                    child: const Text('Découvrir'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
