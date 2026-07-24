import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/repairs_provider.dart';
import '../../theme/voltron_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/client_booking_card.dart';
import '../../widgets/client_repair_order_card.dart';

class RepairsScreen extends ConsumerWidget {
  const RepairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    final allOrders = ref
        .watch(repairsProvider)
        .where((o) => o.clientId == userId)
        .toList();
    final orders = allOrders.where((o) => !o.archived).toList();
    final archivedOrders = allOrders.where((o) => o.archived).toList();
    final bookings = ref
        .watch(bookingsProvider)
        .where((b) => b.clientId == userId)
        .toList();
    final needsResponse = bookings
        .where((b) => b.status == BookingStatus.rescheduled)
        .toList();
    final activeBookings = bookings
        .where(
          (b) =>
              b.status == BookingStatus.pending ||
              b.status == BookingStatus.confirmed,
        )
        .toList();
    final cancelledBookings = bookings
        .where((b) => b.status == BookingStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const AppHeader(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RÉPARATIONS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/repairs/book'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('RÉSERVER', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (bookings.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'MES RENDEZ-VOUS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: VoltronColors.greyText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ...needsResponse.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClientBookingCard(booking: b),
                ),
              ),
              ...activeBookings.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClientBookingCard(booking: b),
                ),
              ),
              if (cancelledBookings.isNotEmpty)
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    iconColor: VoltronColors.electricYellow,
                    collapsedIconColor: VoltronColors.greyText,
                    title: Text(
                      'Rendez-vous annulés (${cancelledBookings.length})',
                      style: const TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: cancelledBookings
                        .map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClientBookingCard(booking: b),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            if (orders.isEmpty)
              const Text(
                'Aucun dossier en cours.',
                style: TextStyle(color: VoltronColors.greyText),
              )
            else
              ...orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClientRepairOrderCard(order: order),
                ),
              ),
            if (archivedOrders.isNotEmpty)
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  iconColor: VoltronColors.electricYellow,
                  collapsedIconColor: VoltronColors.greyText,
                  title: Text(
                    'Réparations archivées (${archivedOrders.length})',
                    style: const TextStyle(
                      color: VoltronColors.greyText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: archivedOrders
                      .map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClientRepairOrderCard(order: order),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/account/repairs-history'),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('VOIR L\'HISTORIQUE COMPLET'),
            ),
          ],
        ),
      ),
    );
  }
}
