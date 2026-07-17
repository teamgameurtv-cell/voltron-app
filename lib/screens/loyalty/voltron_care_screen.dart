import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock_rewards.dart';
import '../../models/reward.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/voltron_theme.dart';

class VoltronCareScreen extends ConsumerWidget {
  const VoltronCareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlan = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('VOLTRON CARE'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (activePlan != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: VoltronColors.blueGlow,
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: VoltronColors.electricYellow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Abonnement ${activePlan.name} actif',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(subscriptionProvider.notifier).cancel();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abonnement résilié')),
                        );
                      },
                      child: const Text('Résilier', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Prenez soin de votre trottinette en toute sérénité.',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ...mockCarePlans.map((plan) => _PlanCard(plan: plan, isActive: activePlan?.id == plan.id)),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final CarePlan plan;
  final bool isActive;

  const _PlanCard({required this.plan, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.lg),
        border: Border.all(
          color: isActive
              ? VoltronColors.success
              : (plan.recommended ? VoltronColors.electricYellow : Colors.transparent),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1)),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VoltronColors.success,
                    borderRadius: BorderRadius.circular(VoltronRadii.pill),
                  ),
                  child: const Text('ACTIF',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                )
              else if (plan.recommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VoltronColors.electricYellow,
                    borderRadius: BorderRadius.circular(VoltronRadii.pill),
                  ),
                  child: const Text('RECOMMANDÉ',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: VoltronColors.deepBlack)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${plan.monthlyPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: VoltronColors.electricYellow),
              ),
              const Text(' / mois', style: TextStyle(color: VoltronColors.greyText, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: VoltronColors.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: isActive ? null : () => context.push('/loyalty/care/payment/${plan.id}'),
            child: Text(isActive ? 'DÉJÀ ABONNÉ' : 'CHOISIR'),
          ),
        ],
      ),
    );
  }
}
