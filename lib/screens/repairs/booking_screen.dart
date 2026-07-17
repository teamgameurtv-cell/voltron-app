import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/mock_repairs.dart';
import '../../models/repair.dart';
import '../../providers/account_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../theme/voltron_theme.dart';

const List<String> _stepLabels = ['Service', 'Date & heure', 'Vos informations', 'Confirmation'];
const List<String> _timeSlots = ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'];

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0;
  RepairService? _service;
  int? _selectedDay;
  String? _selectedTime;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _prefilledFromProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _service != null;
      case 1:
        return _selectedDay != null && _selectedTime != null;
      case 2:
        return _nameController.text.trim().isNotEmpty && _phoneController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      await ref.read(bookingsProvider.notifier).add(
            serviceName: _service?.name ?? '-',
            clientName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Client',
            day: _selectedDay != null ? 'Juin $_selectedDay' : '-',
            time: _selectedTime ?? '-',
          );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous confirmé !')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (!_prefilledFromProfile && (profile.name.isNotEmpty || profile.phone.isNotEmpty)) {
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
                child: Text(_step == 3 ? 'CONFIRMER' : 'CONTINUER'),
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
        return _DateTimeStep(
          selectedDay: _selectedDay,
          selectedTime: _selectedTime,
          onDaySelected: (d) => setState(() => _selectedDay = d),
          onTimeSelected: (t) => setState(() => _selectedTime = t),
        );
      case 2:
        return _InfoStep(nameController: _nameController, phoneController: _phoneController);
      default:
        return _ConfirmationStep(
          service: _service,
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
                  backgroundColor: active || done ? VoltronColors.electricYellow : VoltronColors.cardBlack,
                  child: done && !active
                      ? const Icon(Icons.check_rounded, color: VoltronColors.deepBlack, size: 16)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: active || done ? VoltronColors.deepBlack : VoltronColors.greyText,
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
                    color: active ? VoltronColors.electricYellow : VoltronColors.greyText,
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

class _ServiceStep extends StatelessWidget {
  final RepairService? selected;
  final ValueChanged<RepairService> onSelect;

  const _ServiceStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Choisissez votre service',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...mockRepairServices.map((service) {
          final isSelected = service.id == selected?.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: VoltronColors.cardBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.md),
              border: Border.all(color: isSelected ? VoltronColors.electricYellow : Colors.transparent),
            ),
            child: ListTile(
              onTap: () => onSelect(service),
              title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              subtitle: service.duration.isNotEmpty
                  ? Text(service.duration, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11))
                  : null,
              trailing: Text(service.priceLabel,
                  style: const TextStyle(color: VoltronColors.electricYellow, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          );
        }),
      ],
    );
  }
}

class _DateTimeStep extends StatelessWidget {
  final int? selectedDay;
  final String? selectedTime;
  final ValueChanged<int> onDaySelected;
  final ValueChanged<String> onTimeSelected;

  const _DateTimeStep({
    required this.selectedDay,
    required this.selectedTime,
    required this.onDaySelected,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Choisissez une date',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 30,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = index + 1;
              final isSelected = day == selectedDay;
              return GestureDetector(
                onTap: () => onDaySelected(day),
                child: Container(
                  width: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? VoltronColors.electricYellow : VoltronColors.cardBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.sm),
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? VoltronColors.deepBlack : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text('Heures disponibles',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _timeSlots.map((time) {
            final isSelected = time == selectedTime;
            return GestureDetector(
              onTap: () => onTimeSelected(time),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? VoltronColors.electricYellow : VoltronColors.cardBlack,
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

  const _InfoStep({required this.nameController, required this.phoneController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Vos informations',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nom complet',
            hintStyle: TextStyle(color: VoltronColors.greyText),
            prefixIcon: Icon(Icons.person_outline, color: VoltronColors.greyText),
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
            prefixIcon: Icon(Icons.phone_outlined, color: VoltronColors.greyText),
          ),
        ),
      ],
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  final RepairService? service;
  final int? day;
  final String? time;
  final String name;

  const _ConfirmationStep({
    required this.service,
    required this.day,
    required this.time,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Récapitulatif',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
              _SummaryRow('Date', day != null ? 'Juin ${day.toString()}' : '-'),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: VoltronColors.greyText, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
