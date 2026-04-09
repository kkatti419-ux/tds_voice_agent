import 'package:flutter/material.dart';

class RevealWidget extends StatelessWidget {
  final bool revealed;
  final Widget child;

  const RevealWidget({super.key, required this.revealed, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      opacity: revealed ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 700),
        offset: revealed ? Offset.zero : const Offset(0, 0.06),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}