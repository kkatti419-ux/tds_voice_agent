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
  static final List<html.IFrameElement> _iframes = <html.IFrameElement>[];

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
      _iframes.add(iframe);
      return iframe;
    });
    _viewFactoryRegistered = true;
  }

  void _onWindowMessage(html.MessageEvent event) {
    if (event.origin != html.window.location.origin) return;
    final data = event.data;
    if (data is! String || !data.startsWith('tds_globe_wheel:')) return;
    final raw = data.substring('tds_globe_wheel:'.length);
    final delta = double.tryParse(raw);
    if (delta == null) return;
    if (!mounted) return;
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos == null) return;
    final next = (pos.pixels + delta).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    pos.jumpTo(next.toDouble());
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

void setGlobeIframePointerEventsEnabled(bool enabled) {
  final value = enabled ? 'auto' : 'none';
  for (final iframe in _GlobePageState._iframes) {
    iframe.style.pointerEvents = value;
  }
}
