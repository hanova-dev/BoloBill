import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_color_tokens.dart';

/// Photo-first customer identity (FR-3.4.4) — shows the saved profile photo
/// when present, otherwise a colored initial. Used across the khata module
/// (C1 picker, C2 creation preview, C3 detail header, C5 list) so a
/// customer's visual identity stays consistent everywhere they appear.
class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.radius = 24,
  });

  final String name;
  final String? photoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;

    if (photoPath != null && photoPath!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colors.tint,
        backgroundImage: FileImage(File(photoPath!)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.secondary,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: radius * 0.75, fontWeight: FontWeight.w600),
      ),
    );
  }
}
