import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/voice_viewmodel.dart';
import '../widgets/mic_animation.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<VoiceViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Voice Agent")),
      body: Column(
        children: [
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
            onTap: () {
              if (vm.isListening) {
                vm.stopListening();
              } else {
                vm.startListening();
              }
            },
            child: MicAnimation(isListening: vm.isListening),
          ),

          // GestureDetector(
          //   onTapDown: (_) {
          //     vm.startListening();
          //   },
          //   onTapUp: (_) {
          //     vm.stopListening();
          //   },
          //   child: MicAnimation(isListening: vm.isListening),
          // ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
