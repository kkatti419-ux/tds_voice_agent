import 'package:flutter/material.dart';
import 'package:tds_voice_agent/domain/entities/agni_content.dart';
import 'package:tds_voice_agent/widgets/UsVsOthersCard/comparison_card_items.dart';

class ComparisonsSection extends StatelessWidget {
  final List<ComparisonCardData> comparisons;
  final bool isDark;
  final Color textColor;
  final Color text2Color;
  final Color text3Color;

  const ComparisonsSection({
    super.key,
    required this.comparisons,
    required this.isDark,
    required this.textColor,
    required this.text2Color,
    required this.text3Color,
  });

  @override
  Widget build(BuildContext context) {
    if (comparisons.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Column(
              children: comparisons.map((comp) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ComparisonCard(
                  isOurs: comp.isOurs,
                  badge: comp.badge,
                  headline: comp.headline,
                  items: comp.items,
                  isDark: isDark,
                  textColor: textColor,
                  text2Color: text2Color,
                  text3Color: text3Color,
                ),
              )).toList(),
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: comparisons.map((comp) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: comp == comparisons.first ? 12 : 0,
                    left: comp != comparisons.first ? 12 : 0,
                  ),
                  child: ComparisonCard(
                    isOurs: comp.isOurs,
                    badge: comp.badge,
                    headline: comp.headline,
                    items: comp.items,
                    isDark: isDark,
                    textColor: textColor,
                    text2Color: text2Color,
                    text3Color: text3Color,
                  ),
                ),
              )).toList(),
            );
          }
        },
      ),
    );
  }
}
