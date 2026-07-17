import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/repair.dart';
import '../../models/reward.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/quick_access_button.dart';

class AccueilScreen extends ConsumerWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final activePlan = ref.watch(subscriptionProvider);
    final rewards = ref.watch(rewardsProvider);
    final profile = ref.watch(profileProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    final myActiveOrders =
        ref.watch(repairsProvider).where((o) => o.clientId == userId && !o.isComplete).toList();
    final activeOrder = myActiveOrders.isEmpty ? null : myActiveOrders.first;
    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _buildHeader(context, unreadCount),
            const SizedBox(height: 20),
            _buildLoyaltyCard(context, rewards, profile.loyaltyPoints),
            if (activePlan != null) ...[
              const SizedBox(height: 16),
              _buildCareStatus(context, activePlan.name),
            ],
            if (activeOrder != null) ...[
              const SizedBox(height: 16),
              _buildRepairInProgress(context, activeOrder),
            ],
            const SizedBox(height: 24),
            _sectionTitle('Raccourcis'),
            const SizedBox(height: 12),
            _buildQuickAccessGrid(context),
            const SizedBox(height: 24),
            _buildPromoBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildCareStatus(BuildContext context, String planName) {
    return GestureDetector(
      onTap: () => context.push('/loyalty/care'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: VoltronColors.cardBlack,
          borderRadius: BorderRadius.circular(VoltronRadii.md),
          border: Border.all(color: VoltronColors.success.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: VoltronColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Voltron Care $planName actif',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const Icon(Icons.chevron_right_rounded, color: VoltronColors.greyText),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unreadCount) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Salut Maxime !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2),
              Text(
                'Prêt à rouler ?',
                style: TextStyle(color: VoltronColors.greyText, fontSize: 13),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_none_rounded, size: 26),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: VoltronColors.electricYellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        GestureDetector(
          onTap: () => context.push('/account'),
          child: const CircleAvatar(
            radius: 20,
            backgroundColor: VoltronColors.cardBlack,
            child: Icon(Icons.person, color: VoltronColors.greyText),
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyCard(BuildContext context, List<Reward> rewards, int loyaltyPoints) {
    final nextRewards = rewards.where((r) => r.points > loyaltyPoints).toList()
      ..sort((a, b) => a.points.compareTo(b.points));
    final nextReward = nextRewards.isEmpty ? null : nextRewards.first;
    final progress = nextReward == null ? 1.0 : (loyaltyPoints / nextReward.points).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VoltronRadii.lg),
        gradient: VoltronColors.blueGlow,
        boxShadow: [
          BoxShadow(
            color: VoltronColors.electricBlue.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MON SOLDE FIDÉLITÉ',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$loyaltyPoints',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('pts', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.go('/loyalty'),
                  child: const Text(
                    'Voir mes récompenses',
                    style: TextStyle(
                      color: VoltronColors.electricYellow,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.push('/loyalty/qr'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text('Voir mon QR code', style: TextStyle(fontSize: 12)),
                ),
                if (nextReward != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VoltronRadii.pill),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(VoltronColors.electricYellow),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plus que ${nextReward.points - loyaltyPoints} pts pour "${nextReward.label}"',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.bolt_rounded, color: VoltronColors.electricYellow, size: 40),
        ],
      ),
    );
  }

  Widget _buildRepairInProgress(BuildContext context, RepairOrder order) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(VoltronRadii.md),
        onTap: () => context.go('/repairs'),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: VoltronColors.deepBlack,
                borderRadius: BorderRadius.circular(VoltronRadii.sm),
              ),
              child: const Icon(Icons.electric_scooter_rounded,
                  color: VoltronColors.electricYellow),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dossier #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(order.scooterName,
                      style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: VoltronColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(order.currentStep.label,
                          style: const TextStyle(color: VoltronColors.warning, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: VoltronColors.greyText),
          ],
        ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700));
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        QuickAccessButton(
          icon: Icons.calendar_month_rounded,
          label: 'Réserver',
          onTap: () => context.push('/repairs/book'),
        ),
        QuickAccessButton(
          icon: Icons.storefront_rounded,
          label: 'Boutique',
          onTap: () => context.go('/shop'),
        ),
        QuickAccessButton(
          icon: Icons.garage_rounded,
          label: 'Mon Garage',
          onTap: () => context.push('/account/garage'),
        ),
        QuickAccessButton(
          icon: Icons.shield_rounded,
          label: 'Voltron Care',
          onTap: () => context.push('/loyalty/care'),
        ),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('-15% SUR LES PNEUS',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Jusqu\'au 30 juin 2024',
                    style: TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                const SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: VoltronColors.electricYellow,
                    foregroundColor: VoltronColors.deepBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VoltronRadii.pill),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('J\'en profite',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Icon(Icons.tire_repair, size: 48, color: VoltronColors.electricBlueGlow),
        ],
      ),
    );
  }
}
