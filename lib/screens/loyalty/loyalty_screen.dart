import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/reward.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/garage_provider.dart';
import '../../providers/loyalty_goals_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/app_header.dart';

class _LoyaltyGoal {
  final String id;
  final String title;
  final String subtitle;
  final int points;
  final IconData icon;
  final bool manual;

  const _LoyaltyGoal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.icon,
    this.manual = false,
  });
}

const List<_LoyaltyGoal> _loyaltyGoals = [
  _LoyaltyGoal(
    id: 'phone_added',
    title: 'Ajoute ton numéro de téléphone',
    subtitle: 'Renseigne-le dans Mes informations',
    points: 20,
    icon: Icons.phone_iphone_rounded,
  ),
  _LoyaltyGoal(
    id: 'email_confirmed',
    title: 'Confirme ton adresse e-mail',
    subtitle: 'Valide le lien reçu à l\'inscription',
    points: 20,
    icon: Icons.mark_email_read_outlined,
  ),
  _LoyaltyGoal(
    id: 'avatar_added',
    title: 'Ajoute une photo de profil',
    subtitle: 'Personnalise ton compte',
    points: 15,
    icon: Icons.account_circle_outlined,
  ),
  _LoyaltyGoal(
    id: 'address_added',
    title: 'Ajoute ton adresse',
    subtitle: 'Renseigne-la dans Mes informations',
    points: 15,
    icon: Icons.location_on_outlined,
  ),
  _LoyaltyGoal(
    id: 'birthdate_added',
    title: 'Renseigne ta date de naissance',
    subtitle: 'À l\'inscription, pour en profiter',
    points: 15,
    icon: Icons.cake_outlined,
  ),
  _LoyaltyGoal(
    id: 'vehicle_added',
    title: 'Enregistre un véhicule',
    subtitle: 'Ajoute ta trottinette dans Mon Garage',
    points: 20,
    icon: Icons.electric_scooter_rounded,
  ),
  _LoyaltyGoal(
    id: 'first_purchase',
    title: 'Passe ta première commande',
    subtitle: 'Achète un article dans la boutique',
    points: 30,
    icon: Icons.shopping_bag_outlined,
  ),
  _LoyaltyGoal(
    id: 'care_subscribed',
    title: 'Abonne-toi à Voltron Care',
    subtitle: 'Entretien serein toute l\'année',
    points: 30,
    icon: Icons.verified_rounded,
  ),
  _LoyaltyGoal(
    id: 'instagram_follow',
    title: 'Suis notre compte Instagram',
    subtitle: 'Reviens ici réclamer tes points une fois abonné',
    points: 20,
    icon: Icons.camera_alt_outlined,
    manual: true,
  ),
];

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  bool _isEligible(String goalId, WidgetRef ref) {
    switch (goalId) {
      case 'phone_added':
        return ref.watch(profileProvider).phone.trim().isNotEmpty;
      case 'email_confirmed':
        return ref.watch(currentUserProvider)?.emailConfirmedAt != null;
      case 'avatar_added':
        return (ref.watch(profileProvider).avatarUrl ?? '').isNotEmpty;
      case 'address_added':
        return ref.watch(profileProvider).address.trim().isNotEmpty;
      case 'birthdate_added':
        return ref.watch(profileProvider).dateOfBirth != null;
      case 'vehicle_added':
        return ref.watch(garageProvider).isNotEmpty;
      case 'first_purchase':
        return ref.watch(invoicesProvider).valueOrNull?.isNotEmpty ?? false;
      case 'care_subscribed':
        return ref.watch(subscriptionProvider) != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    final loyaltyPoints = ref.watch(profileProvider).loyaltyPoints;
    final claimedGoals =
        ref.watch(claimedLoyaltyGoalsProvider).valueOrNull ?? {};
    final redemptions = ref.watch(myRedemptionsProvider).valueOrNull ?? [];

    for (final goal in _loyaltyGoals) {
      if (!goal.manual &&
          !claimedGoals.contains(goal.id) &&
          _isEligible(goal.id, ref)) {
        Future.microtask(
          () => ref
              .read(loyaltyGoalsNotifierProvider)
              .claim(goal.id, goal.points),
        );
      }
    }
    final completedCount = _loyaltyGoals
        .where((g) => claimedGoals.contains(g.id))
        .length;

    final nextRewards = rewards.where((r) => r.points > loyaltyPoints).toList()
      ..sort((a, b) => a.points.compareTo(b.points));
    final nextReward = nextRewards.isEmpty ? null : nextRewards.first;
    final pointsProgress = nextReward == null
        ? 1.0
        : (loyaltyPoints / nextReward.points).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const AppHeader(),
            const SizedBox(height: 20),
            const Text(
              'FIDÉLITÉ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Container(
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
                          'MES POINTS',
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
                            const Text(
                              'pts',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _showHistoryDialog(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'Voir mon historique',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        if (nextReward != null) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              VoltronRadii.pill,
                            ),
                            child: LinearProgressIndicator(
                              value: pointsProgress,
                              minHeight: 6,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(
                                VoltronColors.electricYellow,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Plus que ${nextReward.points - loyaltyPoints} pts pour "${nextReward.label}"',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.bolt_rounded,
                    color: VoltronColors.electricYellow,
                    size: 40,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/loyalty/qr'),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('MON QR CODE FIDÉLITÉ'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'OBJECTIFS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: VoltronColors.greyText,
                  ),
                ),
                Text(
                  '$completedCount/${_loyaltyGoals.length} complétés',
                  style: const TextStyle(
                    fontSize: 11,
                    color: VoltronColors.greyText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(VoltronRadii.pill),
              child: LinearProgressIndicator(
                value: completedCount / _loyaltyGoals.length,
                minHeight: 8,
                backgroundColor: VoltronColors.cardBlack,
                valueColor: const AlwaysStoppedAnimation(
                  VoltronColors.electricYellow,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: VoltronColors.electricYellow,
                collapsedIconColor: VoltronColors.greyText,
                title: const Text(
                  'Voir le détail des objectifs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VoltronColors.greyText,
                  ),
                ),
                children: _loyaltyGoals.map((goal) {
                  final isDone = claimedGoals.contains(goal.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VoltronColors.cardBlack,
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                      border: Border.all(
                        color: isDone
                            ? VoltronColors.success.withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: VoltronColors.deepBlack,
                            borderRadius: BorderRadius.circular(
                              VoltronRadii.sm,
                            ),
                          ),
                          child: Icon(
                            isDone ? Icons.check_rounded : goal.icon,
                            color: isDone
                                ? VoltronColors.success
                                : VoltronColors.electricYellow,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDone
                                      ? VoltronColors.greyText
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                goal.subtitle,
                                style: const TextStyle(
                                  color: VoltronColors.greyText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDone)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: VoltronColors.success,
                            size: 20,
                          )
                        else if (goal.manual)
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: VoltronColors.electricYellow,
                              foregroundColor: VoltronColors.deepBlack,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  VoltronRadii.pill,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              final credited = await ref
                                  .read(loyaltyGoalsNotifierProvider)
                                  .claim(goal.id, goal.points);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    credited
                                        ? '+${goal.points} points crédités !'
                                        : 'Déjà réclamé',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              '+${goal.points} pts',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Text(
                            '+${goal.points} pts',
                            style: const TextStyle(
                              color: VoltronColors.electricYellow,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'RÉCOMPENSES DISPONIBLES',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: VoltronColors.greyText,
              ),
            ),
            const SizedBox(height: 6),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: VoltronColors.electricYellow,
                collapsedIconColor: VoltronColors.greyText,
                title: const Text(
                  'Voir le détail des récompenses',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VoltronColors.greyText,
                  ),
                ),
                children: rewards.map((reward) {
                  final canAfford = loyaltyPoints >= reward.points;
                  return Container(
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
                            borderRadius: BorderRadius.circular(
                              VoltronRadii.sm,
                            ),
                          ),
                          child: Icon(
                            reward.icon,
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
                                reward.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${reward.points} points',
                                style: const TextStyle(
                                  color: VoltronColors.greyText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: canAfford
                                ? VoltronColors.electricYellow
                                : VoltronColors.deepBlack,
                            foregroundColor: canAfford
                                ? VoltronColors.deepBlack
                                : VoltronColors.greyText,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                VoltronRadii.pill,
                              ),
                            ),
                          ),
                          onPressed: !canAfford
                              ? null
                              : () async {
                                  try {
                                    final redemption = await ref
                                        .read(rewardsProvider.notifier)
                                        .redeem(reward.id);
                                    if (!context.mounted) return;
                                    _showRedemptionDialog(context, redemption);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pas assez de points pour cette récompense',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            canAfford ? 'Échanger' : 'Pas assez de points',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            if (redemptions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'MES CODES ÉCHANGÉS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: VoltronColors.greyText,
                ),
              ),
              const SizedBox(height: 6),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  iconColor: VoltronColors.electricYellow,
                  collapsedIconColor: VoltronColors.greyText,
                  title: Text(
                    'Voir mes codes (${redemptions.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VoltronColors.greyText,
                    ),
                  ),
                  children: redemptions
                      .map(
                        (r) => GestureDetector(
                          onTap: () => _showRedemptionDialog(context, r),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: VoltronColors.cardBlack,
                              borderRadius: BorderRadius.circular(
                                VoltronRadii.md,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.rewardLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${r.redeemedAt.toLocal().day.toString().padLeft(2, '0')}/${r.redeemedAt.toLocal().month.toString().padLeft(2, '0')}/${r.redeemedAt.toLocal().year}',
                                        style: const TextStyle(
                                          color: VoltronColors.greyText,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VoltronColors.deepBlack,
                                    borderRadius: BorderRadius.circular(
                                      VoltronRadii.sm,
                                    ),
                                    border: Border.all(
                                      color: VoltronColors.electricYellow
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    r.code,
                                    style: const TextStyle(
                                      color: VoltronColors.electricYellow,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
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
                        Text(
                          'VOLTRON CARE',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: VoltronColors.electricBlueGlow,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Prenez soin de votre trottinette en toute sérénité.',
                          style: TextStyle(
                            color: VoltronColors.greyText,
                            fontSize: 12,
                          ),
                        ),
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

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: const Text('Historique des points'),
        content: SizedBox(
          width: 360,
          child: Consumer(
            builder: (context, ref, _) {
              final entries = ref.watch(loyaltyHistoryProvider);
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Aucun historique pour l\'instant. Complète des objectifs fidélité pour gagner tes premiers points !',
                    style: TextStyle(
                      color: VoltronColors.greyText,
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 320,
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white24, height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final title = entry.isGoal
                        ? _loyaltyGoals
                              .firstWhere(
                                (g) => g.id == entry.label,
                                orElse: () => _LoyaltyGoal(
                                  id: entry.label,
                                  title: entry.label,
                                  subtitle: '',
                                  points: 0,
                                  icon: Icons.star,
                                ),
                              )
                              .title
                        : entry.label;
                    final date = entry.date.toLocal();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                                  style: const TextStyle(
                                    color: VoltronColors.greyText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${entry.points} pts',
                            style: const TextStyle(
                              color: VoltronColors.electricYellow,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showRedemptionDialog(
    BuildContext context,
    RewardRedemption redemption,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: const Text('Récompense échangée !'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              redemption.rewardLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${redemption.pointsSpent} points dépensés',
              style: const TextStyle(
                color: VoltronColors.greyText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Présente ce code en boutique pour en profiter :',
              style: TextStyle(color: VoltronColors.greyText, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: VoltronColors.deepBlack,
                borderRadius: BorderRadius.circular(VoltronRadii.md),
                border: Border.all(color: VoltronColors.electricYellow),
              ),
              child: Text(
                redemption.code,
                style: const TextStyle(
                  color: VoltronColors.electricYellow,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
