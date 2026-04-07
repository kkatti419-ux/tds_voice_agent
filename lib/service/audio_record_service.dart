import 'package:record/record.dart';
import 'dart:async';

class AudioRecordService {
  final _recorder = AudioRecorder();
  Timer? _amplitudeTimer;
  bool _isRecording = false;

  /// dBFS amplitude polling frequency.
  static const _amplitudePollInterval = Duration(milliseconds: 100);

  Future<void> startRecording({
    required void Function(double amplitudeDb) onAmplitude,
  }) async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    _isRecording = true;

    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(_amplitudePollInterval, (_) async {
      try {
        final amp = await _recorder.getAmplitude();
        onAmplitude(amp.current);
      } catch (_) {
        // If amplitude polling fails, don't crash the recording flow.
      }
    });

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 24000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: 'voice.wav',
    );
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    return await _recorder.stop();
  }
}