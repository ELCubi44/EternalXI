/// Formato legible en español para puntos, dinero y valor económico en pantallas de liga.
/// No depende de `intl` para mantener el árbol de dependencias mínimo.
abstract final class LeagueMoneyFormat {
  LeagueMoneyFormat._();

  /// Puntos: sin decimales si es entero (miles con punto); si no, un decimal con coma.
  static String points(double value) {
    if (value.isNaN || value.isInfinite) {
      return '—';
    }
    if (value == value.roundToDouble()) {
      return _integerThousandsDots(value.round());
    }
    final rounded = (value * 10).round() / 10;
    final intPart = rounded.truncate();
    final frac = ((rounded - intPart).abs() * 10).round();
    final body = '${_integerThousandsDots(intPart)},$frac';
    return body;
  }

  /// Cantidad en euros: miles con punto, sufijo ` €` (ej. 167.000.000 €).
  static String money(double value) {
    return euros(value);
  }

  /// Valor de plantilla / equipo en euros (misma regla que [money]).
  static String teamValue(double value) {
    return euros(value);
  }

  /// Alias explícito para importes en euros.
  static String euros(double value) {
    if (value.isNaN || value.isInfinite) {
      return '—';
    }
    final sign = value < 0 ? '-' : '';
    final cents = (value.abs() * 100).round();
    final whole = cents ~/ 100;
    final dec = cents % 100;
    if (dec == 0) {
      return '$sign${_integerThousandsDots(whole)} €';
    }
    final decStr = dec.toString().padLeft(2, '0');
    return '$sign${_integerThousandsDots(whole)},$decStr €';
  }

  static String _integerThousandsDots(int n) {
    final sign = n < 0 ? '-' : '';
    final s = n.abs().toString();
    final buf = StringBuffer(sign);
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
