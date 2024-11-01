import 'package:ds_lint/src/string_utils.dart';
import 'package:test/test.dart';

void main() {
  test('unescapeStr', () async {
    expect(unescapeStr(r'hello \t \n \\x22 \\u0022'), 'hello \t \n \x22 \u0022');
  });
}
