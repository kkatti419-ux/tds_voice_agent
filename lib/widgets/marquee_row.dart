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
  final screenWidth = MediaQuery.of(context).size.width;

  final tp = TextPainter(textDirection: TextDirection.ltr);
  double totalWidth = 0;

  for (final item in widget.items) {
    tp.text = TextSpan(text: item, style: widget.textStyle);
    tp.layout();
    totalWidth += tp.width + 72 + 1;
  }

  // Start from right edge and move fully left
  final offset = screenWidth - (widget.progress * (screenWidth + totalWidth));

  return ClipRect(
    child: 
    Transform.translate(
      offset: Offset(offset, -3),
      child: 
      Row(
        mainAxisSize: MainAxisSize.min,
        children: 
        widget.items.map((label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(label, style: widget.textStyle),
      ),
      Container(
        height: 30,
        width: 3,
        color: widget.dividerColor,
      ),
    ],
  );
}).toList(),
        // widget.items.map((label) {
        //   return 
        //   Text(label, style: widget.textStyle);
         
        // }).toList(),
      ),
    ),
  );
}

}