import 'package:flutter/material.dart';
import 'package:tds_voice_agent/widgets/marquee_row.dart';

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
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  Color get text2Color => widget.isDark ? Colors.white70 : Colors.black87;

  Color get text3Color => widget.isDark ? Colors.white54 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    final safeItems = widget.items.isNotEmpty
        ? widget.items
        : ["Google", "Amazon", "Meta", "Netflix"];

    final doubled = [...safeItems, ...safeItems];

    final borderColor = widget.isDark
        ? Colors.blue.withOpacity(0.12)
        : const Color(0xFF1A4A6B).withOpacity(0.10);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF050F20).withOpacity(0.70)
            : Colors.white.withOpacity(0.55),
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
              letterSpacing: 1.5,
              color: text3Color,
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 41,
            child: AnimatedBuilder(
              animation: _marqueeController,
              builder: (_, __) {
                return MarqueeRow(
                  items: doubled,
                  progress: _marqueeController.value,
                  textStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: text2Color,
                  ),
                  dividerColor: borderColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
