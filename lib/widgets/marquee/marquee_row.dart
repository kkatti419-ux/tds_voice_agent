import 'package:flutter/material.dart';

/// Horizontal padding per label (left + right = 100 total)
const double kMarqueeSegmentPadding = 100;

/// Divider width between items
const double kMarqueeDividerWidth = 3;

/// Measures pixel width of ONE full repeating cycle
/// (used for animation distance + duration sync)
double measureMarqueeCycleWidth(
  BuildContext context,
  List<String> segment,
  TextStyle textStyle,
) {
  if (segment.isEmpty) return 1;

  final tp = TextPainter(
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
  );

  double total = 0;

  for (final item in segment) {
    tp.text = TextSpan(text: item, style: textStyle);
    tp.layout();

    total += tp.width;
    total += kMarqueeSegmentPadding;
    total += kMarqueeDividerWidth;
  }

  return total;
}

/// Infinite seamless marquee row
class MarqueeRow extends StatelessWidget {
  final List<String> items;
  final int cycleLength;
  final double progress;
  final TextStyle textStyle;
  final Color dividerColor;
  final double cycleWidth;

  const MarqueeRow({
    super.key,
    required this.items,
    required this.cycleLength,
    required this.progress,
    required this.textStyle,
    required this.dividerColor,
    required this.cycleWidth,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      cycleLength > 0 && items.length % cycleLength == 0,
      'items length must be multiple of cycleLength',
    );

    final offset = -(progress * cycleWidth);

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        minWidth: 0,
        maxWidth: double.infinity,
        child: Transform.translate(
          offset: Offset(offset, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items.map((label) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      label,
                      style: textStyle,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  Container(
                    height: 30,
                    width: kMarqueeDividerWidth,
                    color: dividerColor,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
