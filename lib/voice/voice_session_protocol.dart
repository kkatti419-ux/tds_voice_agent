/// WebSocket JSON `type` values for idle / continue-session flow (web voice).
/// Backend should accept [clientIdle] and emit [sessionPolicy]; client sends [continueIntent] for yes/no.
abstract final class VoiceSessionProtocol {
  VoiceSessionProtocol._();

  /// C→S: prolonged no speech while listening; not an utterance commit.
  static const String clientIdle = 'client_idle';

  /// S→C: policy after idle or after [continueIntent].
  /// Supported shapes:
  /// - `{ "type": "session_policy", "continueSession": true|false }`
  /// - `{ "type": "session_policy", "action": "continue"|"stop"|"ask_user", "prompt": "..."? }`
  static const String sessionPolicy = 'session_policy';

  /// C→S: user answered continue prompt (buttons or paired with STT on server).
  static const String continueIntent = 'continue_intent';

  /// Values for [continueIntent] `intent` field.
  static const String intentYes = 'yes';
  static const String intentNo = 'no';
}
