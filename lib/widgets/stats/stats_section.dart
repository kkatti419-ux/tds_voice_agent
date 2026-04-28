import 'package:flutter/material.dart';
import 'package:tds_voice_agent/model/agni_content.dart';
import 'package:tds_voice_agent/widgets/marquee/stat_card.dart';

class StatsSection extends StatelessWidget {
  final List<StatItem> stats;
  final bool isDark;

  const StatsSection({super.key, required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: stats
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: StatCard(
                        value: s.value,
                        description: s.description,
                        isDark: isDark,
                      ),
                    ),
                  )
                  .toList(),
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stats
                  .map(
                    (s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: StatCard(
                          value: s.value,
                          description: s.description,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }
        },
      ),
    );
  }
}
