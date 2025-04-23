import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 다중알림방지 스넥바
void customSnackbar({
  required String title,
  required String message,
  Widget? icon,
  void Function(GetSnackBar)? onTap,
}) {
  // 이미 스낵바가 열려있는 경우 중복 표시하지 않음
  if (Get.isSnackbarOpen) return;

  // 스낵바 표시
  Get.snackbar(title, message, icon: icon, onTap: onTap);
}
