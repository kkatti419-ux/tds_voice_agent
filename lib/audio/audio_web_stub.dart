class AudioWeb {
  void start({void Function(double levelDb)? onLevel}) {
    // No-op on non-web platforms.
  }

  void stop() {
    // No-op on non-web platforms.
  }
}
