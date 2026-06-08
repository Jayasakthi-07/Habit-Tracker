import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../auth_provider.dart';

/// Displays the user's Google profile photo when available, falling back to a
/// gradient badge with their initials (e.g. for guest/offline sessions or if
/// the avatar fails to load).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 36, this.radius = 10});

  final UserProfile? user;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = user?.photoUrl ?? '';
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        user?.initials ?? 'U',
        style: TextStyle(
          color: const Color(0xFF002417),
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
