import 'package:flutter/material.dart';

// ============================================
// 공통 다이얼로그
// ============================================

class CommonDialog extends StatelessWidget {
  final String? title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final bool barrierDismissible;

  const CommonDialog({
    Key? key,
    this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.barrierDismissible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title != null ? Text(title!) : null,
      content: Text(message),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              onCancel?.call();
            },
            child: Text(cancelText!, style: TextStyle(color: Colors.grey[600])),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          child: Text(
            confirmText ?? '확인',
            style: TextStyle(
              color: confirmColor ?? Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// 다이얼로그 헬퍼 함수들
// ============================================

class DialogHelper {
  /// 확인/취소 다이얼로그
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    String? title,
    required String message,
    String? confirmText,
    String? cancelText = '취소',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color? confirmColor,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (context) => CommonDialog(
            title: title,
            message: message,
            confirmText: confirmText,
            cancelText: cancelText,
            onConfirm: onConfirm,
            onCancel: onCancel,
            confirmColor: confirmColor,
            barrierDismissible: barrierDismissible,
          ),
    );
  }

  /// 알림 다이얼로그 (확인 버튼만)
  static Future<bool?> showAlertDialog(
    BuildContext context, {
    String? title,
    required String message,
    String confirmText = '확인',
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (context) => CommonDialog(
            title: title,
            message: message,
            confirmText: confirmText,
            onConfirm: onConfirm,
            barrierDismissible: barrierDismissible,
          ),
    );
  }

  /// 삭제 확인 다이얼로그
  static Future<bool?> showDeleteDialog(
    BuildContext context, {
    String? title = '삭제',
    required String message,
    String confirmText = '삭제',
    String cancelText = '취소',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmColor: Colors.red,
    );
  }

  /// 경고 다이얼로그
  static Future<bool?> showWarningDialog(
    BuildContext context, {
    String? title = '경고',
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmColor: Colors.orange,
    );
  }
}

// ============================================
// 사용 예시
// ============================================

// class DialogExample extends StatelessWidget {
//   const DialogExample({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('다이얼로그 예시')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // 1. 기본 확인/취소 다이얼로그
//             ElevatedButton(
//               onPressed: () async {
//                 final result = await DialogHelper.showConfirmDialog(
//                   context,
//                   title: '친구 요청',
//                   message: '친구 요청을 수락하시겠습니까?',
//                   confirmText: '수락',
//                   cancelText: '거절',
//                 );

//                 if (result == true) {
//                   print('확인 클릭');
//                 } else {
//                   print('취소 클릭');
//                 }
//               },
//               child: const Text('확인/취소 다이얼로그'),
//             ),
//             const SizedBox(height: 16),

//             // 2. 알림 다이얼로그 (확인만)
//             ElevatedButton(
//               onPressed: () {
//                 DialogHelper.showAlertDialog(
//                   context,
//                   title: '알림',
//                   message: '친구 요청이 전송되었습니다.',
//                 );
//               },
//               child: const Text('알림 다이얼로그'),
//             ),
//             const SizedBox(height: 16),

//             // 3. 삭제 다이얼로그
//             ElevatedButton(
//               onPressed: () async {
//                 final result = await DialogHelper.showDeleteDialog(
//                   context,
//                   message: '정말 삭제하시겠습니까?',
//                   onConfirm: () {
//                     print('삭제 실행');
//                   },
//                 );

//                 if (result == true) {
//                   print('삭제됨');
//                 }
//               },
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//               child: const Text('삭제 다이얼로그'),
//             ),
//             const SizedBox(height: 16),

//             // 4. 경고 다이얼로그
//             ElevatedButton(
//               onPressed: () {
//                 DialogHelper.showWarningDialog(
//                   context,
//                   message: '이 작업은 되돌릴 수 없습니다.',
//                   onConfirm: () {
//                     print('경고 확인');
//                   },
//                 );
//               },
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//               child: const Text('경고 다이얼로그'),
//             ),
//             const SizedBox(height: 16),

//             // 5. 콜백 함수와 함께 사용
//             ElevatedButton(
//               onPressed: () {
//                 DialogHelper.showConfirmDialog(
//                   context,
//                   title: '로그아웃',
//                   message: '로그아웃 하시겠습니까?',
//                   confirmText: '로그아웃',
//                   onConfirm: () {
//                     // 로그아웃 로직
//                     print('로그아웃 실행');
//                   },
//                   onCancel: () {
//                     print('로그아웃 취소');
//                   },
//                 );
//               },
//               child: const Text('콜백 함수 사용'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
