import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Same pipeline as training (`ml-training/src/crop_ml/transforms.py`):
/// shorter side → 256, centre crop 224, RGB float32 / 255, NHWC
/// `[1, 224, 224, 3]`. ImageNet normalisation is inside the model.
/// Top-level so it can run in `compute` (off the UI thread).
Float32List preprocess(Uint8List bytes) {
  const resize = 256;
  const crop = 224;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('not an image');
  final image = img.bakeOrientation(decoded);
  final scale = resize / min(image.width, image.height);
  // ponytail: box-average when shrinking approximates PIL's antialiased
  // bilinear; exact parity needs the Python fixture test (AGENTS.md).
  final resized = img.copyResize(
    image,
    width: max(crop, (image.width * scale).round()),
    height: max(crop, (image.height * scale).round()),
    interpolation: scale < 1
        ? img.Interpolation.average
        : img.Interpolation.linear,
  );
  final left = ((resized.width - crop) / 2).round();
  final top = ((resized.height - crop) / 2).round();
  final out = Float32List(crop * crop * 3);
  var i = 0;
  for (var y = 0; y < crop; y++) {
    for (var x = 0; x < crop; x++) {
      final p = resized.getPixel(left + x, top + y);
      out[i++] = p.rNormalized.toDouble();
      out[i++] = p.gNormalized.toDouble();
      out[i++] = p.bNormalized.toDouble();
    }
  }
  return out;
}
