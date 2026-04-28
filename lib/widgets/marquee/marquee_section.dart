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

    // Two copies of the list for seamless looping.
    final doubled = [...safeItems, ...safeItems];

    final borderColor = widget.isDark
        ? AgniColors.oceanBright.withOpacity(0.15)
        : const Color(0xFF1A4A6B).withOpacity(0.10);

    final backgroundColor = widget.isDark
        ? const Color(0xFF050F20).withOpacity(0.65)
        : AgniColors.white.withOpacity(0.65);

    final textStyle =
        AppTypography.displaySmall(color: textPrimary).copyWith();

    final cycleW = measureMarqueeCycleWidth(context, safeItems, textStyle);

    /// displaySmall line height ~44; slack for dividers.
    const double marqueeBandHeight = 62;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.symmetric(
          horizontal: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Text(
            'TRUSTED BY 2,100+ BUSINESSES ACROSS 12 COUNTRIES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                colors: [
                  AgniColors.transparent,
                  AgniColors.black,
                  AgniColors.black,
                  AgniColors.transparent,
                ],
                stops: const [0.0, 0.08, 0.92, 1.0],
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
                builder: (_, __) {
                  return MarqueeRow(
                    items: doubled,
                    cycleLength: safeItems.length,
                    cycleWidth: cycleW,
                    progress: _marqueeController.value,
                    textStyle: textStyle,
                    dividerColor: borderColor,
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
