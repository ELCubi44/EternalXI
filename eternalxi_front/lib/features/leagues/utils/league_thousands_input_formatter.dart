import 'package:flutter/services.dart';

/// Formatea importes enteros con separador de miles `.` mientras se escribe.
///
/// Si el texto nuevo contiene caracteres que no son dígitos (letras, coma,
/// signo negativo…), se rechaza el cambio completo y se mantiene el valor
/// anterior. Si contiene puntos que no corresponden a separadores de miles
/// válidos (ej. "10.5"), también se rechaza — evitando que un pegado
/// se transforme silenciosamente en otro número.
class LeagueThousandsInputFormatter extends TextInputFormatter {
  static final _onlyDigits = RegExp(r'^\d*$');
  static final _invalidChars = RegExp(r'[^\d.]');

  static String formatDigits(String digits) {
    final sanitized = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized.isEmpty) {
      return '';
    }
    final normalized = sanitized.replaceFirst(RegExp(r'^0+(?=.)'), '');
    final chars = normalized.split('');
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && (chars.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(chars[i]);
    }
    return buffer.toString();
  }

  static int? parseToInt(String formatted) {
    final raw = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Reject commas, letters, minus, or any char that isn't a digit or dot.
    if (_invalidChars.hasMatch(newValue.text)) {
      return oldValue;
    }

    // Now the text only has digits and dots. Strip ALL dots to get raw digits.
    final stripped = newValue.text.replaceAll('.', '');
    if (!_onlyDigits.hasMatch(stripped)) return oldValue;

    // Guard against decimal-point pastes like "10.5":
    // the dots in newValue must match the count our formatter would produce
    // for those digits. Extra dots → user paste with decimal → reject.
    final formatted = formatDigits(stripped);
    final dotsInInput = '.'.allMatches(newValue.text).length;
    final dotsExpected = '.'.allMatches(formatted).length;
    if (dotsInInput > dotsExpected) {
      return oldValue;
    }

    final digitsBeforeCursor = _countDigitsBeforeOffset(
      newValue.text,
      newValue.selection.baseOffset,
    );
    final newCursorOffset = _offsetForDigitsCount(
      formatted,
      digitsBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorOffset),
      composing: TextRange.empty,
    );
  }

  static int _countDigitsBeforeOffset(String text, int offset) {
    final safeOffset = offset.clamp(0, text.length);
    final before = text.substring(0, safeOffset);
    return RegExp(r'\d').allMatches(before).length;
  }

  static int _offsetForDigitsCount(String text, int digitsCount) {
    if (digitsCount <= 0) {
      return 0;
    }
    var seenDigits = 0;
    for (var i = 0; i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        seenDigits++;
        if (seenDigits >= digitsCount) {
          return i + 1;
        }
      }
    }
    return text.length;
  }
}
