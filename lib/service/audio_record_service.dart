import 'package:record/record.dart';

class AudioRecordService {
  final _recorder = AudioRecorder();

  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      await _recorder.start(
        const RecordConfig(),
        path: 'voice.wav',
      );
    }
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }
}