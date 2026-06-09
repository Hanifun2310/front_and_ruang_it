import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Widget buildWebImage(String url, {double? width, double? height, BoxFit? fit, Widget? errorWidget}) {
  final String viewType = 'web-img-${url.hashCode}-${width}-${height}';
  
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final html.ImageElement element = html.ImageElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none'
      ..style.objectFit = fit == BoxFit.cover
          ? 'cover'
          : fit == BoxFit.contain
              ? 'contain'
              : 'fill';
              
    element.onError.listen((_) {
      element.style.display = 'none';
    });
    
    return element;
  });

  return SizedBox(
    width: width,
    height: height,
    child: Stack(
      children: [
        if (errorWidget != null) Positioned.fill(child: errorWidget),
        Positioned.fill(child: HtmlElementView(viewType: viewType)),
      ],
    ),
  );
}
