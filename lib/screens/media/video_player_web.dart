// Web implementation - uses HtmlElementView to embed YouTube iframe
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

final _registeredViews = <String>{};

Widget buildYouTubeIframe(String videoId) {
  final viewType = 'youtube-$videoId';

  if (!_registeredViews.contains(viewType)) {
    _registeredViews.add(viewType);
    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      return html.IFrameElement()
        ..src =
            'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&mute=1&playsinline=1&rel=0'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..setAttribute('allowfullscreen', 'true');
    });
  }

  return HtmlElementView(viewType: viewType);
}
