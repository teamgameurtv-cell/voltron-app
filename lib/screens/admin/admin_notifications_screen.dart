import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/admin_notification.dart';
import '../../providers/admin_notifications_provider.dart';
import '../../theme/voltron_theme.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminNotificationsProvider.notifier).markAllRead();
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
    final notifications = ref.watch(adminNotificationsProvider);

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
                  final AdminNotification n = notifications[index];
                  return Material(
                    color: VoltronColors.cardBlack,
                    borderRadius: BorderRadius.circular(VoltronRadii.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(VoltronRadii.md),
                      onTap: n.orderId == null
                          ? null
                          : () => context.push('/admin/repairs/${n.orderId}'),
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
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: VoltronColors.deepBlack,
                                borderRadius: BorderRadius.circular(
                                  VoltronRadii.sm,
                                ),
                              ),
                              child: const Icon(
                                Icons.euro_rounded,
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
                                    _formatDate(n.createdAt),
                                    style: const TextStyle(
                                      color: VoltronColors.greyText,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (n.orderId != null)
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
