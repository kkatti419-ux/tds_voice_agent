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
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: isOurs
            ? (isDark ? const Color(0xFF071828) : AgniColors.lightOceanDeep)
            : (isDark
                  ? const Color(0xFF08141E).withOpacity(0.65)
                  : Colors.white.withOpacity(0.55)),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isOurs
              ? AgniColors.oceanBright.withOpacity(0.22)
              : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.80)),
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
        children: [if (isOurs) _buildGlowBackground(), _buildContent()],
      ),
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
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBadge(),
        const SizedBox(height: 28),
        _buildHeadline(),
        const SizedBox(height: 28),
        ...items.map(_buildItem),
      ],
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: isOurs ? AgniColors.grad : null,
        color: isOurs
            ? null
            : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : AgniColors.oceanMid.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(100),
        border: isOurs
            ? null
            : Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06 * 12,
          color: isOurs ? Colors.white : text3Color,
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return Text(
      headline,
      style: GoogleFonts.playfairDisplay(
        fontSize: 24.8,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: isOurs ? Colors.white.withOpacity(0.90) : textColor,
      ),
    );
  }

  Widget _buildItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Expanded(child: _buildItemText(item)),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        isOurs ? '✓' : '✕',
        style: TextStyle(
          fontSize: 12.8,
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

  Widget _buildItemText(String item) {
    return Text(
      item,
      style: TextStyle(
        fontSize: 15.2,
        height: 1.5,
        color: isOurs
            ? Colors.white.withOpacity(0.85)
            : (isDark ? text2Color.withOpacity(0.75) : AgniColors.lightText2),
      ),
    );
  }
}
