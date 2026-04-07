import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class Message {
  final String text;
  final bool isUser;

  Message(this.text, this.isUser);
}

class VoiceViewModel extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool isListening = false;
  List<Message> messages = [];

  // START LISTENING
  Future<void> startListening() async {
    if (_speech.isListening) return;

    bool available = await _speech.initialize();

    if (available) {
      isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            String text = result.recognizedWords;

            messages.add(Message(text, true));
            _reply(text);
          }

          notifyListeners();
        },
      );
    }
  }
  // Future<void> startListening() async {
  //   // 🔥 IMPORTANT FIX
  //   if (isListening) return;

  //   bool available = await _speech.initialize();

  //   if (available) {
  //     isListening = true;
  //     notifyListeners();

  //     _speech.listen(
  //       onResult: (result) {
  //         if (result.finalResult) {
  //           String text = result.recognizedWords;

  //           messages.add(Message(text, true));
  //           _reply(text);
  //         }

  //         notifyListeners();
  //       },
  //     );
  //   }
  // }
  // Future<void> startListening() async {
  //   bool available = await _speech.initialize();

  //   if (available) {
  //     isListening = true;
  //     notifyListeners();

  //     _speech.listen(
  //       onResult: (result) {
  //         if (result.finalResult) {
  //           String text = result.recognizedWords;

  //           messages.add(Message(text, true));

  //           // OPTIONAL: Bot reply
  //           _reply(text);
  //         }

  //         notifyListeners();
  //       },
  //     );
  //   }
  // }

  // STOP LISTENING
  void stopListening() {
    if (!isListening) return;

    _speech.stop();
    isListening = false;
    notifyListeners();
  }
  // void stopListening() {
  //   _speech.stop();
  //   isListening = false;
  //   notifyListeners();
  // }

  // BOT REPLY + TTS
  Future<void> _reply(String userText) async {
    String reply = "You said: $userText";

    messages.add(Message(reply, false));
    notifyListeners();

    await _tts.speak(reply);
  }
}
