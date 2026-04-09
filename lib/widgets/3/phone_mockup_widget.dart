// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:tds_voice_agent/domain/entities/agni_content.dart';

// class PhoneMockupWidget extends StatefulWidget {
//   final bool isDark;
//   final List<String> languages;
//   final List<FloatingCardData> floatingCards;

//   const PhoneMockupWidget({
//     super.key,
//     required this.isDark,
//     required this.languages,
//     required this.floatingCards,
//   });

//   @override
//   State<PhoneMockupWidget> createState() => _PhoneMockupWidgetState();
// }

// class _PhoneMockupWidgetState extends State<PhoneMockupWidget>
//     with TickerProviderStateMixin {
//   late AnimationController _waveController;
//   late AnimationController _floatController;

//   int _langIndex = 0;
//   double _langOpacity = 1;
//   double _langOffset = 0;

//   @override
//   void initState() {
//     super.initState();

//     _waveController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);

//     _floatController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 3),
//     )..repeat(reverse: true);

//     _startLanguageCycle();
//   }

//   void _startLanguageCycle() async {
//     while (mounted) {
//       await Future.delayed(const Duration(seconds: 2));

//       setState(() {
//         _langOpacity = 0;
//         _langOffset = 10;
//       });

//       await Future.delayed(const Duration(milliseconds: 400));

//       setState(() {
//         _langIndex = (_langIndex + 1) % widget.languages.length;
//         _langOpacity = 1;
//         _langOffset = 0;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _waveController.dispose();
//     _floatController.dispose();
//     super.dispose();
//   }

//   Color get textColor => widget.isDark ? Colors.white : Colors.black;

//   Color get text3Color => widget.isDark ? Colors.white60 : Colors.black54;

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         _phoneUI(),

//         /// Floating Cards
//         if (widget.floatingCards.isNotEmpty)
//           Positioned(
//             top: 50,
//             right: -80,
//             child: _floatingCard(widget.floatingCards[0]),
//           ),

//         if (widget.floatingCards.length > 1)
//           Positioned(
//             bottom: 90,
//             left: -80,
//             child: _floatingCard(widget.floatingCards[1]),
//           ),
//       ],
//     );
//   }

//   Widget _phoneUI() {
//     return Container(
//       width: 260,
//       height: 420,
//       decoration: BoxDecoration(
//         color: widget.isDark ? const Color(0xFF08162A) : Colors.white,
//         borderRadius: BorderRadius.circular(32),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _avatar(),
//           const SizedBox(height: 16),
//           _waveform(),
//           const SizedBox(height: 16),

//           /// Language Animation
//           if (widget.languages.isNotEmpty)
//             AnimatedOpacity(
//               duration: const Duration(milliseconds: 400),
//               opacity: _langOpacity,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 400),
//                 transform: Matrix4.translationValues(0, _langOffset, 0),
//                 child: Text(
//                   widget.languages[_langIndex],
//                   style: GoogleFonts.playfairDisplay(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: textColor,
//                   ),
//                 ),
//               ),
//             ),

//           const SizedBox(height: 8),

//           Text("Agentic AI", style: TextStyle(color: text3Color)),

//           const SizedBox(height: 20),

//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             decoration: BoxDecoration(
//               color: Colors.blue,
//               borderRadius: BorderRadius.circular(50),
//             ),
//             child: const Text(
//               "Tap to talk",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _avatar() {
//     return Container(
//       width: 70,
//       height: 70,
//       decoration: const BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.blue,
//       ),
//       child: const Icon(Icons.person, color: Colors.white),
//     );
//   }

//   Widget _waveform() {
//     final heights = [20.0, 30.0, 40.0, 25.0, 35.0];

//     return AnimatedBuilder(
//       animation: _waveController,
//       builder: (_, __) {
//         return Row(
//           mainAxisSize: MainAxisSize.min,
//           children: heights.map((h) {
//             final scale = 0.5 + math.sin(_waveController.value * math.pi) * 0.5;

//             return Container(
//               width: 4,
//               height: h * scale,
//               margin: const EdgeInsets.symmetric(horizontal: 2),
//               color: Colors.blue,
//             );
//           }).toList(),
//         );
//       },
//     );
//   }

//   Widget _floatingCard(FloatingCardData data) {
//     return AnimatedBuilder(
//       animation: _floatController,
//       builder: (_, __) {
//         final offset = math.sin(_floatController.value * math.pi * 2) * 6;

//         return Transform.translate(
//           offset: Offset(0, offset),
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: widget.isDark ? Colors.black : Colors.white,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   data.stat,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 Text(data.label),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

//-------------------------------------------------------

// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// class VoicePhoneWidget extends StatefulWidget {
//   final bool isDark;

//   const VoicePhoneWidget({super.key, required this.isDark});

//   @override
//   State<VoicePhoneWidget> createState() => _VoicePhoneWidgetState();
// }

// class _VoicePhoneWidgetState extends State<VoicePhoneWidget>
//     with TickerProviderStateMixin {
//   late stt.SpeechToText _speech;
//   bool _isListening = false;

//   String userText = "";
//   String botReply = "Tap mic and speak...";

//   late AnimationController _waveController;

//   @override
//   void initState() {
//     super.initState();

//     _speech = stt.SpeechToText();

//     _waveController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     )..repeat(reverse: true);
//   }

//   void _listen() async {
//     if (!_isListening) {
//       bool available = await _speech.initialize();

//       if (available) {
//         setState(() => _isListening = true);

//         _speech.listen(
//           onResult: (result) {
//             setState(() {
//               userText = result.recognizedWords;
//               botReply = _generateReply(userText);
//             });
//           },
//         );
//       }
//     } else {
//       setState(() => _isListening = false);
//       _speech.stop();
//     }
//   }

//   String _generateReply(String input) {
//     if (input.toLowerCase().contains("price")) {
//       return "Our pricing starts from ₹2/min with AI support.";
//     } else if (input.isNotEmpty) {
//       return "Got it: \"$input\"";
//     }
//     return "Say something...";
//   }

//   Color get bg => widget.isDark ? const Color(0xFF08162A) : Colors.white;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 280,
//       height: 480,
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: Column(
//         children: [
//           const SizedBox(height: 20),

//           /// 🎙️ Avatar
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.blue,
//             child: Icon(
//               _isListening ? Icons.mic : Icons.mic_none,
//               color: Colors.white,
//             ),
//           ),

//           const SizedBox(height: 20),

//           /// 🔊 Wave animation
//           _waveform(),

//           const SizedBox(height: 20),

//           /// 💬 Chat bubbles
//           _chatBubble(userText, isUser: true),
//           _chatBubble(botReply, isUser: false),

//           const Spacer(),

//           /// 💰 Pricing Card
//           _pricingCard(),

//           const SizedBox(height: 10),

//           /// 🎤 Button
//           GestureDetector(
//             onTap: _listen,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)],
//                 ),
//                 borderRadius: BorderRadius.circular(50),
//               ),
//               child: Text(
//                 _isListening ? "Listening..." : "Tap to speak",
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   /// 🎧 Waveform
//   Widget _waveform() {
//     final heights = [20.0, 30.0, 40.0, 25.0, 35.0];

//     return AnimatedBuilder(
//       animation: _waveController,
//       builder: (_, __) {
//         return Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: heights.map((h) {
//             final scale = 0.5 + math.sin(_waveController.value * math.pi) * 0.5;

//             return Container(
//               width: 4,
//               height: h * scale,
//               margin: const EdgeInsets.symmetric(horizontal: 2),
//               color: Colors.blue,
//             );
//           }).toList(),
//         );
//       },
//     );
//   }

//   /// 💬 Chat Bubble
//   Widget _chatBubble(String text, {required bool isUser}) {
//     if (text.isEmpty) return const SizedBox();

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: isUser ? Colors.blue : Colors.grey.shade300,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Text(
//           text,
//           style: TextStyle(color: isUser ? Colors.white : Colors.black),
//         ),
//       ),
//     );
//   }

//   /// 💰 Pricing Card
//   Widget _pricingCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.green.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.green),
//       ),
//       child: Column(
//         children: const [
//           Text("Pricing", style: TextStyle(fontWeight: FontWeight.bold)),
//           SizedBox(height: 6),
//           Text("₹2 / min"),
//           Text("AI Voice + Automation"),
//         ],
//       ),
//     );
//   }
// }

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tds_voice_agent/model/voice_message.dart';
import 'package:tds_voice_agent/viewmodel/voice_viewmodel.dart';

/// Hero phone mockup: same behavior as dev [VoiceScreen] — WebSocket JSON + PCM
/// via [VoiceViewModel], binary TTS playback, barge-in, silence commit.
class VoicePhoneWidget extends StatefulWidget {
  final bool isDark;

  const VoicePhoneWidget({super.key, required this.isDark});

  @override
  State<VoicePhoneWidget> createState() => _VoicePhoneWidgetState();
}

class _VoicePhoneWidgetState extends State<VoicePhoneWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late ScrollController _scrollController;
  bool _didAutostart = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAutostart) return;
      _didAutostart = true;
      if (kIsWeb) {
        context.read<VoiceViewModel>().requestAutostartMic();
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  Color get bg => widget.isDark ? const Color(0xFF08162A) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceViewModel>(
      builder: (context, vm, _) {
        if (vm.messages.isNotEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }

        return Container(
          width: 300,
          height: 520,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  vm.statusText,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 28,
                backgroundColor: vm.isListening ? Colors.green.shade700 : Colors.blue,
                child: Icon(
                  vm.micMutedByUser || !vm.isListening
                      ? Icons.mic_off
                      : Icons.mic,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              _waveform(vm),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: vm.messages.length,
                  itemBuilder: (context, index) {
                    final VoiceMessage msg = vm.messages[index];
                    return _chatBubble(msg.text, isUser: msg.isUser);
                  },
                ),
              ),
              _pricingCard(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: vm.agentTtsMuted
                          ? 'Unmute agent voice'
                          : 'Mute agent voice',
                      onPressed: vm.toggleAgentTtsMuted,
                      icon: Icon(
                        vm.agentTtsMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                        size: 22,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    Flexible(
                      child: GestureDetector(
                        onTap: () => vm.toggleListening(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5B6CFF),
                                Color(0xFF8E44AD),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            vm.micMutedByUser || !vm.isListening
                                ? 'Tap to unmute'
                                : 'Mute mic',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _waveform(VoiceViewModel vm) {
    final heights = [20.0, 30.0, 40.0, 25.0, 35.0];
    final level = ((vm.amplitudeDb + 120) / 120).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: heights.asMap().entries.map((e) {
            final i = e.key;
            final h = e.value;
            final wobble =
                0.55 + 0.45 * math.sin(_waveController.value * math.pi + i);
            final scale =
                vm.isListening ? (0.35 + level * 0.65) * wobble : 0.35;
            return Container(
              width: 4,
              height: (h * scale).clamp(6.0, 48.0),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: Colors.blue,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _chatBubble(String text, {required bool isUser}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            text,
            softWrap: true,
            style: TextStyle(color: isUser ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _pricingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: const Column(
        children: [
          Text('Pricing', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('₹2 / min'),
          Text('AI Voice + Automation'),
        ],
      ),
    );
  }
}
