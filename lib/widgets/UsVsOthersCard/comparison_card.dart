import 'package:flutter/material.dart';
import 'package:tds_voice_agent/model/agni_content.dart';
import 'package:tds_voice_agent/widgets/reveal_widget.dart';

class ComparisonSection extends StatelessWidget {
  final List<ComparisonCardData> comparisons;
  final bool revealed;
  final Key revealKey;

  final Widget Function(String) sectionTagBuilder;
  final Widget Function(String, String) sectionTitleBuilder;
  final Widget Function({
    required bool isOurs,
    required String badge,
    required String headline,
    required List<String> items,
  })
  compCardBuilder;

  const ComparisonSection({
    super.key,
    required this.comparisons,
    required this.revealed,
    required this.revealKey,
    required this.sectionTagBuilder,
    required this.sectionTitleBuilder,
    required this.compCardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return RevealWidget(
      key: revealKey,
      revealed: revealed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTagBuilder('The difference'),
            const SizedBox(height: 18),
            sectionTitleBuilder(
              'Everyone else is fighting\nover ',
              'the same market.',
            ),
            const SizedBox(height: 56),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (comparisons.isNotEmpty)
                  Expanded(
                    child: compCardBuilder(
                      isOurs: comparisons[0].isOurs,
                      badge: comparisons[0].badge,
                      headline: comparisons[0].headline,
                      items: comparisons[0].items,
                    ),
                  ),
                if (comparisons.length > 1) const SizedBox(width: 24),
                if (comparisons.length > 1)
                  Expanded(
                    child: compCardBuilder(
                      isOurs: comparisons[1].isOurs,
                      badge: comparisons[1].badge,
                      headline: comparisons[1].headline,
                      items: comparisons[1].items,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
