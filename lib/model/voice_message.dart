class VoiceMessage {
  final String text;
  final bool isUser;
  final bool isPlaying;

  VoiceMessage({
    required this.text,
    required this.isUser,
    this.isPlaying = false,
  });
}