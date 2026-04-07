import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view/voice_screen.dart';
import 'viewmodel/voice_viewmodel.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => VoiceViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VoiceScreen(),
    );
  }
}