import 'package:flutter/material.dart';
import '../theme/voltron_theme.dart';

/// Affiche la photo de profil du client si elle existe, sinon une icône par défaut.
class ClientAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final IconData icon;

  const ClientAvatar({super.key, this.avatarUrl, this.radius = 20, this.icon = Icons.person});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: VoltronColors.cardBlack,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: VoltronColors.cardBlack,
      child: Icon(icon, color: VoltronColors.greyText, size: radius),
    );
  }
}
