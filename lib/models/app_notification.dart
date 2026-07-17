import 'package:flutter/material.dart';

enum NotificationType { repair, order, loyalty, promo, reminder }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime date;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    this.read = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.repair:
        return Icons.build_rounded;
      case NotificationType.order:
        return Icons.shopping_bag_rounded;
      case NotificationType.loyalty:
        return Icons.star_rounded;
      case NotificationType.promo:
        return Icons.local_offer_rounded;
      case NotificationType.reminder:
        return Icons.notifications_active_rounded;
    }
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      date: date,
      read: read ?? this.read,
    );
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: NotificationType.values.byName(map['type'] as String),
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      date: DateTime.parse(map['created_at'] as String),
      read: map['read'] as bool? ?? false,
    );
  }
}
