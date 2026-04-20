import 'package:flutter/material.dart';
import 'package:tds_voice_agent/widgets/voice%20orb/voice_orb.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  bool speaking = false;
  bool listening = false;

  void setIdle() {
    setState(() {
      speaking = false;
      listening = false;
    });
  }

  void setThinking() {
    setState(() {
      speaking = false;
      listening = true;
    });
  }

  void setSpeaking() {
    setState(() {
      speaking = true;
      listening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090f),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// 🔵 ORB
          VoiceOrb(speaking: speaking, listening: listening),

          const SizedBox(height: 40),

          /// 🔘 BUTTONS (TEST)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _btn("Idle", setIdle),
              const SizedBox(width: 10),
              _btn("Thinking", setThinking),
              const SizedBox(width: 10),
              _btn("Talking", setSpeaking),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
    return ElevatedButton(onPressed: onTap, child: Text(text));
  }
}
