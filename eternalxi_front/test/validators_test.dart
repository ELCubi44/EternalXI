import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/core/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email validator returns null for valid email', () {
    expect(
      Validators.email('test@mail.com', AppLocalizations(const Locale('es'))),
      isNull,
    );
  });
}
