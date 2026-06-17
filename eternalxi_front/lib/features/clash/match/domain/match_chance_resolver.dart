import 'dart:math';

/// Resolución probabilística inyectable (tests deterministas).
abstract class MatchChanceResolver {
  bool succeeds(int percent);

  /// Moneda de desempate: verde = usuario, rojo = rival.
  bool coinFlipFavorsUser();
}

class RandomMatchChanceResolver implements MatchChanceResolver {
  RandomMatchChanceResolver(this._random);

  final Random _random;

  @override
  bool succeeds(int percent) {
    final clamped = percent.clamp(5, 95);
    return _random.nextInt(100) < clamped;
  }

  @override
  bool coinFlipFavorsUser() => _random.nextBool();
}

class FixedMatchChanceResolver implements MatchChanceResolver {
  const FixedMatchChanceResolver({
    required this.alwaysSucceed,
    this.coinFavorsUser = true,
  });

  final bool alwaysSucceed;
  final bool coinFavorsUser;

  @override
  bool succeeds(int percent) => alwaysSucceed;

  @override
  bool coinFlipFavorsUser() => coinFavorsUser;
}
