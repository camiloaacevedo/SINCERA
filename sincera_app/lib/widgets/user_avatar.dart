import 'package:flutter/material.dart';
import '../theme.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final double iconSize;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.radius = 20, // Tamaño pequeño por defecto para listas
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    bool hasImage =
        avatarUrl != null &&
        avatarUrl!.isNotEmpty &&
        avatarUrl!.startsWith('http');

    return CircleAvatar(
      radius: radius,
      backgroundColor: SinceraTheme.accentNeon,
      backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
      child: !hasImage
          ? Icon(Icons.person, size: iconSize, color: Colors.black)
          : null,
    );
  }
}
