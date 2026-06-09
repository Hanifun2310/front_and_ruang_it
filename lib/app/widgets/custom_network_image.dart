import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'image_loader_mobile.dart'
    if (dart.library.html) 'image_loader_web.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Widget Function(BuildContext, String)? placeholder;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorWidget,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final defaultErrorWidget = Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );

      return buildWebImage(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorWidget: errorWidget != null
            ? errorWidget!(context, imageUrl, null)
            : placeholder != null
                ? placeholder!(context, imageUrl)
                : defaultErrorWidget,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget!(context, url, error)
          : null,
      placeholder: placeholder != null
          ? (context, url) => placeholder!(context, url)
          : null,
    );
  }
}
