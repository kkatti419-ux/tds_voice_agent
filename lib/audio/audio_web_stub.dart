import 'dart:typed_data';

class AudioWeb {
  void start({
    void Function(double levelDb)? onLevel,
    void Function(String message)? onMicError,
  }) {
    // No-op on non-web platforms.
  }

  void stop() {
    // No-op on non-web platforms.
  }
}

