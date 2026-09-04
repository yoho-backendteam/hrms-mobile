import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class AppToast {
  AppToast._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, type: ToastType.success);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message: message, type: ToastType.error);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, type: ToastType.info);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message: message, type: ToastType.warning);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required ToastType type,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.hideCurrentSnackBar();

    Color bgColor;
    Color iconColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        bgColor = const Color(0xFF0F172A);
        iconColor = const Color(0xFF10B981);
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        bgColor = const Color(0xFFFEF2F2);
        iconColor = const Color(0xFFDC2626);
        textColor = const Color(0xFF991B1B);
        icon = Icons.error_rounded;
        break;
      case ToastType.warning:
        bgColor = const Color(0xFFFFFBEB);
        iconColor = const Color(0xFFD97706);
        textColor = const Color(0xFF92400E);
        icon = Icons.warning_rounded;
        break;
      case ToastType.info:
        bgColor = const Color(0xFF0F172A);
        iconColor = const Color(0xFFFF5722);
        textColor = Colors.white;
        icon = Icons.info_rounded;
        break;
    }

    final isLightBox = type == ToastType.error || type == ToastType.warning;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isLightBox
              ? BorderSide(color: iconColor.withValues(alpha: 0.3), width: 1)
              : BorderSide.none,
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
