import 'package:dio/dio.dart';
import 'package:eternal_xi/core/image/light_bg_stripper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Descarga una imagen de red y elimina fondos claros conectados al borde.
class TransparentNetworkImage extends StatefulWidget {
  const TransparentNetworkImage({
    required this.url,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.errorBuilder,
    super.key,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final Widget Function(BuildContext context)? errorBuilder;

  static final _cache = <String, Uint8List>{};

  @override
  State<TransparentNetworkImage> createState() =>
      _TransparentNetworkImageState();
}

class _TransparentNetworkImageState extends State<TransparentNetworkImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TransparentNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final cached = TransparentNetworkImage._cache[widget.url];
    if (cached != null) {
      if (mounted) {
        setState(() => _bytes = cached);
      }
      return;
    }

    try {
      final response = await Dio().get<List<int>>(
        widget.url,
        options: Options(responseType: ResponseType.bytes),
      );
      final raw = Uint8List.fromList(response.data ?? const []);
      final stripped = await compute(stripLightBorderBackgroundBytes, raw);
      TransparentNetworkImage._cache[widget.url] = stripped;
      if (mounted) {
        setState(() => _bytes = stripped);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.errorBuilder?.call(context) ??
          const ColoredBox(color: Colors.transparent);
    }
    final bytes = _bytes;
    if (bytes == null) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Image.memory(
      bytes,
      fit: widget.fit,
      alignment: widget.alignment,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
    );
  }
}
