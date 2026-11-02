import 'package:flutter/material.dart';
import 'package:leafcheck/ui/theme/tokens.dart';

/// A leaf photo with radius 16. With [heroTag] it flies between Analyzing,
/// Result and list tiles.
class LeafPhoto extends StatelessWidget {
  const LeafPhoto({
    required this.image,
    this.heroTag,
    this.width,
    this.height,
    this.radius = AppRadius.card,
    this.semanticLabel,
    super.key,
  });

  /// Hero tag shared by Analyzing and Result (one photo per route, so a
  /// single tag never collides).
  static const scanHeroTag = 'scan-photo';

  final ImageProvider image;
  final Object? heroTag;
  final double? width;
  final double? height;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
        errorBuilder: (context, _, _) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
      ),
    );
    return heroTag == null ? photo : Hero(tag: heroTag!, child: photo);
  }
}
