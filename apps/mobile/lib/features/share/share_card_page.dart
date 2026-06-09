import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glow_button.dart';
import 'share_service.dart';

/// Everything needed to render a shareable card.
class ShareCardSpec {
  const ShareCardSpec({
    required this.icon,
    required this.headline,
    required this.title,
    required this.subtitle,
    this.accent = AppColors.primary,
    this.stats = const [],
    this.shareText = 'Tracking my habits with Aura Habits ✨',
  });

  final IconData icon;
  final String headline; // big focal line, e.g. "12-day streak"
  final String title; // e.g. habit / achievement name
  final String subtitle; // context line
  final Color accent;
  final List<({String label, String value})> stats;
  final String shareText;
}

/// A full-screen preview of a branded share card with a Share button. Captures
/// the card (a [RepaintBoundary]) to a PNG and opens the system share sheet.
class ShareCardPage extends StatefulWidget {
  const ShareCardPage({super.key, required this.spec});

  final ShareCardSpec spec;

  static Future<void> open(BuildContext context, ShareCardSpec spec) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShareCardPage(spec: spec)),
    );
  }

  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await ShareService.shareBoundary(_boundaryKey, text: widget.spec.shareText);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Share'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: _AuraShareCard(spec: widget.spec),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GlowButton(
                label: 'Share',
                icon: Icons.ios_share_rounded,
                expand: true,
                busy: _sharing,
                onPressed: _sharing ? null : _share,
              ),
              const SizedBox(height: 8),
              Text('Shares a high-res image to any app',
                  style: TextStyle(color: AppColors.faint, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuraShareCard extends StatelessWidget {
  const _AuraShareCard({required this.spec});
  final ShareCardSpec spec;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF141421), Color(0xFF0A0A0A)],
          ),
        ),
        child: Stack(
          children: [
            // Accent glow blobs.
            Positioned(
                top: -40,
                right: -30,
                child: _glow(spec.accent, 200)),
            Positioned(
                bottom: -50,
                left: -40,
                child: _glow(AppColors.secondary, 220)),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand row.
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: Color(0xFF002417), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Aura Habits',
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Spacer(),
                  // Focal icon.
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.alpha(spec.accent, 0.16),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: AppColors.alpha(spec.accent, 0.4)),
                    ),
                    child: Icon(spec.icon, color: spec.accent, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    spec.headline,
                    style: AppTypography.numeric(40, color: AppColors.text)
                        .copyWith(height: 1.05),
                  ),
                  const SizedBox(height: 6),
                  Text(spec.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(spec.subtitle,
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 14)),
                  if (spec.stats.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        for (final s in spec.stats) _stat(s.label, s.value),
                      ],
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Build habits that actually stick',
                          style: TextStyle(
                              color: AppColors.faint, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.numeric(22)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [AppColors.alpha(color, 0.22), Colors.transparent]),
        ),
      );
}
