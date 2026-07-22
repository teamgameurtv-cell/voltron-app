import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../providers/bookings_provider.dart';
import '../theme/voltron_theme.dart';

/// Carte d'une réservation côté client. Si elle est en attente d'une réponse
/// à une reprogrammation ([BookingStatus.rescheduled]), met en avant le
/// nouveau créneau proposé avec des boutons Accepter/Refuser ; sinon affiche
/// simplement son statut.
class ClientBookingCard extends ConsumerStatefulWidget {
  final Booking booking;

  const ClientBookingCard({super.key, required this.booking});

  @override
  ConsumerState<ClientBookingCard> createState() => _ClientBookingCardState();
}

class _ClientBookingCardState extends ConsumerState<ClientBookingCard> {
  bool _responding = false;

  Future<void> _respond(bool accept) async {
    setState(() => _responding = true);
    try {
      await ref
          .read(bookingsProvider.notifier)
          .respondToReschedule(widget.booking.id, accept);
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  Future<void> _editProblem() async {
    final controller = TextEditingController(
      text: widget.booking.problemDescription,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: VoltronColors.cardBlack,
        title: const Text('Décris ton problème'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Ex : bruit anormal à l\'accélération...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref
        .read(bookingsProvider.notifier)
        .updateProblemDescription(widget.booking.id, result);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final needsResponse = booking.status == BookingStatus.rescheduled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VoltronColors.cardBlack,
        borderRadius: BorderRadius.circular(VoltronRadii.md),
        border: needsResponse
            ? Border.all(
                color: VoltronColors.electricBlueGlow.withValues(alpha: 0.6),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.event_rounded,
                size: 15,
                color: VoltronColors.greyText,
              ),
              const SizedBox(width: 6),
              Text(
                '${booking.day} à ${booking.time}',
                style: const TextStyle(
                  color: VoltronColors.greyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (booking.scooterName.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                booking.scooterName,
                style: const TextStyle(
                  color: VoltronColors.electricBlueGlow,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (booking.status != BookingStatus.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(VoltronRadii.sm),
                onTap: _editProblem,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: booking.problemDescription.trim().isEmpty
                          ? VoltronColors.electricYellow
                          : VoltronColors.greyText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.problemDescription.trim().isEmpty
                            ? 'Décrire ton problème'
                            : booking.problemDescription,
                        style: TextStyle(
                          color: booking.problemDescription.trim().isEmpty
                              ? VoltronColors.electricYellow
                              : VoltronColors.greyText,
                          fontSize: 12,
                          fontStyle: booking.problemDescription.trim().isEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (needsResponse) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VoltronColors.electricBlueGlow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(VoltronRadii.sm),
              ),
              child: const Text(
                'Le magasin te propose ce nouveau créneau. Merci de confirmer si ça te convient.',
                style: TextStyle(
                  color: VoltronColors.greyText,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _responding ? null : () => _respond(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF5C5C),
                      side: const BorderSide(color: Color(0xFFFF5C5C)),
                    ),
                    child: const Text('REFUSER'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _responding ? null : () => _respond(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VoltronColors.success,
                    ),
                    child: _responding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ACCEPTER'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.confirmed => VoltronColors.success,
      BookingStatus.pending => VoltronColors.warning,
      BookingStatus.cancelled => const Color(0xFFFF5C5C),
      BookingStatus.rescheduled => VoltronColors.electricBlueGlow,
    };
    final label = switch (status) {
      BookingStatus.confirmed => 'Confirmé',
      BookingStatus.pending => 'En attente',
      BookingStatus.cancelled => 'Annulé',
      BookingStatus.rescheduled => 'À confirmer',
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
