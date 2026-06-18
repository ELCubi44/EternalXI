import 'dart:convert';

import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book.dart';
import 'package:flutter/services.dart';

/// Carga libros de técnica Clash desde JSON empaquetado en assets.
class ClashTechniqueBooksLocalDataSource {
  ClashTechniqueBooksLocalDataSource({
    this.assetPath = 'assets/data/clash/technique_books.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  Future<List<ClashTechniqueBook>> loadBooks() async {
    final raw = await _bundle.loadString(assetPath);
    return parseBooksJson(raw);
  }

  List<ClashTechniqueBook> parseBooksJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'JSON de libros de técnica Clash debe ser un objeto',
      );
    }

    final booksRaw = decoded['books'];
    if (booksRaw is! List) {
      throw FormatException('Campo obligatorio ausente: books');
    }

    return booksRaw
        .map(
          (item) => ClashTechniqueBook.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }
}
