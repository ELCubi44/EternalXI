import 'dart:collection';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Convierte PNG con cuadricula blanco/gris (falso alpha) en PNG con alpha real.
/// Elimina pixeles claros conectados al borde (checkerboard o fondo blanco).
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Uso: dart run tool/strip_checkerboard_bg.dart <archivo|directorio> '
      '[umbral]',
    );
    exit(1);
  }

  final threshold = args.length > 1 ? int.parse(args[1]) : 175;
  final target = args.first;
  final entity = FileSystemEntity.typeSync(target);

  if (entity == FileSystemEntityType.directory) {
    final dir = Directory(target);
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'));
    for (final file in files) {
      _processFile(file, threshold);
    }
    return;
  }

  _processFile(File(target), threshold);
}

void _processFile(File file, int threshold) {
  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('No se pudo decodificar: ${file.path}');
    return;
  }

  final stripped = stripLightBorderBackground(decoded, threshold: threshold);
  file.writeAsBytesSync(img.encodePng(stripped));
  stdout.writeln('OK: ${file.path}');
}

img.Image stripLightBorderBackground(
  img.Image decoded, {
  int threshold = 175,
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
