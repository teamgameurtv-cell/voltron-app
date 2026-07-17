import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);

    return AdminShell(
      selected: AdminSection.bookings,
      title: 'RÉSERVATIONS',
      child: ListView.separated(
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VoltronColors.cardBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.md),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.day, style: const TextStyle(fontSize: 11, color: VoltronColors.greyText)),
                      Text(booking.time, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.serviceName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(booking.clientName, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                    ],
                  ),
                ),
                DropdownButton<BookingStatus>(
                  value: booking.status,
                  dropdownColor: VoltronColors.cardBlack,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: BookingStatus.pending, child: Text('En attente')),
                    DropdownMenuItem(value: BookingStatus.confirmed, child: Text('Confirmé')),
                    DropdownMenuItem(value: BookingStatus.cancelled, child: Text('Annulé')),
                  ],
                  onChanged: (status) {
                    if (status != null) {
                      ref.read(bookingsProvider.notifier).updateStatus(booking.id, status);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
