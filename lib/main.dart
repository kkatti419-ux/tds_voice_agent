import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tds_voice_agent/theme/app_theme.dart';
import 'view/voice_screen.dart';
import 'viewmodel/voice_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VoiceViewModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const VoiceScreen(),
      ),
    );
  }
}
