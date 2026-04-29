import 'package:flutter/material.dart';

/// Non-web placeholder ([globe_page_web] uses platform view + iframe).
class GlobePage extends StatelessWidget {
  const GlobePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.transparent,
      child: SizedBox.expand(),
    );
  }
}
