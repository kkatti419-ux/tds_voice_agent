import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart';

class GlobePage extends StatelessWidget {
  const GlobePage({super.key});

  @override
  Widget build(BuildContext context) {
    ui.platformViewRegistry.registerViewFactory('globe-view', (int viewId) {
      final iframe = IFrameElement()
        ..src = 'globe.html'
        ..style.border = 'none'
        ..style.backgroundColor = 'transparent'
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });

    return const HtmlElementView(viewType: 'globe-view');
  }
}
