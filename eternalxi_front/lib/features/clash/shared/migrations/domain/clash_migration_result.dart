/// Resultado de ejecutar migraciones locales de Clash (Fase 56).
class ClashMigrationResult {
  const ClashMigrationResult({
    required this.fromVersion,
    required this.toVersion,
    this.ranMigrations = const [],
    this.skipped = false,
    this.futureVersionDetected = false,
    this.errors = const [],
  });

  final int fromVersion;
  final int toVersion;
  final List<String> ranMigrations;
  final bool skipped;
  final bool futureVersionDetected;
  final List<String> errors;

  bool get migrated => ranMigrations.isNotEmpty;

  bool get isSuccess => errors.isEmpty;
}
