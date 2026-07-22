import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/booking.dart';
import '../../models/repair.dart';
import '../../models/reward.dart';
import '../../models/shortcut_option.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/promo_banner_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/quick_access_button.dart';

class AccueilScreen extends ConsumerWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlan = ref.watch(subscriptionProvider);
    final rewards = ref.watch(rewardsProvider);
    final profile = ref.watch(profileProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    final myActiveOrders = ref
        .watch(repairsProvider)
        .where((o) => o.clientId == userId && !o.isComplete)
        .toList();
    final activeOrder = myActiveOrders.isEmpty ? null : myActiveOrders.first;
    final nextBooking = _nextBooking(ref, userId);
    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const AppHeader(),
            const SizedBox(height: 20),
            _buildLoyaltyCard(context, rewards, profile.loyaltyPoints),
            if (activePlan != null) ...[
              const SizedBox(height: 16),
              _buildCareStatus(context, activePlan.name),
            ],
            if (nextBooking != null) ...[
              const SizedBox(height: 16),
              _buildNextBooking(context, nextBooking),
            ],
            if (activeOrder != null) ...[
              const SizedBox(height: 16),
              _buildRepairInProgress(context, activeOrder),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Raccourcis'),
                GestureDetector(
                  onTap: () => _showEditShortcutsDialog(
                    context,
                    ref,
                    profile.quickShortcuts,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: VoltronColors.greyText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickAccessGrid(context, profile.quickShortcuts),
            const SizedBox(height: 24),
            _buildPromoBanner(context, ref),
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
          border: Border.all(
            color: VoltronColors.success.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              color: VoltronColors.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Voltron Care $planName actif',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: VoltronColors.greyText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(
    BuildContext context,
    List<Reward> rewards,
    int loyaltyPoints,
  ) {
    final nextRewards = rewards.where((r) => r.points > loyaltyPoints).toList()
      ..sort((a, b) => a.points.compareTo(b.points));
    final nextReward = nextRewards.isEmpty ? null : nextRewards.first;
    final progress = nextReward == null
        ? 1.0
        : (loyaltyPoints / nextReward.points).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(VoltronRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(VoltronRadii.lg),
        onTap: () => context.go('/loyalty'),
        child: Container(
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
                        const Text(
                          'pts',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Voir mes récompenses',
                      style: TextStyle(
                        color: VoltronColors.electricYellow,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/loyalty/qr'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                      label: const Text(
                        'Voir mon QR code',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (nextReward != null) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(VoltronRadii.pill),
                        child: LinearProgressIndicator(
                          value: progress,
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
      ),
    );
  }

  /// Prochain rendez-vous actif (hors annulés) à mettre en avant sur
  /// l'accueil : une réservation en attente de réponse à une reprogrammation
  /// passe avant toute autre, car elle demande une action du client.
  Booking? _nextBooking(WidgetRef ref, String? userId) {
    final bookings =
        ref
            .watch(bookingsProvider)
            .where(
              (b) =>
                  b.clientId == userId && b.status != BookingStatus.cancelled,
            )
            .toList()
          ..sort((a, b) {
            final aNeedsResponse = a.status == BookingStatus.rescheduled;
            final bNeedsResponse = b.status == BookingStatus.rescheduled;
            if (aNeedsResponse != bNeedsResponse) {
              return aNeedsResponse ? -1 : 1;
            }
            final da = a.parsedDay;
            final db = b.parsedDay;
            if (da == null || db == null) return 0;
            return da.compareTo(db);
          });
    return bookings.isEmpty ? null : bookings.first;
  }

  Widget _buildNextBooking(BuildContext context, Booking booking) {
    final needsResponse = booking.status == BookingStatus.rescheduled;
    final statusColor = switch (booking.status) {
      BookingStatus.confirmed => VoltronColors.success,
      BookingStatus.pending => VoltronColors.warning,
      BookingStatus.rescheduled => VoltronColors.electricBlueGlow,
      BookingStatus.cancelled => VoltronColors.greyText,
    };
    final statusLabel = switch (booking.status) {
      BookingStatus.confirmed => 'Confirmé',
      BookingStatus.pending => 'En attente',
      BookingStatus.rescheduled => 'Nouveau créneau à confirmer',
      BookingStatus.cancelled => 'Annulé',
    };
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(VoltronRadii.md),
        onTap: () => context.go('/repairs'),
        child: Container(
          decoration: needsResponse
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(VoltronRadii.md),
                  border: Border.all(
                    color: VoltronColors.electricBlueGlow.withValues(
                      alpha: 0.6,
                    ),
                  ),
                )
              : null,
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
                child: const Icon(
                  Icons.event_rounded,
                  color: VoltronColors.electricYellow,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${booking.day} à ${booking.time}',
                      style: const TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: VoltronColors.greyText,
              ),
            ],
          ),
        ),
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
                child: const Icon(
                  Icons.electric_scooter_rounded,
                  color: VoltronColors.electricYellow,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dossier #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      order.scooterName,
                      style: const TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 12,
                      ),
                    ),
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
                        Text(
                          order.currentStep.label,
                          style: const TextStyle(
                            color: VoltronColors.warning,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: VoltronColors.greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, List<String> shortcutIds) {
    final selected = shortcutIds
        .map((id) => allShortcuts.where((s) => s.id == id).firstOrNull)
        .whereType<ShortcutOption>()
        .toList();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: selected
          .map(
            (s) => QuickAccessButton(
              icon: s.icon,
              label: s.label,
              onTap: () => context.push(s.route),
            ),
          )
          .toList(),
    );
  }

  void _showEditShortcutsDialog(
    BuildContext context,
    WidgetRef ref,
    List<String> current,
  ) {
    final selected = {...current};
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: VoltronColors.cardBlack,
          title: const Text('Personnaliser mes raccourcis'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: allShortcuts
                    .map(
                      (s) => CheckboxListTile(
                        value: selected.contains(s.id),
                        title: Text(
                          s.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        secondary: Icon(
                          s.icon,
                          color: VoltronColors.electricYellow,
                          size: 20,
                        ),
                        activeColor: VoltronColors.electricYellow,
                        checkColor: VoltronColors.deepBlack,
                        onChanged: (checked) => setDialogState(() {
                          if (checked == true) {
                            selected.add(s.id);
                          } else {
                            selected.remove(s.id);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final ordered = allShortcuts
                    .map((s) => s.id)
                    .where(selected.contains)
                    .toList();
                ref.read(profileProvider.notifier).updateShortcuts(ordered);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context, WidgetRef ref) {
    final banner = ref.watch(promoBannerProvider).valueOrNull;
    if (banner == null || !banner.active) return const SizedBox.shrink();

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
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  banner.subtitle,
                  style: const TextStyle(
                    color: VoltronColors.greyText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: VoltronColors.electricYellow,
                    foregroundColor: VoltronColors.deepBlack,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VoltronRadii.pill),
                    ),
                  ),
                  onPressed: () => context.push(banner.ctaRoute),
                  child: Text(
                    banner.ctaLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.local_offer_rounded,
            size: 48,
            color: VoltronColors.electricBlueGlow,
          ),
        ],
      ),
    );
  }
}
