import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reward.dart';
import '../../providers/admin_crm_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/client_avatar.dart';
import 'admin_shell.dart';

class AdminRewardsScreen extends ConsumerWidget {
  const AdminRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);

    return AdminShell(
      selected: AdminSection.rewards,
      title: 'FIDÉLITÉ',
      actions: ElevatedButton.icon(
        onPressed: () => _showRewardDialog(context, ref),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('AJOUTER'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RedeemCodeCard(),
          const SizedBox(height: 24),
          const Text(
            'RÉCOMPENSES DU CATALOGUE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: VoltronColors.greyText,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: rewards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return Container(
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
                        child: Icon(
                          reward.icon,
                          color: VoltronColors.electricYellow,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          reward.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${reward.points} pts',
                        style: const TextStyle(
                          color: VoltronColors.electricYellow,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _showRewardDialog(context, ref, existing: reward),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                      IconButton(
                        onPressed: () => ref
                            .read(rewardsProvider.notifier)
                            .removeReward(reward.id),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFFFF5C5C),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardDialog(
    BuildContext context,
    WidgetRef ref, {
    Reward? existing,
  }) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final pointsController = TextEditingController(
      text: existing?.points.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: Text(
          existing == null ? 'Nouvelle récompense' : 'Modifier la récompense',
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(hintText: 'Libellé'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Points requis'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final points = int.tryParse(pointsController.text) ?? 0;
              if (existing == null) {
                ref
                    .read(rewardsProvider.notifier)
                    .addReward(
                      label: labelController.text.trim().isEmpty
                          ? 'Nouvelle récompense'
                          : labelController.text.trim(),
                      points: points,
                    );
              } else {
                ref
                    .read(rewardsProvider.notifier)
                    .updateReward(
                      Reward(
                        id: existing.id,
                        label: labelController.text.trim(),
                        points: points,
                        icon: existing.icon,
                      ),
                    );
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );
  }
}

/// Carte pour valider en une action un code présenté en boutique : le
/// consomme côté serveur (non réutilisable ensuite) et affiche une
/// confirmation claire avec le client et la récompense concernés.
class _RedeemCodeCard extends ConsumerStatefulWidget {
  const _RedeemCodeCard();

  @override
  ConsumerState<_RedeemCodeCard> createState() => _RedeemCodeCardState();
}

class _RedeemCodeCardState extends ConsumerState<_RedeemCodeCard> {
  final _controller = TextEditingController();
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() => _checking = true);
    try {
      final redemption = await ref.read(rewardsProvider.notifier).useCode(code);
      _controller.clear();
      if (!mounted) return;
      _showSuccessDialog(redemption);
    } on Object catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('déjà été utilisé')
          ? 'Ce code a déjà été utilisé.'
          : e.toString().contains('introuvable')
          ? 'Code introuvable — vérifie la saisie.'
          : 'Impossible de valider ce code.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFFF5C5C),
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showSuccessDialog(RewardRedemption redemption) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: VoltronColors.success),
            SizedBox(width: 10),
            Text('Code validé'),
          ],
        ),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                redemption.rewardLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${redemption.pointsSpent} points dépensés',
                style: const TextStyle(
                  color: VoltronColors.greyText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              if (redemption.clientId != null)
                Consumer(
                  builder: (context, ref, _) {
                    final client = ref
                        .watch(clientByIdProvider(redemption.clientId!))
                        .valueOrNull;
                    if (client == null) {
                      return const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VoltronColors.electricYellow,
                        ),
                      );
                    }
                    return Row(
                      children: [
                        ClientAvatar(avatarUrl: client.avatarUrl, radius: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              if (client.phone.isNotEmpty)
                                Text(
                                  client.phone,
                                  style: const TextStyle(
                                    color: VoltronColors.greyText,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VoltronRadii.lg),
        gradient: VoltronColors.blueGlow,
        boxShadow: [
          BoxShadow(
            color: VoltronColors.electricBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(VoltronRadii.sm),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Valider un code client',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Le client te présente son code en boutique — saisis-le pour '
            'appliquer la récompense et le rendre inutilisable ensuite.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _validate(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 3,
                  ),
                  decoration: InputDecoration(
                    hintText: 'CODE',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      letterSpacing: 3,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(VoltronRadii.sm),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VoltronColors.electricYellow,
                  foregroundColor: VoltronColors.deepBlack,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                onPressed: _checking ? null : _validate,
                child: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: VoltronColors.deepBlack,
                        ),
                      )
                    : const Text('VALIDER'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
