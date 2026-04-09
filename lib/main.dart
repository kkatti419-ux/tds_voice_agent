import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        theme: ThemeData.dark(useMaterial3: true),
        home: const VoiceScreen(),
      ),
    );
  }
}
