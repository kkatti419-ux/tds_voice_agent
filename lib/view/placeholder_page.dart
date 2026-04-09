import 'package:flutter/material.dart';

/// Temporary full-screen placeholder for routes not yet implemented.
class PlaceholderPage extends StatelessWidget {
  /// Shown in the app bar and as secondary context in the body.
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        automaticallyImplyLeading: false, // 🔥 THIS REMOVES BACK ARROW
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Soon it will come',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
