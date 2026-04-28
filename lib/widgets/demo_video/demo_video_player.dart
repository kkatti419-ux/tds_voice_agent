/// Demo video: [video_player] on IO; HTML `<video>` + blob URL on web (avoids
/// `VideoPlayerPlatform.init` UnimplementedError when the web plugin is not wired).
library;

export 'demo_video_player_io.dart'
    if (dart.library.html) 'demo_video_player_web.dart';
