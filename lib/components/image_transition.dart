import 'package:flutter/material.dart';
import 'dart:typed_data';

class ImageTransition extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final Animation<double> animation;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ImageTransition({
    super.key,
    this.imageBytes,
    this.imageUrl,
    required this.animation,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : assert(imageBytes != null || imageUrl != null);

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget =
        imageBytes != null
            ? Image.memory(imageBytes!, fit: fit)
            : Image.network(
              imageUrl!,
              fit: fit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 64,
                  ),
                );
              },
            );

    // Apply clipping if border radius is specified
    final Widget finalWidget =
        borderRadius != null
            ? ClipRRect(borderRadius: borderRadius!, child: imageWidget)
            : imageWidget;

    // Apply fade transition
    return FadeTransition(opacity: animation, child: finalWidget);
  }
}
