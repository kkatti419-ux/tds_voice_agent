import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';

class ComparisonCard extends StatelessWidget {
  final bool isOurs;
  final String badge;
  final String headline;
  final List<String> items;
  final bool isDark;
  final Color textColor;
  final Color text2Color;
  final Color text3Color;

  const ComparisonCard({
    super.key,
    required this.isOurs,
    required this.badge,
    required this.headline,
    required this.items,
    required this.isDark,
    required this.textColor,
    required this.text2Color,
    required this.text3Color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final compact = cardWidth < 560;
        final dense = cardWidth < 440;
        final pad = dense ? 18.0 : (compact ? 24.0 : 36.0);

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: isOurs
                ? (isDark ? const Color(0xFF071828) : AgniColors.lightOceanDeep)
                : (isDark
                    ? const Color(0xFF08141E).withOpacity(0.65)
                    : AgniColors.white.withOpacity(0.55)),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isOurs
                  ? AgniColors.oceanBright.withOpacity(0.22)
                  : (isDark
                      ? AgniColors.white.withOpacity(0.05)
                      : AgniColors.white.withOpacity(0.80)),
            ),
            boxShadow: isOurs
                ? [
                    BoxShadow(
                      color: AgniColors.oceanBright.withOpacity(
                        isDark ? 0.20 : 0.10,
                      ),
                      blurRadius: 80,
                      offset: const Offset(0, 24),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              if (isOurs) _buildGlowBackground(),
              _buildContent(compact: compact, dense: dense),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: RadialGradient(
            center: const Alignment(0.5, -0.5),
            radius: 1.1,
            colors: [
              AgniColors.oceanBright.withOpacity(0.18),
              AgniColors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent({required bool compact, required bool dense}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBadge(compact: compact),
        SizedBox(height: dense ? 14 : (compact ? 18 : 24)),
        _buildHeadline(compact: compact, dense: dense),
        SizedBox(height: dense ? 14 : (compact ? 18 : 24)),
        ...items.map((item) => _buildItem(item, compact: compact, dense: dense)),
      ],
    );
  }

  Widget _buildBadge({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        gradient: isOurs ? AgniColors.grad : null,
        color: isOurs
            ? null
            : (isDark
                  ? AgniColors.white.withOpacity(0.05)
                  : AgniColors.oceanMid.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(100),
        border: isOurs
            ? null
            : Border.all(
                color: isDark
                    ? AgniColors.white.withOpacity(0.10)
                    : AgniColors.oceanMid.withOpacity(0.12),
              ),
        boxShadow: isOurs
            ? [
                BoxShadow(
                  color: AgniColors.oceanBright.withOpacity(0.30),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: Text(
        badge,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: compact ? 0.04 * 11 : 0.06 * 12,
          color: isOurs ? AgniColors.white : text3Color,
        ),
      ),
    );
  }

  Widget _buildHeadline({required bool compact, required bool dense}) {
    return Text(
      headline,
      style: GoogleFonts.playfairDisplay(
        fontSize: dense ? 19.5 : (compact ? 21.5 : 24.8),
        fontWeight: FontWeight.w700,
        height: dense ? 1.2 : 1.25,
        color: isOurs ? AgniColors.white.withOpacity(0.90) : textColor,
      ),
    );
  }

  Widget _buildItem(String item, {required bool compact, required bool dense}) {
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 10 : (compact ? 12 : 16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(compact: compact),
          SizedBox(width: compact ? 10 : 12),
          Expanded(child: _buildItemText(item, compact: compact, dense: dense)),
        ],
      ),
    );
  }

  Widget _buildIcon({required bool compact}) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        isOurs ? '✓' : '✕',
        style: TextStyle(
          fontSize: compact ? 12 : 12.8,
          color: isOurs
              ? AgniColors.forestBright
              : (isDark ? const Color(0xFF334455) : const Color(0xFFBBBBBB)),
          fontWeight: FontWeight.w700,
          shadows: isOurs && isDark
              ? [
                  Shadow(
                    color: AgniColors.forestBright.withOpacity(0.60),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildItemText(
    String item, {
    required bool compact,
    required bool dense,
  }) {
    return Text(
      item,
      style: TextStyle(
        fontSize: dense ? 13.4 : (compact ? 14.2 : 15.2),
        height: dense ? 1.35 : 1.45,
        color: isOurs
            ? AgniColors.white.withOpacity(0.85)
            : (isDark ? text2Color.withOpacity(0.75) : AgniColors.lightText2),
      ),
    );
  }
}
