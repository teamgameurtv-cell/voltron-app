import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reward.dart';
import '../../providers/rewards_provider.dart';
import '../../theme/voltron_theme.dart';
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
                  child: Icon(reward.icon, color: VoltronColors.electricYellow),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(reward.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Text('${reward.points} pts',
                    style: const TextStyle(color: VoltronColors.electricYellow, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () => _showRewardDialog(context, ref, existing: reward),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  onPressed: () => ref.read(rewardsProvider.notifier).removeReward(reward.id),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF5C5C)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRewardDialog(BuildContext context, WidgetRef ref, {Reward? existing}) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final pointsController = TextEditingController(text: existing?.points.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: Text(existing == null ? 'Nouvelle récompense' : 'Modifier la récompense'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: labelController, decoration: const InputDecoration(hintText: 'Libellé')),
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
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final points = int.tryParse(pointsController.text) ?? 0;
              if (existing == null) {
                ref.read(rewardsProvider.notifier).addReward(
                      label: labelController.text.trim().isEmpty ? 'Nouvelle récompense' : labelController.text.trim(),
                      points: points,
                    );
              } else {
                ref.read(rewardsProvider.notifier).updateReward(Reward(
                      id: existing.id,
                      label: labelController.text.trim(),
                      points: points,
                      icon: existing.icon,
                    ));
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
