class VoiceMessage {
  String text;
  final bool isUser;
  bool isPlaying;

  VoiceMessage({
    required this.text,
    required this.isUser,
    this.isPlaying = false,
  });
}