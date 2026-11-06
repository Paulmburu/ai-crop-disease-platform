import 'dart:io';

import 'package:flutter/widgets.dart';

/// Paths of bundled assets. Never write asset paths anywhere else.
abstract final class AppAssets {
  /// A diagnosis photo: a bundled sample (`assets/...`) or a file on disk.
  static ImageProvider photo(String path) =>
      path.startsWith('assets/') ? AssetImage(path) : FileImage(File(path));

  static const leafLateBlight = 'assets/images/leaf_late_blight.jpg';
  static const leafEarlyBlight = 'assets/images/leaf_early_blight.jpg';
  static const leafHealthy = 'assets/images/leaf_healthy.jpg';
  static const leafBlurry = 'assets/images/leaf_blurry.jpg';
  static const fieldRows = 'assets/images/field_rows.jpg';

  static const List<String> leafPhotos = [
    leafLateBlight,
    leafEarlyBlight,
    leafHealthy,
    leafBlurry,
  ];
  static const List<String> all = [...leafPhotos, fieldRows];

  static const fontFamily = 'Inter';
}
