import 'package:flutter/material.dart';

/// Horizontal padding per label (`symmetric(50)` → 100 total per segment).
const double kMarqueeSegmentPadding = 100;
const double kMarqueeDividerWidth = 3;

/// Width of one repeating segment [segment] (padding + text + dividers per item).
/// Uses [context] so widths match scaled [Text] (accessibility text scale).
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
    total += tp.width + kMarqueeSegmentPadding + kMarqueeDividerWidth;
  }
  return total;
}

/// Horizontal marquee: [items] must be an integer number of [cycleLength] copies
/// of the same pattern (for seamless loop). Offset moves by one pattern width per period.
///
/// Pass [cycleWidth] from the parent (same value used for duration math) so translation
/// stays aligned with the measured strip width.
class MarqueeRow extends StatelessWidget {
  final List<String> items;
  /// Length of one repeating unit (e.g. original brand list length).
  final int cycleLength;
  final double progress;
  final TextStyle textStyle;
  final Color dividerColor;

  /// Pixel width of one full cycle; falls back to measuring if omitted.
  final double? cycleWidth;

  const MarqueeRow({
    super.key,
    required this.items,
    required this.cycleLength,
    required this.progress,
    required this.textStyle,
    required this.dividerColor,
    this.cycleWidth,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      cycleLength > 0 && items.length % cycleLength == 0,
      'items length must be a multiple of cycleLength',
    );

    final cycleSegment = items.sublist(0, cycleLength);
    final cw = cycleWidth ??
        measureMarqueeCycleWidth(context, cycleSegment, textStyle);
    final offset = -progress * cw;

    return ClipRect(
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          clipBehavior: Clip.hardEdge,
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
                      overflow: TextOverflow.visible,
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
