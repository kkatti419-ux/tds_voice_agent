import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/voice_viewmodel.dart';
import '../widgets/mic_animation.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  bool _didAutostart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb || _didAutostart) return;
      _didAutostart = true;
      context.read<VoiceViewModel>().requestAutostartMic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<VoiceViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Agent')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Text(vm.statusText),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: vm.messages.length,
              itemBuilder: (_, index) {
                final msg = vm.messages[index];

                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    color: msg.isUser ? Colors.blue : Colors.grey.shade300,
                    child: Text(msg.text),
                  ),
                );
              },
            ),
          ),

          GestureDetector(
            onTap: () => vm.toggleListening(),
            child: MicAnimation(
              isListening: vm.isListening,
              amplitudeDb: vm.amplitudeDb,
              isAgentSpeaking: vm.isAgentSpeaking,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
