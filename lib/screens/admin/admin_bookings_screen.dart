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

TextStyle _maybeStrike(TextStyle style, bool cancelled) => cancelled
    ? style.copyWith(
        decoration: TextDecoration.lineThrough,
        color: VoltronColors.greyText,
      )
    : style;

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.confirmed => VoltronColors.success,
      BookingStatus.pending => VoltronColors.warning,
      BookingStatus.cancelled => const Color(0xFFFF5C5C),
    };
    final label = switch (status) {
      BookingStatus.confirmed => 'Confirmé',
      BookingStatus.pending => 'En attente',
      BookingStatus.cancelled => 'Annulé',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(VoltronRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
    final isCancelled = booking.status == BookingStatus.cancelled;
    return Material(
      color: VoltronColors.cardBlack,
      borderRadius: BorderRadius.circular(VoltronRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(VoltronRadii.md),
        onTap: () => _showBookingDetailDialog(context, ref, booking),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.day,
                      style: _maybeStrike(
                        const TextStyle(
                          fontSize: 11,
                          color: VoltronColors.greyText,
                        ),
                        isCancelled,
                      ),
                    ),
                    Text(
                      booking.time,
                      style: _maybeStrike(
                        const TextStyle(fontWeight: FontWeight.w700),
                        isCancelled,
                      ),
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
                      style: _maybeStrike(
                        const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        isCancelled,
                      ),
                    ),
                    Text(
                      booking.clientName,
                      style: _maybeStrike(
                        const TextStyle(
                          color: VoltronColors.greyText,
                          fontSize: 11,
                        ),
                        isCancelled,
                      ),
                    ),
                    if (booking.scooterName.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          booking.scooterName,
                          style: _maybeStrike(
                            const TextStyle(
                              color: VoltronColors.electricBlueGlow,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            isCancelled,
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
                          style: _maybeStrike(
                            const TextStyle(
                              color: VoltronColors.greyText,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                            isCancelled,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _StatusBadge(status: booking.status),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Confirmer',
                onPressed: booking.status == BookingStatus.confirmed
                    ? null
                    : () => ref
                          .read(bookingsProvider.notifier)
                          .confirmBooking(booking.id),
                icon: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: booking.status == BookingStatus.confirmed
                      ? VoltronColors.greyText.withValues(alpha: 0.4)
                      : VoltronColors.success,
                ),
              ),
              IconButton(
                tooltip: 'Reprogrammer',
                onPressed: () => _showRescheduleDialog(context, ref, booking),
                icon: const Icon(
                  Icons.event_repeat_rounded,
                  size: 20,
                  color: VoltronColors.electricBlueGlow,
                ),
              ),
              IconButton(
                tooltip: 'Annuler',
                onPressed: isCancelled
                    ? null
                    : () => ref
                          .read(bookingsProvider.notifier)
                          .cancelBooking(booking.id),
                icon: Icon(
                  Icons.cancel_outlined,
                  size: 20,
                  color: isCancelled
                      ? VoltronColors.greyText.withValues(alpha: 0.4)
                      : const Color(0xFFFF5C5C),
                ),
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
        ),
      ),
    );
  }
}

const List<String> _rescheduleTimeSlots = [
  '09:00',
  '10:00',
  '11:00',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
];

void _showRescheduleDialog(
  BuildContext context,
  WidgetRef ref,
  Booking booking,
) {
  DateTime focusedDay = booking.parsedDay ?? DateTime.now();
  DateTime? selectedDay = booking.parsedDay;
  String? selectedTime;
  List<String> bookedTimes = [];
  bool loadingBookedTimes = false;
  bool initialLoadTriggered = false;
  final reasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> loadBookedTimes(DateTime day) async {
          setDialogState(() => loadingBookedTimes = true);
          final formatted =
              '${day.day} ${bookingMonthNames[day.month - 1]} ${day.year}';
          final booked = await ref
              .read(bookingsProvider.notifier)
              .bookedTimesForDay(formatted);
          setDialogState(() {
            bookedTimes = booked..remove(booking.time);
            loadingBookedTimes = false;
          });
        }

        if (!initialLoadTriggered && selectedDay != null) {
          initialLoadTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => loadBookedTimes(selectedDay!),
          );
        }

        return AlertDialog(
          backgroundColor: VoltronColors.cardBlack,
          title: const Text('Reprogrammer le rendez-vous'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VoltronColors.deepBlack,
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                    ),
                    child: TableCalendar<void>(
                      firstDay: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDay: DateTime(DateTime.now().year + 2),
                      focusedDay: focusedDay,
                      selectedDayPredicate: (day) =>
                          selectedDay != null && isSameDay(selectedDay!, day),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      daysOfWeekHeight: 20,
                      onDaySelected: (selected, focused) {
                        setDialogState(() {
                          selectedDay = selected;
                          focusedDay = focused;
                          selectedTime = null;
                        });
                        loadBookedTimes(selected);
                      },
                      onPageChanged: (focused) =>
                          setDialogState(() => focusedDay = focused),
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        weekendTextStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        todayDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: VoltronColors.electricBlueGlow,
                            width: 1.5,
                          ),
                        ),
                        selectedDecoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: VoltronColors.electricYellow,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: VoltronColors.deepBlack,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Heure',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (loadingBookedTimes) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: VoltronColors.electricYellow,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (selectedDay == null)
                    const Text(
                      'Choisis d\'abord une date.',
                      style: TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 12,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _rescheduleTimeSlots.map((time) {
                        final isSelected = time == selectedTime;
                        final isTaken = bookedTimes.contains(time);
                        return GestureDetector(
                          onTap: isTaken
                              ? null
                              : () => setDialogState(() => selectedTime = time),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? VoltronColors.electricYellow
                                  : VoltronColors.deepBlack,
                              borderRadius: BorderRadius.circular(
                                VoltronRadii.sm,
                              ),
                              border: isTaken
                                  ? Border.all(
                                      color: VoltronColors.greyText.withValues(
                                        alpha: 0.3,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isTaken
                                    ? VoltronColors.greyText.withValues(
                                        alpha: 0.5,
                                      )
                                    : isSelected
                                    ? VoltronColors.deepBlack
                                    : Colors.white,
                                decoration: isTaken
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Raison (optionnel)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: (selectedDay == null || selectedTime == null)
                  ? null
                  : () async {
                      final formatted =
                          '${selectedDay!.day} ${bookingMonthNames[selectedDay!.month - 1]} ${selectedDay!.year}';
                      await ref
                          .read(bookingsProvider.notifier)
                          .rescheduleBooking(
                            booking.id,
                            day: formatted,
                            time: selectedTime!,
                            reason: reasonController.text,
                          );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                    },
              child: const Text('PROPOSER CE CRÉNEAU'),
            ),
          ],
        );
      },
    ),
  );
}

void _showBookingDetailDialog(
  BuildContext context,
  WidgetRef ref,
  Booking booking,
) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: VoltronColors.cardBlack,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.calendar_month_rounded,
                label: 'Date',
                value: booking.day,
              ),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Heure',
                value: booking.time,
              ),
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Client',
                value: booking.clientName,
              ),
              if (booking.clientPhone.trim().isNotEmpty)
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: booking.clientPhone,
                ),
              if (booking.scooterName.trim().isNotEmpty)
                _DetailRow(
                  icon: Icons.electric_scooter_rounded,
                  label: 'Véhicule',
                  value: booking.scooterName,
                ),
              if (booking.problemDescription.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'PROBLÈME DÉCRIT',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: VoltronColors.greyText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  booking.problemDescription,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: VoltronColors.greyText),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: VoltronColors.greyText,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
