import 'package:flutter_test/flutter_test.dart';
import 'package:wol_client/core/routes/app_pages.dart';
import 'package:wol_client/core/routes/app_routes.dart';

void main() {
  test('all registered pages have valid paths starting with /', () {
    final names = AppPages.pages.map((p) => p.name).toList();
    expect(names, contains(AppRoutes.root));
    expect(names, contains(AppRoutes.login));
    expect(names, contains(AppRoutes.gateways));
    expect(names, contains(AppRoutes.dashboard));
    expect(names, contains(AppRoutes.discovery));
    expect(names, contains(AppRoutes.deviceForm));
    expect(names, contains(AppRoutes.deviceDetail));
    expect(names, contains(AppRoutes.diagnostics));
    expect(names, contains(AppRoutes.settings));

    for (final page in AppPages.pages) {
      expect(page.name.startsWith('/'), isTrue);
    }
  });

  test('no duplicate route names exist in AppPages', () {
    final names = AppPages.pages.map((p) => p.name).toList();
    expect(names.toSet().length, equals(names.length));
  });
}
