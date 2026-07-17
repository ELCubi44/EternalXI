/// Utilidades compartidas para parseo JSON del dominio Clash.
library;

int clashAsInt(Object? value, {int fallback = 0}) {
  if (value == null) {
    return fallback;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

int clashRequireInt(Object? value, String fieldName) {
  if (value == null) {
    throw FormatException('Campo obligatorio ausente: $fieldName');
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  throw FormatException('Campo $fieldName debe ser numérico entero');
}

String clashRequireString(Object? value, String fieldName) {
  if (value == null) {
    throw FormatException('Campo obligatorio ausente: $fieldName');
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    throw FormatException('Campo $fieldName no puede estar vacío');
  }
  return text;
}

String? clashOptionalString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? clashOptionalInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
