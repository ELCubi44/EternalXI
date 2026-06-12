import 'dart:collection';
import 'dart:io';

import 'package:image/image.dart' as img;

/// JPEG/PNG con fondo negro → PNG RGBA. Solo elimina negro conectado al borde.
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart run tool/strip_black_bg.dart <ruta> [umbral]');
    exit(1);
  }
  final path = args.first;
  final threshold = args.length > 1 ? int.parse(args[1]) : 28;
  final file = File(path);
  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('No se pudo decodificar: $path');
    exit(1);
  }

  final w = decoded.width;
  final h = decoded.height;
  final remove = List.generate(h, (_) => List.filled(w, false));

  bool isBg(int x, int y) {
    final p = decoded.getPixel(x, y);
    return p.r < threshold && p.g < threshold && p.b < threshold;
  }

  final queue = Queue<(int, int)>();
  void seed(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    if (!isBg(x, y) || remove[y][x]) return;
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

  file.writeAsBytesSync(img.encodePng(out));
  stdout.writeln('OK: $path');
}
