import 'package:djbs_foundation/utils/verhoeff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects an incomplete aadhaar number', () {
    expect(Verhoeff.validate('1234'), isFalse);
    expect(Verhoeff.validate(''), isFalse);
  });
}
