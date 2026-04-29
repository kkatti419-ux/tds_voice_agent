// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Hero demo clip — web uses a native `<video>` with a blob URL (asset bytes).
class DemoVideoPlayer extends StatefulWidget {
  const DemoVideoPlayer({super.key});

  @override
  State<DemoVideoPlayer> createState() => _DemoVideoPlayerState();
}

class _DemoVideoPlayerState extends State<DemoVideoPlayer> {
  String? _viewType;
  String? _objectUrl;
  html.VideoElement? _video;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final data = await rootBundle.load('assets/images/demo.mp4');
    final blob = html.Blob([data.buffer.asUint8List()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    _objectUrl = url;

    final video = html.VideoElement()
      ..src = url
      ..autoplay = true
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..setAttribute('playsinline', 'true');

    final vt =
        'demo-video-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(vt, (int _) => video);
    _video = video;
    if (!mounted) return;
    setState(() => _viewType = vt);
    await video.play().catchError((_) {});
  }

  @override
  void dispose() {
    _video?.pause();
    _video = null;
    if (_objectUrl != null) {
      html.Url.revokeObjectUrl(_objectUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewType == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        Positioned.fill(
          child: HtmlElementView(viewType: _viewType!),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
