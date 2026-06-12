import 'dart:io';

import 'package:image/image.dart' as img;

/// Elimina todos los píxeles oscuros (no solo los del borde).
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart run tool/strip_dark_pixels.dart <ruta> [umbral]');
    exit(1);
  }
  final path = args.first;
  final threshold = args.length > 1 ? int.parse(args[1]) : 42;
  final file = File(path);
  final decoded = img.decodeImage(file.readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('No se pudo decodificar: $path');
    exit(1);
  }

  final w = decoded.width;
  final h = decoded.height;
  final out = img.Image(width: w, height: h, numChannels: 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = decoded.getPixel(x, y);
      if (p.r < threshold && p.g < threshold && p.b < threshold) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }
  }

  file.writeAsBytesSync(img.encodePng(out));
  stdout.writeln('OK: $path');
}
