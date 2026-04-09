import 'package:flutter/material.dart';

class MarqueeRow extends StatefulWidget {
  final List<String> items;
  final double progress;
  final TextStyle textStyle;
  final Color dividerColor;

  const MarqueeRow({
    required this.items,
    required this.progress,
    required this.textStyle,
    required this.dividerColor,
  });

  @override
  State<MarqueeRow> createState() => _MarqueeRowState();
}

class _MarqueeRowState extends State<MarqueeRow> {
  @override
  Widget build(BuildContext context) {
    // Estimate item width from text metrics + padding
    // padding:10px 36px = 72px horizontal padding per item
    // We use TextPainter to measure each label
    final tp = TextPainter(textDirection: TextDirection.ltr);
    double totalHalfWidth = 0;
    for (int i = 0; i < widget.items.length ~/ 2; i++) {
      tp.text = TextSpan(text: widget.items[i], style: widget.textStyle);
      tp.layout();
      totalHalfWidth += tp.width + 72 + 1; // text + horizontal padding + border
    }

    // CSS: translateX(-50%) of the 20-item total = -totalHalfWidth
    final offset = -(widget.progress * totalHalfWidth);

    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Transform.translate(
          offset: Offset(offset, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: widget.items
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: widget.dividerColor, width: 1),
                      ),
                    ),
                    child: Text(label, style: widget.textStyle),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
