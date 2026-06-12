import 'dart:collection';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Fondo transparente + pelota central en blanco para tab Inicio de liga.
void main(List<String> args) {
  final path = args.isNotEmpty
      ? args.first
      : 'assets/app/nav_league_home.png';
  final file = File(path);
  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('No se pudo decodificar: $path');
    exit(1);
  }

  final w = decoded.width;
  final h = decoded.height;
  final removeBg = List.generate(h, (_) => List.filled(w, false));

  bool isBgPixel(int x, int y) {
    final p = decoded.getPixel(x, y);
    return p.r < 28 && p.g < 28 && p.b < 28;
  }

  final queue = Queue<(int, int)>();
  void seed(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    if (!isBgPixel(x, y) || removeBg[y][x]) return;
    removeBg[y][x] = true;
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

  bool inBallEllipse(int x, int y) {
    final cx = w * 0.5;
    final cy = h * 0.73;
    final rx = w * 0.24;
    final ry = h * 0.20;
    final dx = (x - cx) / rx;
    final dy = (y - cy) / ry;
    return dx * dx + dy * dy <= 1.05;
  }

  bool isNeutralDark(int r, int g, int b) {
    if (r > 95 || g > 95 || b > 95) return false;
    if (b > r + 30 && b > g + 20) return false;
    return (r - g).abs() < 28 && (g - b).abs() < 28;
  }

  (int, int, int) ballColor(int r, int g, int b) {
    final lum = (r + g + b) / 3;
    if (lum < 45) {
      return (252, 252, 252);
    }
    if (lum < 90) {
      return (210, 214, 220);
    }
    if (lum < 130) {
      return (45, 55, 95);
    }
    return (r, g, b);
  }

  final out = img.Image(width: w, height: h, numChannels: 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = decoded.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();

      if (removeBg[y][x]) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      if (inBallEllipse(x, y) && isNeutralDark(r, g, b)) {
        final (nr, ng, nb) = ballColor(r, g, b);
        out.setPixelRgba(x, y, nr, ng, nb, 255);
      } else {
        out.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }

  file.writeAsBytesSync(img.encodePng(out));
  stdout.writeln('OK: $path');
}
