import 'dart:collection';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Elimina fondos claros (blanco, gris, checkerboard) conectados al borde.
Uint8List stripLightBorderBackgroundBytes(
  Uint8List input, {
  int threshold = 175,
}) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    return input;
  }
  final stripped = _stripLightBorderBackground(decoded, threshold: threshold);
  return Uint8List.fromList(img.encodePng(stripped));
}

img.Image _stripLightBorderBackground(
  img.Image decoded, {
  required int threshold,
}) {
  final w = decoded.width;
  final h = decoded.height;
  final remove = List.generate(h, (_) => List.filled(w, false));

  bool isBg(int x, int y) {
    final p = decoded.getPixel(x, y);
    final r = p.r.toInt();
    final g = p.g.toInt();
    final b = p.b.toInt();
    if (r < threshold || g < threshold || b < threshold) {
      return false;
    }
    final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
    return maxC - minC <= 28;
  }

  final queue = Queue<(int, int)>();
  void seed(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) {
      return;
    }
    if (!isBg(x, y) || remove[y][x]) {
      return;
    }
    remove[y][x] = true;
    queue.add((x, y));
  }

  for (var x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }

  while (queue.isNotEmpty) {
    final (x, y) = queue.removeFirst();
    seed(x + 1, y);
    seed(x - 1, y);
    seed(x, y + 1);
    seed(x, y - 1);
  }

  final out = img.Image(width: w, height: h, numChannels: 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = decoded.getPixel(x, y);
      if (remove[y][x]) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }
  }
  return out;
}
