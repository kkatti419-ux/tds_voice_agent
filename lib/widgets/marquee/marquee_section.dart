import 'package:flutter/material.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/theme/app_typography.dart';
import 'package:tds_voice_agent/widgets/marquee/marquee_row.dart';

class MarqueeSection extends StatefulWidget {
  final List<String> items;
  final bool isDark;

  const MarqueeSection({super.key, required this.items, required this.isDark});

  @override
  State<MarqueeSection> createState() => _MarqueeSectionState();
}

class _MarqueeSectionState extends State<MarqueeSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _marqueeController;

  static const double _pixelsPerSecond = 60;

  @override
  void initState() {
    super.initState();

    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  Color get textPrimary =>
      widget.isDark ? AgniColors.white70 : AgniColors.black87;

  Color get textSecondary =>
      widget.isDark ? AgniColors.white54 : AgniColors.black54;

  @override
  Widget build(BuildContext context) {
    final safeItems = widget.items.isNotEmpty
        ? widget.items
        : ['Google', 'Amazon', 'Meta', 'Netflix'];

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isMobile = viewportWidth < 600;

    final textStyle = AppTypography.displaySmall(color: textPrimary);

    final cycleWidth = measureMarqueeCycleWidth(context, safeItems, textStyle);

    /// Dynamically repeat items based on screen width
    final repeats = (viewportWidth / cycleWidth).ceil() + 3;

    final repeatedItems = [for (int i = 0; i < repeats; i++) ...safeItems];

    final borderColor = widget.isDark
        ? AgniColors.oceanBright.withOpacity(0.15)
        : const Color(0xFF1A4A6B).withOpacity(0.10);

    final backgroundColor = widget.isDark
        ? const Color(0xFF050F20).withOpacity(0.65)
        : AgniColors.white.withOpacity(0.65);

    final marqueeBandHeight = isMobile ? 50.0 : 62.0;
    final verticalPadding = isMobile ? 32.0 : 48.0;
    final headerFontSize = isMobile ? 10.0 : 12.0;

    /// Sync animation speed with actual width
    final durationMs = (cycleWidth / _pixelsPerSecond * 1000).round();

    _marqueeController.duration = Duration(
      milliseconds: durationMs.clamp(8000, 120000),
    );

    if (!_marqueeController.isAnimating) {
      _marqueeController.repeat();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.symmetric(
          horizontal: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: AlignmentGeometry.center,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'TRUSTED BY 2,100+ BUSINESSES ACROSS 12 COUNTRIES',
                textAlign: TextAlign.center, // 🔥 important
                style: TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.08, 0.92, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: marqueeBandHeight,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _marqueeController,
                builder: (_, _) {
                  return MarqueeRow(
                    items: repeatedItems,
                    cycleLength: safeItems.length,
                    progress: _marqueeController.value,
                    textStyle: textStyle,
                    dividerColor: borderColor,
                    cycleWidth: cycleWidth,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
