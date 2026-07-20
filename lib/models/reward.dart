import 'package:flutter/material.dart';

const Map<String, IconData> rewardIconRegistry = {
  'local_offer': Icons.local_offer_rounded,
  'hourglass_bottom': Icons.hourglass_bottom_rounded,
  'lock_open': Icons.lock_open_rounded,
  'card_giftcard': Icons.card_giftcard_rounded,
  'star': Icons.star_rounded,
};

IconData iconForRewardName(String name) => rewardIconRegistry[name] ?? Icons.card_giftcard_rounded;

class Reward {
  final String id;
  final String label;
  final int points;
  final IconData icon;

  const Reward({
    required this.id,
    required this.label,
    required this.points,
    required this.icon,
  });

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] as String,
      label: map['label'] as String,
      points: map['points'] as int,
      icon: iconForRewardName(map['icon_name'] as String? ?? 'card_giftcard'),
    );
  }
}

class RewardRedemption {
  final String id;
  final String code;
  final String rewardLabel;
  final int pointsSpent;
  final DateTime redeemedAt;

  const RewardRedemption({
    required this.id,
    required this.code,
    required this.rewardLabel,
    required this.pointsSpent,
    required this.redeemedAt,
  });

  factory RewardRedemption.fromMap(Map<String, dynamic> map) {
    return RewardRedemption(
      id: map['id'] as String,
      code: map['code'] as String,
      rewardLabel: map['reward_label'] as String,
      pointsSpent: map['points_spent'] as int,
      redeemedAt: DateTime.parse(map['redeemed_at'] as String),
    );
  }
}

class CarePlan {
  final String id;
  final String name;
  final double monthlyPrice;
  final List<String> features;
  final bool recommended;

  const CarePlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.features,
    this.recommended = false,
  });
}
