// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

/// Web: iframe [globe.html] + wheel events forwarded to the Flutter scroll view via
/// [postMessage] so the page scrolls. Drag on the globe is unchanged (OrbitControls).
class GlobePage extends StatefulWidget {
  const GlobePage({super.key});

  @override
  State<GlobePage> createState() => _GlobePageState();
}

class _GlobePageState extends State<GlobePage> {
  static const String _viewType = 'tds-globe-view';

  static bool _viewFactoryRegistered = false;

  StreamSubscription<html.MessageEvent>? _wheelSub;

  @override
  void initState() {
    super.initState();
    _registerViewFactoryOnce();
    _wheelSub = html.window.onMessage.listen(_onWindowMessage);
  }

  void _registerViewFactoryOnce() {
    if (_viewFactoryRegistered) return;
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'globe.html'
        ..style.border = 'none'
        ..style.backgroundColor = 'transparent'
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });
    _viewFactoryRegistered = true;
  }

  void _onWindowMessage(html.MessageEvent event) {
    if (event.origin != html.window.location.origin) return;
    final data = event.data;
    if (data is! Map) return;
    if (data['source'] != 'tds_globe' || data['type'] != 'wheel') return;
    final dy = data['deltaY'];
    if (dy is! num) return;
    final delta = dy.toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pos = Scrollable.maybeOf(context)?.position;
      if (pos == null) return;
      final next = (pos.pixels + delta).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      );
      pos.jumpTo(next.toDouble());
    });
  }

  @override
  void dispose() {
    _wheelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}
