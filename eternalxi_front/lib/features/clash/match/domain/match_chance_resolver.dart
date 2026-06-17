import 'dart:math';

/// Resolución probabilística inyectable (tests deterministas).
abstract class MatchChanceResolver {
  bool succeeds(int percent);
}

class RandomMatchChanceResolver implements MatchChanceResolver {
  RandomMatchChanceResolver(this._random);

  final Random _random;

  @override
  bool succeeds(int percent) {
    final clamped = percent.clamp(5, 95);
    return _random.nextInt(100) < clamped;
  }
}

class FixedMatchChanceResolver implements MatchChanceResolver {
  const FixedMatchChanceResolver({required this.alwaysSucceed});

  final bool alwaysSucceed;

  @override
  bool succeeds(int percent) => alwaysSucceed;
}
