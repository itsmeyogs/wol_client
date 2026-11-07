import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

class AppSnackbar {
  AppSnackbar._();

  static void success(String message) =>
      _show(title: 'Success', message: message, color: AppColors.primary);

  static void error(String message) =>
      _show(title: 'Error', message: message, color: AppColors.error);

  static void _show({
    required String title,
    required String message,
    required Color color,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      borderRadius: 12,
      backgroundColor: color,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 220),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
}
