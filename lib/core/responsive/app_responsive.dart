import 'package:flutter/widgets.dart';

class AppResponsive {
  const AppResponsive._();
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1024;
  }

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return 48;
    if (width >= 600) return 32;
    return 20;
  }
}
