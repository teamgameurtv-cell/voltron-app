import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking.dart';
import '../../models/repair.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    final repairs = ref.watch(repairsProvider);
    final products = ref.watch(catalogProvider);

    final activeBookings = bookings.where((b) => !b.archived).toList();
    final now = DateTime.now();
    final todayBookings = activeBookings
        .where(
          (b) => b.parsedDay != null && isSameBookingDay(b.parsedDay!, now),
        )
        .toList();
    final inProgressRepairs = repairs
        .where((r) => r.steps.any((s) => s.status == RepairStepStatus.current))
        .toList();
    final totalStock = products.fold<int>(0, (sum, p) => sum + p.stock);

    return AdminShell(
      selected: AdminSection.dashboard,
      title: 'TABLEAU DE BORD',
      child: ListView(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                label: 'RENDEZ-VOUS AUJOURD\'HUI',
                value: '${todayBookings.length}',
                icon: Icons.calendar_month_rounded,
              ),
              _StatCard(
                label: 'RÉPARATIONS EN COURS',
                value: '${inProgressRepairs.length}',
                icon: Icons.build_rounded,
              ),
              _StatCard(
                label: 'PRODUITS AU CATALOGUE',
                value: '${products.length}',
                icon: Icons.storefront_rounded,
              ),
              _StatCard(
                label: 'UNITÉS EN STOCK',
                value: '$totalStock',
                icon: Icons.inventory_2_rounded,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'RENDEZ-VOUS À VENIR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: VoltronColors.greyText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: VoltronColors.cardBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.md),
            ),
            child: Column(
              children: activeBookings
                  .take(5)
                  .map((b) => _BookingRow(booking: b))
                  .toList(),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'RÉPARATIONS EN COURS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: VoltronColors.greyText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: VoltronColors.cardBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.md),
            ),
            child: Column(
              children: repairs.map((r) => _RepairRow(order: r)).toList(),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: VoltronColors.electricYellow, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: VoltronColors.greyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final Booking booking;

  const _BookingRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status) {
      BookingStatus.confirmed => VoltronColors.success,
      BookingStatus.pending => VoltronColors.warning,
      BookingStatus.cancelled => const Color(0xFFFF5C5C),
      BookingStatus.rescheduled => VoltronColors.electricBlueGlow,
    };
    final statusLabel = switch (booking.status) {
      BookingStatus.confirmed => 'Confirmé',
      BookingStatus.pending => 'En attente',
      BookingStatus.cancelled => 'Annulé',
      BookingStatus.rescheduled => 'Reprogrammé',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              booking.time,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.serviceName, style: const TextStyle(fontSize: 13)),
                Text(
                  booking.clientName,
                  style: const TextStyle(
                    color: VoltronColors.greyText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(VoltronRadii.pill),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepairRow extends StatelessWidget {
  final RepairOrder order;

  const _RepairRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final current = order.currentStep;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '#${order.id}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              order.scooterName,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            current.label,
            style: const TextStyle(color: VoltronColors.warning, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
