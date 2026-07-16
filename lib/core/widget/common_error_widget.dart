import 'package:flutter/material.dart';

class CommonErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry; // 다시 시도 버튼을 위한 콜백

  const CommonErrorWidget({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            '문제가 발생했습니다',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // 에러 메시지를 짧게 요약해서 보여주거나,
          // 개발 중에만 상세 내용을 보여주도록 설정할 수 있습니다.
          Text(
            error.toString().split('\n').first, // 첫 줄만 표시
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}
