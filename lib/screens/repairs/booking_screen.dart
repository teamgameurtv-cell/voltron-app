import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/repair.dart';
import '../../models/scooter.dart';
import '../../providers/account_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/garage_provider.dart';
import '../../providers/repair_services_provider.dart';
import '../../theme/voltron_theme.dart';

const List<String> _stepLabels = [
  'Service',
  'Problème',
  'Date & heure',
  'Vos informations',
  'Confirmation',
];
const List<String> _timeSlots = [
  '09:00',
  '10:00',
  '11:00',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
];
const List<String> _weekdayInitials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const List<String> _monthNames = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatDay(DateTime day) =>
    '${day.day} ${_monthNames[day.month - 1]} ${day.year}';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0;
  RepairService? _service;
  final _problemController = TextEditingController();
  OwnedScooter? _selectedScooter;
  DateTime? _selectedDay;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedTime;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _prefilledFromProfile = false;

  @override
  void dispose() {
    _problemController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _service != null;
      case 1:
        final garage = ref.watch(garageProvider);
        final needsScooterPick = garage.isNotEmpty && _selectedScooter == null;
        return _problemController.text.trim().isNotEmpty && !needsScooterPick;
      case 2:
        return _selectedDay != null && _selectedTime != null;
      case 3:
        return _nameController.text.trim().isNotEmpty &&
            _phoneController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      await ref
          .read(bookingsProvider.notifier)
          .add(
            serviceName: _service?.name ?? '-',
            clientName: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : 'Client',
            day: _selectedDay != null ? _formatDay(_selectedDay!) : '-',
            time: _selectedTime ?? '-',
            problemDescription: _problemController.text.trim(),
            scooterName: _selectedScooter != null
                ? '${_selectedScooter!.brand} ${_selectedScooter!.model}'
                : '',
          );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rendez-vous confirmé !')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (!_prefilledFromProfile &&
        (profile.name.isNotEmpty || profile.phone.isNotEmpty)) {
      _nameController.text = profile.name;
      _phoneController.text = profile.phone;
      _prefilledFromProfile = true;
    }

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _step == 0 ? context.pop() : setState(() => _step--),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('RÉSERVATION'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _StepperHeader(
                currentStep: _step,
                onStepTapped: (step) {
                  if (step <= _step) setState(() => _step = step);
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStepContent(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                onPressed: _canContinue ? _next : null,
                child: Text(_step == 4 ? 'CONFIRMER' : 'CONTINUER'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _ServiceStep(
          selected: _service,
          onSelect: (s) => setState(() => _service = s),
        );
      case 1:
        return _ProblemStep(
          problemController: _problemController,
          selectedScooter: _selectedScooter,
          onScooterSelected: (s) => setState(() => _selectedScooter = s),
          onDescriptionChanged: () => setState(() {}),
        );
      case 2:
        return _DateTimeStep(
          visibleMonth: _visibleMonth,
          selectedDay: _selectedDay,
          selectedTime: _selectedTime,
          onMonthChanged: (m) => setState(() => _visibleMonth = m),
          onDaySelected: (d) => setState(() => _selectedDay = d),
          onTimeSelected: (t) => setState(() => _selectedTime = t),
        );
      case 3:
        return _InfoStep(
          nameController: _nameController,
          phoneController: _phoneController,
        );
      default:
        return _ConfirmationStep(
          service: _service,
          problem: _problemController.text,
          scooter: _selectedScooter,
          day: _selectedDay,
          time: _selectedTime,
          name: _nameController.text,
        );
    }
  }
}

class _StepperHeader extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTapped;

  const _StepperHeader({required this.currentStep, required this.onStepTapped});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_stepLabels.length, (i) {
        final active = i == currentStep;
        final done = i < currentStep;
        final isTappable = i <= currentStep;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isTappable ? () => onStepTapped(i) : null,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: active || done
                      ? VoltronColors.electricYellow
                      : VoltronColors.cardBlack,
                  child: done && !active
                      ? const Icon(
                          Icons.check_rounded,
                          color: VoltronColors.deepBlack,
                          size: 16,
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: active || done
                                ? VoltronColors.deepBlack
                                : VoltronColors.greyText,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stepLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: active
                        ? VoltronColors.electricYellow
                        : VoltronColors.greyText,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ServiceStep extends ConsumerWidget {
  final RepairService? selected;
  final ValueChanged<RepairService> onSelect;

  const _ServiceStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(repairServicesProvider);
    return ListView(
      children: [
        const Text(
          'Choisissez votre service',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...services.map((service) {
          final isSelected = service.id == selected?.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: VoltronColors.cardBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.md),
              border: Border.all(
                color: isSelected
                    ? VoltronColors.electricYellow
                    : Colors.transparent,
              ),
            ),
            child: ListTile(
              onTap: () => onSelect(service),
              leading:
                  (service.imageUrl != null && service.imageUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(VoltronRadii.sm),
                      child: Image.network(
                        service.imageUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const CircleAvatar(
                      backgroundColor: VoltronColors.deepBlack,
                      child: Icon(
                        Icons.build_rounded,
                        color: VoltronColors.electricYellow,
                        size: 18,
                      ),
                    ),
              title: Text(
                service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.duration.isNotEmpty)
                    Text(
                      service.duration,
                      style: const TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 11,
                      ),
                    ),
                  if ((service.description ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        service.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VoltronColors.greyText,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Text(
                service.priceLabel,
                style: const TextStyle(
                  color: VoltronColors.electricYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ProblemStep extends ConsumerWidget {
  final TextEditingController problemController;
  final OwnedScooter? selectedScooter;
  final ValueChanged<OwnedScooter> onScooterSelected;
  final VoidCallback onDescriptionChanged;

  const _ProblemStep({
    required this.problemController,
    required this.selectedScooter,
    required this.onScooterSelected,
    required this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garage = ref.watch(garageProvider);
    return ListView(
      children: [
        const Text(
          'Expliquez votre problème',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: problemController,
          maxLines: 4,
          onChanged: (_) => onDescriptionChanged(),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Décrivez la panne ou le problème rencontré...',
            hintStyle: TextStyle(color: VoltronColors.greyText),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Quel véhicule est concerné ?',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (garage.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VoltronColors.cardBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vous n\'avez pas encore de véhicule enregistré dans votre garage.',
                  style: TextStyle(color: VoltronColors.greyText, fontSize: 13),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/account/garage'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('AJOUTER MON VÉHICULE'),
                ),
              ],
            ),
          ),
        ] else
          ...garage.map((v) {
            final isSelected = v.id == selectedScooter?.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: VoltronColors.cardBlack,
                borderRadius: BorderRadius.circular(VoltronRadii.md),
                border: Border.all(
                  color: isSelected
                      ? VoltronColors.electricYellow
                      : Colors.transparent,
                ),
              ),
              child: ListTile(
                onTap: () => onScooterSelected(v),
                leading: (v.imageUrl != null && v.imageUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(VoltronRadii.sm),
                        child: Image.network(
                          v.imageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const CircleAvatar(
                        backgroundColor: VoltronColors.deepBlack,
                        child: Icon(
                          Icons.electric_scooter_rounded,
                          color: VoltronColors.electricYellow,
                          size: 18,
                        ),
                      ),
                title: Text(
                  '${v.brand} ${v.model}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  'N° ${v.serialNumber}',
                  style: const TextStyle(
                    color: VoltronColors.greyText,
                    fontSize: 11,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: VoltronColors.electricYellow,
                      )
                    : null,
              ),
            );
          }),
      ],
    );
  }
}

class _DateTimeStep extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime? selectedDay;
  final String? selectedTime;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<String> onTimeSelected;

  const _DateTimeStep({
    required this.visibleMonth,
    required this.selectedDay,
    required this.selectedTime,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final currentMonth = DateTime(today.year, today.month);
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final firstWeekday = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    ).weekday; // 1 = Monday

    return ListView(
      children: [
        const Text(
          'Choisissez une date',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: visibleMonth.isAfter(currentMonth)
                  ? () => onMonthChanged(
                      DateTime(visibleMonth.year, visibleMonth.month - 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              color: Colors.white,
            ),
            Text(
              '${_monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            IconButton(
              onPressed: () => onMonthChanged(
                DateTime(visibleMonth.year, visibleMonth.month + 1),
              ),
              icon: const Icon(Icons.chevron_right_rounded),
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: _weekdayInitials
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: const TextStyle(
                        color: VoltronColors.greyText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: firstWeekday - 1 + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday - 1) return const SizedBox.shrink();
            final day = index - (firstWeekday - 1) + 1;
            final date = DateTime(visibleMonth.year, visibleMonth.month, day);
            final isPast = date.isBefore(todayNormalized);
            final isToday = _isSameDay(date, todayNormalized);
            final isSelected =
                selectedDay != null && _isSameDay(date, selectedDay!);
            return GestureDetector(
              onTap: isPast ? null : () => onDaySelected(date),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? VoltronColors.electricYellow
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(VoltronRadii.sm),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? VoltronColors.deepBlack
                            : isPast
                            ? VoltronColors.greyText.withValues(alpha: 0.4)
                            : Colors.white,
                      ),
                    ),
                    if (isToday && !isSelected)
                      const Positioned(
                        bottom: 4,
                        child: CircleAvatar(
                          radius: 2,
                          backgroundColor: VoltronColors.electricBlueGlow,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Heures disponibles',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _timeSlots.map((time) {
            final isSelected = time == selectedTime;
            return GestureDetector(
              onTap: () => onTimeSelected(time),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? VoltronColors.electricYellow
                      : VoltronColors.cardBlack,
                  borderRadius: BorderRadius.circular(VoltronRadii.sm),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isSelected ? VoltronColors.deepBlack : Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _InfoStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const _InfoStep({
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Vos informations',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nom complet',
            hintStyle: TextStyle(color: VoltronColors.greyText),
            prefixIcon: Icon(
              Icons.person_outline,
              color: VoltronColors.greyText,
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Téléphone',
            hintStyle: TextStyle(color: VoltronColors.greyText),
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: VoltronColors.greyText,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  final RepairService? service;
  final String problem;
  final OwnedScooter? scooter;
  final DateTime? day;
  final String? time;
  final String name;

  const _ConfirmationStep({
    required this.service,
    required this.problem,
    required this.scooter,
    required this.day,
    required this.time,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Récapitulatif',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VoltronColors.cardBlack,
            borderRadius: BorderRadius.circular(VoltronRadii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow('Service', service?.name ?? '-'),
              _SummaryRow(
                'Véhicule',
                scooter != null ? '${scooter!.brand} ${scooter!.model}' : '-',
              ),
              _SummaryRow('Problème', problem.isNotEmpty ? problem : '-'),
              _SummaryRow('Date', day != null ? _formatDay(day!) : '-'),
              _SummaryRow('Heure', time ?? '-'),
              _SummaryRow('Client', name.isNotEmpty ? name : '-'),
              _SummaryRow('Prix', service?.priceLabel ?? '-'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: VoltronColors.greyText, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
