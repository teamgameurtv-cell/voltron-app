import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/voltron_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
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
                child: Text('Aucune notification.', style: TextStyle(color: VoltronColors.greyText)),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VoltronColors.cardBlack,
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                      border: Border.all(
                        color: n.read ? Colors.transparent : VoltronColors.electricYellow.withValues(alpha: 0.4),
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
                            borderRadius: BorderRadius.circular(VoltronRadii.sm),
                          ),
                          child: Icon(n.icon, color: VoltronColors.electricYellow, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(n.body, style: const TextStyle(color: VoltronColors.greyText, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(_formatDate(n.date),
                                  style: const TextStyle(color: VoltronColors.greyText, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
