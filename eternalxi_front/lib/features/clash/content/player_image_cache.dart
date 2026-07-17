import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Disk cache for player photos shared by Clash and Fantasy.
///
/// One image per [playerId] (same photo Fantasy / rarity R use).
class PlayerImageCache {
  PlayerImageCache._();

  static final PlayerImageCache instance = PlayerImageCache._();

  Directory? _playersDir;
  final Map<int, File> _known = {};

  Future<Directory> playersDirectory() async {
    final cached = _playersDir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/clash_content/players');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _playersDir = dir;
    return dir;
  }

  File fileFor(int playerId, Directory dir) =>
      File('${dir.path}/$playerId.png');

  Future<File?> localFile(int playerId) async {
    if (playerId <= 0) return null;
    final known = _known[playerId];
    if (known != null && await known.exists()) return known;
    final dir = await playersDirectory();
    final file = fileFor(playerId, dir);
    if (await file.exists() && await file.length() > 0) {
      _known[playerId] = file;
      return file;
    }
    return null;
  }

  /// Sync lookup after [playersDirectory] was warmed (e.g. splash / prepare).
  File? localFileIfReady(int playerId) {
    if (playerId <= 0) return null;
    final known = _known[playerId];
    if (known != null) return known;
    final dir = _playersDir;
    if (dir == null) return null;
    final file = fileFor(playerId, dir);
    if (file.existsSync() && file.lengthSync() > 0) {
      _known[playerId] = file;
      return file;
    }
    return null;
  }

  Future<void> remember(int playerId, File file) async {
    _known[playerId] = file;
  }

  Future<int> countPresent(Iterable<int> playerIds) async {
    final dir = await playersDirectory();
    var n = 0;
    for (final id in playerIds) {
      final f = fileFor(id, dir);
      if (await f.exists() && await f.length() > 0) n++;
    }
    return n;
  }

  Future<int> bytesPresent(Iterable<int> playerIds) async {
    final dir = await playersDirectory();
    var bytes = 0;
    for (final id in playerIds) {
      final f = fileFor(id, dir);
      if (await f.exists()) {
        bytes += await f.length();
      }
    }
    return bytes;
  }
}
