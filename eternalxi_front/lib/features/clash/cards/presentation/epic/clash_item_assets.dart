/// Iconos de objetos consumibles Clash (libros, etc.).
abstract final class ClashItemAssets {
  static const _base = 'assets/images/clash/items';

  static String techniqueBookIcon(String bookId) => switch (bookId) {
        'basic-technique-book' => '$_base/book_basic.png',
        'advanced-technique-book' => '$_base/book_advanced.png',
        'master-technique-book' => '$_base/book_master.png',
        _ => '$_base/book_basic.png',
      };
}
