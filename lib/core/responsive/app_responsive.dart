import 'package:flutter/widgets.dart';

enum AppLayout { mobile, tablet, desktop }

abstract final class AppResponsive {
  static AppLayout layout(BuildContext context) =>
      layoutForWidth(MediaQuery.sizeOf(context).width);

  static AppLayout layoutForWidth(double width) => width < 600
      ? AppLayout.mobile
      : width < 1024
      ? AppLayout.tablet
      : AppLayout.desktop;

  static bool isMobile(BuildContext context) =>
      layout(context) == AppLayout.mobile;

  static double horizontalPadding(BuildContext context) =>
      switch (layout(context)) {
        AppLayout.mobile => 20,
        AppLayout.tablet => 32,
        AppLayout.desktop => 40,
      };

  static double contentWidth(BuildContext context) => switch (layout(context)) {
    AppLayout.mobile => double.infinity,
    AppLayout.tablet => 920,
    AppLayout.desktop => 1200,
  };
}
