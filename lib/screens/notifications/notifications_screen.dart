import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/voltron_theme.dart';

/// Route vers laquelle une notification renvoie quand on tape dessus. [order]
/// couvre à la fois les réservations (rendez-vous) et les achats boutique : on
/// distingue via le titre, fixé par le code qui l'a créée, plutôt que d'ajouter
/// un sous-type qui complexifierait le modèle pour un seul cas d'usage.
String? _routeForNotification(AppNotification n) {
  switch (n.type) {
    case NotificationType.repair:
      return '/repairs';
    case NotificationType.order:
      final title = n.title.toLowerCase();
      if (title.contains('rendez-vous') || title.contains('créneau')) {
        return '/repairs';
      }
      return '/account/invoices';
    case NotificationType.loyalty:
      return '/loyalty';
    case NotificationType.promo:
      return '/shop';
    case NotificationType.reminder:
      return '/account/garage';
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(visibleNotificationsProvider);

    return Scaffold(
      backgroundColor: VoltronColors.deepBlack,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('NOTIFICATIONS'),
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? const Center(
                child: Text(
                  'Aucune notification.',
                  style: TextStyle(color: VoltronColors.greyText),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final route = _routeForNotification(n);
                  return Material(
                    color: VoltronColors.cardBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                      onTap: route == null
                          ? null
                          : () {
                              if (!n.read) {
                                ref
                                    .read(notificationsProvider.notifier)
                                    .markRead(n.id);
                              }
                              context.push(route);
                            },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(VoltronRadii.md),
                          border: Border.all(
                            color: n.read
                                ? Colors.transparent
                                : VoltronColors.electricYellow.withValues(
                                    alpha: 0.4,
                                  ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: VoltronColors.deepBlack,
                                borderRadius: BorderRadius.circular(
                                  VoltronRadii.sm,
                                ),
                              ),
                              child: Icon(
                                n.icon,
                                color: VoltronColors.electricYellow,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.body,
                                    style: const TextStyle(
                                      color: VoltronColors.greyText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(n.date),
                                    style: const TextStyle(
                                      color: VoltronColors.greyText,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (route != null)
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: VoltronColors.greyText,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
