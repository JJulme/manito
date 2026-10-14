import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/analytics/analytics_event.dart';
import 'package:manito/core/analytics/analytics_service.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/util/game_time_util.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';

/// 10분 단위 월/일/시/분 휠 피커 마감 시간 설정 모달 (최소 30분 ~ 최대 12시간)
class LobbyDurationPickerModal extends ConsumerStatefulWidget {
  final String roomId;
  final DateTime? currentEndTime;

  const LobbyDurationPickerModal({
    super.key,
    required this.roomId,
    this.currentEndTime,
  });

  static Future<void> show(BuildContext context, {required String roomId, DateTime? currentEndTime}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => LobbyDurationPickerModal(roomId: roomId, currentEndTime: currentEndTime),
    );
  }

  @override
  ConsumerState<LobbyDurationPickerModal> createState() => _LobbyDurationPickerModalState();
}

class _LobbyDurationPickerModalState extends ConsumerState<LobbyDurationPickerModal> {
  late final DateTime _minAllowedDeadline;
  late final DateTime _maxAllowedDeadline;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _minAllowedDeadline = GameTimeUtil.calculateCeiledDeadline(baseTime: now, minutesToAdd: 30);
    _maxAllowedDeadline = GameTimeUtil.calculateCeiledDeadline(baseTime: now, minutesToAdd: 720);

    DateTime initialDeadline = widget.currentEndTime?.toLocal() ?? _minAllowedDeadline;
    if (initialDeadline.isUtc) {
      initialDeadline = initialDeadline.toLocal();
    }
    // 10분 단위 및 최소/최대 범위 보정
    final remainder = initialDeadline.minute % 10;
    if (remainder != 0) {
      initialDeadline = initialDeadline.add(Duration(minutes: 10 - remainder));
    }
    initialDeadline = DateTime(
      initialDeadline.year,
      initialDeadline.month,
      initialDeadline.day,
      initialDeadline.hour,
      initialDeadline.minute,
      0,
      0,
    );
    if (initialDeadline.isBefore(_minAllowedDeadline)) {
      initialDeadline = _minAllowedDeadline;
    } else if (initialDeadline.isAfter(_maxAllowedDeadline)) {
      initialDeadline = _maxAllowedDeadline;
    }
    _selectedDateTime = initialDeadline;
  }

  @override
  Widget build(BuildContext context) {
    final currentNow = DateTime.now();
    final diff = _selectedDateTime.difference(currentNow).inMinutes;
    final durationMinutes = diff > 0 ? diff : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('마감시간 설정', style: AppTypography.headlineMd),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '최소 30분부터 최대 12시간까지 10분 단위로 설정할 수 있습니다.',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: 16),

            // Selected Time Summary Box
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('진행 시간', style: AppTypography.labelMd.copyWith(color: AppColors.textSecondaryOf(context))),
                      Text(
                        GameTimeUtil.formatDuration(durationMinutes),
                        style: AppTypography.titleSm.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 18, color: AppColors.borderOf(context)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🎯 마감 시간', style: AppTypography.labelMd.copyWith(color: AppColors.textPrimaryOf(context))),
                      Text(
                        GameTimeUtil.formatKoreanDateTime(_selectedDateTime),
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cupertino 10-Minute Wheel Picker (월, 일, 시, 10분 단위 분)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceLowOf(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: AppColors.isDark(context) ? Brightness.dark : Brightness.light,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: 18,
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  use24hFormat: false,
                  minuteInterval: 10,
                  initialDateTime: _selectedDateTime,
                  minimumDate: _minAllowedDeadline,
                  maximumDate: _maxAllowedDeadline,
                  onDateTimeChanged: (newDateTime) {
                    setState(() {
                      _selectedDateTime = newDateTime;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    ref.read(analyticsServiceProvider).logEvent(
                      AnalyticsEvent.lobbyDeadlineChange,
                      screenName: 'GroupLobbyScreen',
                      properties: {
                        'room_id': widget.roomId,
                        'new_deadline': _selectedDateTime.toIso8601String(),
                      },
                    );
                    await ref.read(roomsRepositoryProvider).updateRoomSettings(
                          roomId: widget.roomId,
                          gameEndTime: _selectedDateTime,
                        );
                    ref.invalidate(roomDetailsProvider(widget.roomId));
                  } catch (e, s) {
                    if (context.mounted) {
                      AppLogger.e('마감시간 수정 실패', error: e, stackTrace: s);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('마감시간 수정에 실패했습니다. 다시 시도해 주세요.')),
                      );
                    }
                  }
                },
                child: const Text('설정 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
