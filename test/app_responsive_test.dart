import 'package:flutter_test/flutter_test.dart';
import 'package:wol_client/core/responsive/app_responsive.dart';

void main() {
  test('layout breakpoints match the product requirements', () {
    expect(AppResponsive.layoutForWidth(599), AppLayout.mobile);
    expect(AppResponsive.layoutForWidth(600), AppLayout.tablet);
    expect(AppResponsive.layoutForWidth(1023), AppLayout.tablet);
    expect(AppResponsive.layoutForWidth(1024), AppLayout.desktop);
  });
}
