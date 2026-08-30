import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/analytics/analytics_event.dart';
import 'package:manito/core/analytics/analytics_service.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/util/text_sanitizer.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';

/// 대기실 제목 수정 다이얼로그
class LobbyEditTitleDialog extends ConsumerStatefulWidget {
  final String roomId;
  final String currentTitle;

  const LobbyEditTitleDialog({
    super.key,
    required this.roomId,
    required this.currentTitle,
  });

  static Future<void> show(BuildContext context, {required String roomId, required String currentTitle}) {
    return showDialog(
      context: context,
      builder: (ctx) => LobbyEditTitleDialog(roomId: roomId, currentTitle: currentTitle),
    );
  }

  @override
  ConsumerState<LobbyEditTitleDialog> createState() => _LobbyEditTitleDialogState();
}

class _LobbyEditTitleDialogState extends ConsumerState<LobbyEditTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('제목 수정', style: AppTypography.titleMd),
      content: TextField(
        controller: _controller,
        maxLength: 30,
        decoration: const InputDecoration(
          hintText: '새로운 제목을 입력하세요',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newTitle = TextSanitizer.sanitizeSingleLine(_controller.text);
            if (newTitle.isEmpty) return;

            Navigator.pop(context);
            try {
              ref.read(analyticsServiceProvider).logEvent(
                AnalyticsEvent.lobbyTitleEdit,
                screenName: 'GroupLobbyScreen',
                properties: {'room_id': widget.roomId, 'new_title': newTitle},
              );
              await ref.read(roomsRepositoryProvider).updateRoomSettings(
                    roomId: widget.roomId,
                    title: newTitle,
                  );
              ref.invalidate(roomDetailsProvider(widget.roomId));
            } catch (e, s) {
              if (context.mounted) {
                AppLogger.e('제목 수정 실패', error: e, stackTrace: s);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('제목 수정에 실패했습니다. 다시 시도해 주세요.')),
                );
              }
            }
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
