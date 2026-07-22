import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

const List<String> _weekdayLabels = [
  'LUN',
  'MAR',
  'MER',
  'JEU',
  'VEN',
  'SAM',
  'DIM',
];

String _formatSelectedDay(DateTime day) {
  const weekdays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  return '${weekdays[day.weekday - 1]} ${day.day} ${bookingMonthNames[day.month - 1].toLowerCase()} ${day.year}';
}

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() =>
      _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final allBookings = ref.watch(bookingsProvider);
    final activeBookings = allBookings.where((b) => !b.archived).toList();
    final archivedBookings = allBookings.where((b) => b.archived).toList();
    final selectedDayBookings =
        activeBookings
            .where(
              (b) =>
                  b.parsedDay != null && isSameDay(b.parsedDay!, _selectedDay),
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));

    return AdminShell(
      selected: AdminSection.bookings,
      title: 'RÉSERVATIONS',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 380,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VoltronColors.cardBlack,
                borderRadius: BorderRadius.circular(VoltronRadii.md),
              ),
              child: TableCalendar<Booking>(
                firstDay: DateTime(DateTime.now().year - 2),
                lastDay: DateTime(DateTime.now().year + 2),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                startingDayOfWeek: StartingDayOfWeek.monday,
                daysOfWeekHeight: 24,
                eventLoader: (day) => activeBookings
                    .where(
                      (b) =>
                          b.parsedDay != null && isSameDay(b.parsedDay!, day),
                    )
                    .toList(),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) =>
                    setState(() => _focusedDay = focused),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                  ),
                  titleTextFormatter: (date, locale) =>
                      '${bookingMonthNames[date.month - 1]} ${date.year}',
                ),
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) => Center(
                    child: Text(
                      _weekdayLabels[day.weekday - 1],
                      style: const TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: const TextStyle(color: Colors.white70),
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VoltronColors.electricBlueGlow,
                      width: 1.5,
                    ),
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedDecoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: VoltronColors.electricYellow,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: VoltronColors.deepBlack,
                    fontWeight: FontWeight.w800,
                  ),
                  markerDecoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: VoltronColors.electricYellow,
                  ),
                  markersAlignment: Alignment.bottomCenter,
                  markerSize: 5,
                  markersMaxCount: 3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _formatSelectedDay(_selectedDay),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!isSameDay(_selectedDay, DateTime.now()))
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedDay = DateTime.now();
                          _focusedDay = DateTime.now();
                        }),
                        child: const Text('AUJOURD\'HUI'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedDayBookings.isEmpty)
                  const Text(
                    'Aucune réservation ce jour-là.',
                    style: TextStyle(color: VoltronColors.greyText),
                  )
                else
                  ...selectedDayBookings.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BookingTile(booking: booking, ref: ref),
                    ),
                  ),
                if (archivedBookings.isNotEmpty) ...[
                  const SizedBox(height: 20),
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
                        'Réservations archivées (${archivedBookings.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: VoltronColors.greyText,
                        ),
                      ),
                      children: archivedBookings
                          .map(
                            (booking) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BookingTile(booking: booking, ref: ref),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  final WidgetRef ref;

  const _BookingTile({required this.booking, required this.ref});

  @override
  Widget build(BuildContext context) {
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
                Text(
                  booking.day,
                  style: const TextStyle(
                    fontSize: 11,
                    color: VoltronColors.greyText,
                  ),
                ),
                Text(
                  booking.time,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  booking.clientName,
                  style: const TextStyle(
                    color: VoltronColors.greyText,
                    fontSize: 11,
                  ),
                ),
                if (booking.scooterName.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      booking.scooterName,
                      style: const TextStyle(
                        color: VoltronColors.electricBlueGlow,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (booking.problemDescription.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      booking.problemDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          DropdownButton<BookingStatus>(
            value: booking.status,
            dropdownColor: VoltronColors.cardBlack,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: BookingStatus.pending,
                child: Text('En attente'),
              ),
              DropdownMenuItem(
                value: BookingStatus.confirmed,
                child: Text('Confirmé'),
              ),
              DropdownMenuItem(
                value: BookingStatus.cancelled,
                child: Text('Annulé'),
              ),
            ],
            onChanged: (status) {
              if (status != null) {
                ref
                    .read(bookingsProvider.notifier)
                    .updateStatus(booking.id, status);
              }
            },
          ),
          IconButton(
            tooltip: booking.archived ? 'Désarchiver' : 'Archiver',
            onPressed: () => ref
                .read(bookingsProvider.notifier)
                .setArchived(booking.id, !booking.archived),
            icon: Icon(
              booking.archived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
              size: 20,
              color: VoltronColors.greyText,
            ),
          ),
        ],
      ),
    );
  }
}
