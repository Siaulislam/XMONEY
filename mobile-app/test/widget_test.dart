import 'package:flutter_test/flutter_test.dart';
import 'package:xmoney_app/core/l10n/xm_strings.dart';

void main() {
  test('XmStrings loads English catalog', () async {
    await XmStrings.instance.load('en');
    expect(XmStrings.instance.t('nav.signin', 'Sign in'), isNotEmpty);
  });
}
