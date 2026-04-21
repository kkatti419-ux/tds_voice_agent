import 'package:flutter/foundation.dart';

/// High-level session phase for idle / continue / stop (web mic).
enum VoiceSessionPhase {
  /// Mic on, normal capture; idle no-speech timer may run.
  listening,

  /// [client_idle] sent; waiting for [session_policy].
  awaitingPolicy,

  /// Server asked user to confirm; waiting for yes/no or timeout.
  awaitingContinueAnswer,

  /// Transitional (optional, mostly immediate).
  stopping,
}

/// Durations and helpers for idle listening policy (separate from utterance silence commit).
@immutable
class ListeningIdlePolicy {
  const ListeningIdlePolicy._();

  /// No speech above threshold for this long → send [VoiceSessionProtocol.clientIdle].
  static const Duration idleNoSpeech = Duration(seconds: 10);

  /// After [VoiceSessionPhase.awaitingContinueAnswer], auto [muteMic] if no answer.
  static const Duration continuePromptTimeout = Duration(seconds: 10);

  /// If user stays idle while listening, ask a lightweight presence check-in.
  static const Duration userPresencePromptIdle = Duration(seconds: 30);
}
