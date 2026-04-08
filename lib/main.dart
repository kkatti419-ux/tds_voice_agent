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

// import 'package:flutter/material.dart';
// import 'package:tds_voice_agent/audio/audio_playback.dart';
// import 'package:tds_voice_agent/audio/audio_web.dart';
// import 'dart:typed_data';

// import 'package:tds_voice_agent/socket/socket_manager.dart';
 
// void main() {
//   runApp(const MyApp());
// }
 
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
 
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
 
// class _MyAppState extends State<MyApp> {
//   final socket = SocketManager();
//   final audio = AudioWeb();
//   final player = AudioPlayerWeb();
 
//   String status = "Idle";
//   String transcript = "";
//   String aiText = "";
 
//   @override
//   void initState() {
//     super.initState();
 
//     socket.connect();
 
//     socket.jsonStream.listen((event) {
//       setState(() {
//         if (event["type"] == "status") {
//           status = event["text"];
//         } else if (event["type"] == "transcript") {
//           transcript = event["text"];
//         } else if (event["type"] == "ai_stream") {
//           aiText += event["text"];
//         } else if (event["type"] == "interrupt") {
//           player.stop();
//         }
//       });
//     });
 
//     socket.audioStream.listen((Uint8List chunk) {
//       player.playChunk(chunk);
//     });
//   }
 
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text("Voice Agent")),
//         body: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Text("Status: $status"),
//               SizedBox(height: 10),
//               Text("You: $transcript"),
//               SizedBox(height: 10),
//               Text("AI: $aiText"),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   audio.start();
//                 },
//                 child: Text("Start Talking"),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   socket.interrupt();
//                 },
//                 child: Text("Interrupt"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }