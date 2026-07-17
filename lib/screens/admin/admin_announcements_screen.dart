import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/voltron_theme.dart';
import 'admin_shell.dart';

class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends ConsumerState<AdminAnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  NotificationType _type = NotificationType.promo;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sent = ref.watch(notificationsProvider).where((n) => n.type == NotificationType.promo).toList();

    return AdminShell(
      selected: AdminSection.announcements,
      title: 'ANNONCES',
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VoltronColors.cardBlack,
              borderRadius: BorderRadius.circular(VoltronRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Envoyer une notification à tous les clients',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 14),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'Titre (ex: -15% sur les pneus)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Message'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<NotificationType>(
                  value: _type,
                  dropdownColor: VoltronColors.cardBlack,
                  items: const [
                    DropdownMenuItem(value: NotificationType.promo, child: Text('Promotion')),
                    DropdownMenuItem(value: NotificationType.loyalty, child: Text('Fidélité')),
                    DropdownMenuItem(value: NotificationType.reminder, child: Text('Rappel')),
                  ],
                  onChanged: (t) => setState(() => _type = t ?? NotificationType.promo),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_titleController.text.trim().isEmpty) return;
                    ref.read(notificationsProvider.notifier).broadcast(
                          type: _type,
                          title: _titleController.text.trim(),
                          body: _bodyController.text.trim(),
                        );
                    _titleController.clear();
                    _bodyController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification envoyée à tous les clients')),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('ENVOYER'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('ANNONCES ENVOYÉES',
              style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: VoltronColors.greyText)),
          const SizedBox(height: 12),
          if (sent.isEmpty)
            const Text('Aucune annonce envoyée pour le moment.', style: TextStyle(color: VoltronColors.greyText, fontSize: 12)),
          ...sent.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: VoltronColors.cardBlack, borderRadius: BorderRadius.circular(VoltronRadii.md)),
                child: Row(
                  children: [
                    Icon(n.icon, size: 16, color: VoltronColors.electricYellow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (n.body.isNotEmpty)
                            Text(n.body, style: const TextStyle(color: VoltronColors.greyText, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
