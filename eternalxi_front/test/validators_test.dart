import 'package:eternal_xi/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email validator returns null for valid email', () {
    expect(Validators.email('test@mail.com'), isNull);
  });
}
