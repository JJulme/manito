import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/router.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/core/notifications/app_notification_service.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/util/game_time_util.dart';
import 'package:manito/core/analytics/analytics_event.dart';
import 'package:manito/core/analytics/analytics_service.dart';
import 'package:manito/main.dart';
import 'package:manito/features/friends/presentation/screens/invite_friends_screen.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/setup/presentation/screens/mission_setup_screen.dart';

class GroupLobbyScreen extends ConsumerStatefulWidget {
  final String roomId;

  const GroupLobbyScreen({super.key, required this.roomId});

  @override
  ConsumerState<GroupLobbyScreen> createState() => _GroupLobbyScreenState();
}

class _GroupLobbyScreenState extends ConsumerState<GroupLobbyScreen> {
  bool _isStarting = false;
  bool _isHandlingExpiration = false;
  bool _isVoluntaryExit = false;
  bool _hasNavigatedToMissionSetup = false;
  RealtimeChannel? _roomChannel;
  Timer? _expirationCheckTimer;

  @override
  void initState() {
    super.initState();
    _subscribeToRealtimeChanges();
    _startExpirationTimer();
  }

  @override
  void dispose() {
    _expirationCheckTimer?.cancel();
    _roomChannel?.unsubscribe();
    super.dispose();
  }

  void _startExpirationTimer() {
    _expirationCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _isHandlingExpiration || _isVoluntaryExit) return;
      final room = ref.read(roomDetailsProvider(widget.roomId)).value;
      if (room != null && room.status == RoomStatus.waiting) {
        final elapsedMinutes = DateTime.now().difference(room.createdAt).inMinutes;
        if (elapsedMinutes >= 10) {
          _handleRoomExpiredOrDeleted(isTimeExpired: true);
        }
      }
      // 4초마다 멤버 목록 실시간 동기화 보강
      if (timer.tick % 2 == 0) {
        ref.invalidate(roomMembersProvider(widget.roomId));
      }
    });
  }

  void _subscribeToRealtimeChanges() {
    try {
      final supabase = ref.read(supabaseProvider);
      _roomChannel = supabase
          .channel('public:lobby_${widget.roomId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'rooms',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: widget.roomId,
            ),
            callback: (payload) {
              AppLogger.i('Realtime room update received: ${payload.eventType}', tag: 'ROOMS');
              if (payload.eventType == PostgresChangeEvent.delete) {
                if (!_isVoluntaryExit) {
                  _handleRoomExpiredOrDeleted(isTimeExpired: false);
                }
                return;
              }
              if (payload.eventType == PostgresChangeEvent.update) {
                final status = payload.newRecord['status'] as String?;
                if (status == 'PREPARING') {
                  _navigateToMissionSetup();
                  return;
                }
              }
              if (mounted) {
                ref.invalidate(roomDetailsProvider(widget.roomId));
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'room_members',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: widget.roomId,
            ),
            callback: (payload) {
              AppLogger.i('Realtime member update received: ${payload.eventType}', tag: 'ROOMS');
              if (mounted) {
                ref.invalidate(roomMembersProvider(widget.roomId));
              }
            },
          );

      _roomChannel?.subscribe();
    } catch (e) {
      AppLogger.e('Failed to subscribe to realtime lobby updates: $e', tag: 'ROOMS');
    }
  }

  void _navigateToMissionSetup() {
    if (_hasNavigatedToMissionSetup || _isVoluntaryExit || !mounted) return;
    _hasNavigatedToMissionSetup = true;
    _expirationCheckTimer?.cancel();
    _roomChannel?.unsubscribe();

    AppLogger.i('Navigating to MissionSetupScreen once for room: ${widget.roomId}', tag: 'ROOMS');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MissionSetupScreen(roomId: widget.roomId),
          ),
        );
      }
    });
  }

  void _handleRoomExpiredOrDeleted({bool isTimeExpired = false}) {
    if (_isVoluntaryExit || _isHandlingExpiration || !mounted) return;
    _isHandlingExpiration = true;
    _expirationCheckTimer?.cancel();
    _roomChannel?.unsubscribe();

    AppLogger.i('Room expired or deleted (isTimeExpired=$isTimeExpired). Navigating back to home...', tag: 'ROOMS');
    ref.read(appNotificationServiceProvider).cancelGameDeadlineNotifications(widget.roomId);
    ref.invalidate(ongoingRoomsProvider);
    ref.invalidate(receivedRoomInvitationsProvider);

    if (mounted) {
      // Pop all dialogs/screens back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.go('/bottom_nav2');

      // Show auto-deletion / host-deletion notice bottomsheet on home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final rootCtx = rootNavigatorKey.currentContext;
        if (rootCtx != null) {
          _showRoomExpiredBottomSheet(rootCtx, isTimeExpired: isTimeExpired);
        }
      });
    }
  }

  void _showRoomExpiredBottomSheet(BuildContext context, {bool isTimeExpired = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.statusRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTimeExpired ? Icons.timer_off_rounded : Icons.delete_outline_rounded,
                  color: AppColors.statusRed,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isTimeExpired ? '대기실이 자동 삭제되었습니다' : '대기실이 삭제되었습니다',
                style: AppTypography.headlineMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isTimeExpired
                    ? '대기실 개설 후 10분 동안 게임이 시작되지 않아\n대기실이 자동으로 폭파(삭제)되었습니다.\n\n새로운 방을 개설하거나 친구들을 다시 초대해보세요!'
                    : '방장에 의해 대기실이 삭제(폭파)되었습니다.\n\n새로운 방을 개설하거나 다른 초대를 확인해보세요!',
                style: AppTypography.bodyMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTitleDialog(BuildContext context, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('제목 수정', style: AppTypography.titleMd),
        content: TextField(
          controller: controller,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: '새로운 제목을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) return;

              Navigator.pop(ctx);
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
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('제목 수정 실패: $e')),
                  );
                }
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCategory(String category) async {
    try {
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvent.lobbyCategoryToggle,
        screenName: 'GroupLobbyScreen',
        properties: {'room_id': widget.roomId, 'category': category},
      );
      await ref.read(roomsRepositoryProvider).updateRoomSettings(
            roomId: widget.roomId,
            missionCategory: category,
          );
      ref.invalidate(roomDetailsProvider(widget.roomId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카테고리 수정 실패: $e')),
        );
      }
    }
  }

  /// 10분 단위 월/일/시/분 휠 피커 마감 시간 설정 모달 (최소 30분 ~ 최대 12시간)
  void _showDurationPickerModal(BuildContext context, DateTime? currentEndTime) {
    final now = DateTime.now();
    final minAllowedDeadline = GameTimeUtil.calculateCeiledDeadline(baseTime: now, minutesToAdd: 30);
    final maxAllowedDeadline = GameTimeUtil.calculateCeiledDeadline(baseTime: now, minutesToAdd: 720);

    DateTime initialDeadline = currentEndTime?.toLocal() ?? minAllowedDeadline;
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
    if (initialDeadline.isBefore(minAllowedDeadline)) {
      initialDeadline = minAllowedDeadline;
    } else if (initialDeadline.isAfter(maxAllowedDeadline)) {
      initialDeadline = maxAllowedDeadline;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        DateTime selectedDateTime = initialDeadline;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final currentNow = DateTime.now();
            final diff = selectedDateTime.difference(currentNow).inMinutes;
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
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
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
                                GameTimeUtil.formatKoreanDateTime(selectedDateTime),
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
                          initialDateTime: initialDeadline,
                          minimumDate: minAllowedDeadline,
                          maximumDate: maxAllowedDeadline,
                          onDateTimeChanged: (newDateTime) {
                            setModalState(() {
                              selectedDateTime = newDateTime;
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
                          Navigator.pop(ctx);
                          try {
                            ref.read(analyticsServiceProvider).logEvent(
                              AnalyticsEvent.lobbyDeadlineChange,
                              screenName: 'GroupLobbyScreen',
                              properties: {
                                'room_id': widget.roomId,
                                'new_deadline': selectedDateTime.toIso8601String(),
                              },
                            );
                            await ref.read(roomsRepositoryProvider).updateRoomSettings(
                                  roomId: widget.roomId,
                                  gameEndTime: selectedDateTime,
                                );
                            ref.invalidate(roomDetailsProvider(widget.roomId));
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('마감시간 수정 실패: $e')),
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
          },
        );
      },
    );
  }

  void _showInviteFriendsModal(BuildContext context, List<RoomMemberModel> existingMembers) {
    final existingUserIds = existingMembers.map((m) => m.userId).toSet();

    InviteFriendsScreen.showAsBottomSheet(
      context,
      roomId: widget.roomId,
      excludedUserIds: existingUserIds,
      onInviteSuccess: () {
        ref.invalidate(roomMembersProvider(widget.roomId));
      },
    );
  }

  Future<void> _startGame(List<RoomMemberModel> members) async {
    final acceptedMembers = members.where((m) => m.joinStatus == '✔️').toList();
    if (acceptedMembers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('마니또 매칭을 시작하려면 최소 2명 이상의 참가자(수락)가 필요합니다.'),
          backgroundColor: AppColors.statusRed,
        ),
      );
      return;
    }

    setState(() => _isStarting = true);
    try {
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvent.roomGameStart,
        screenName: 'GroupLobbyScreen',
        properties: {
          'room_id': widget.roomId,
          'member_count': acceptedMembers.length,
        },
      );
      await ref.read(roomsRepositoryProvider).startGameAndMatch(widget.roomId);
      ref.invalidate(roomDetailsProvider(widget.roomId));
      ref.invalidate(roomMembersProvider(widget.roomId));

      _navigateToMissionSetup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임 시작 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _showLeaveRoomBottomSheet(BuildContext context, bool isHost) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.statusRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.statusRed,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isHost ? '마니또 방 삭제 및 나가기' : '대기실 나가기',
                    style: AppTypography.headlineMd,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isHost
                        ? '⚠️ 방장이 대기실을 나가면 개설된 방이 완전히 삭제되며, 모든 참가자가 퇴장 처리됩니다.\n정말 방을 삭제하고 나가시겠습니까?'
                        : '대기실에서 퇴장하시겠습니까?\n언제든 다시 초대를 받아 참여할 수 있습니다.',
                    style: AppTypography.bodyMd.copyWith(
                      color: isHost ? AppColors.statusRed : AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.borderOf(context)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              '취소',
                              style: TextStyle(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    setModalState(() => isProcessing = true);
                                    _isVoluntaryExit = true;
                                    _isHandlingExpiration = true;
                                    _expirationCheckTimer?.cancel();
                                    _roomChannel?.unsubscribe();

                                    try {
                                      final repo = ref.read(roomsRepositoryProvider);
                                      ref.read(analyticsServiceProvider).logEvent(
                                        isHost ? AnalyticsEvent.roomDelete : AnalyticsEvent.roomLeave,
                                        screenName: 'GroupLobbyScreen',
                                        properties: {'room_id': widget.roomId},
                                      );
                                      if (isHost) {
                                        await repo.deleteRoom(widget.roomId);
                                      } else {
                                        await repo.leaveRoom(widget.roomId);
                                      }
                                      ref.read(appNotificationServiceProvider).cancelGameDeadlineNotifications(widget.roomId);
                                      ref.invalidate(ongoingRoomsProvider);
                                      ref.invalidate(receivedRoomInvitationsProvider);

                                      if (mounted) {
                                        Navigator.pop(ctx);
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                        context.go('/bottom_nav2');
                                        scaffoldMessengerKey.currentState?.showSnackBar(
                                          SnackBar(
                                            content: Text(isHost ? '방이 삭제되었습니다.' : '대기실에서 퇴장했습니다.'),
                                            backgroundColor: AppColors.textPrimary,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      _isVoluntaryExit = false;
                                      _isHandlingExpiration = false;
                                      setModalState(() => isProcessing = false);
                                      if (mounted) {
                                        scaffoldMessengerKey.currentState?.showSnackBar(
                                          SnackBar(content: Text('나가기 실패: $e')),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    isHost ? '방 삭제' : '나가기',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RoomModel?>>(roomDetailsProvider(widget.roomId), (prev, next) {
      next.whenData((room) {
        if (room != null && room.status == RoomStatus.preparing) {
          _navigateToMissionSetup();
        }
      });
    });

    final roomAsync = ref.watch(roomDetailsProvider(widget.roomId));
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final currentUserId = ref.watch(currentUserProvider)?.id;

    final room = roomAsync.value;
    final isHost = room?.hostId == currentUserId;
    final members = membersAsync.value ?? [];
    final acceptedMembers = members.where((m) => m.joinStatus == '✔️').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(room?.title ?? '대기실'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.statusRed),
            tooltip: isHost ? '방 삭제 및 나가기' : '대기실 나가기',
            onPressed: () => _showLeaveRoomBottomSheet(context, isHost),
          ),
        ],
      ),
      bottomNavigationBar: (room != null && isHost)
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
                border: Border(
                  top: BorderSide(color: AppColors.borderOf(context), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.25 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isStarting || acceptedMembers.length < 2
                        ? null
                        : () => _startGame(members),
                    icon: _isStarting
                        ? const SizedBox.shrink()
                        : const Icon(Icons.play_arrow_rounded, size: 22),
                    label: _isStarting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : Text(
                            acceptedMembers.length >= 2
                                ? '마니또 시작하기 (${acceptedMembers.length}명 수락)'
                                : '최소 2명 수락 필요 (${acceptedMembers.length}/2)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('대기실 로드 실패: $err')),
        data: (room) {
          if (room == null) {
            if (!_isVoluntaryExit) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleRoomExpiredOrDeleted(isTimeExpired: false);
              });
            }
            return const Center(child: Text('대기실 정보를 찾을 수 없습니다.'));
          }
          final isHost = room.hostId == currentUserId;

          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('멤버 로드 실패: $err')),
            data: (members) {
              final category = room.missionCategory?.toLowerCase() ?? 'daily';
              final deadline = room.gameEndTime ?? GameTimeUtil.calculateCeiledDeadline(minutesToAdd: 30);

              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 0. Circular Countdown Timer Banner if WAITING
                    if (room.status == RoomStatus.waiting) ...[
                      LobbyCircularTimerBanner(
                        createdAt: room.createdAt,
                        onExpired: _handleRoomExpiredOrDeleted,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 1. Room Settings & Parameters Card
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderOf(context)),
                        boxShadow: AppColors.cardShadowOf(context),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 20,
                                    color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '마니또 옵션',
                                    style: AppTypography.titleSm.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                ],
                              ),
                              if (isHost)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.isDark(context)
                                        ? AppColors.darkPrimaryLight
                                        : AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '방장',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDarkOf(context),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // A. Room Title Setting
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('제목', style: AppTypography.labelMd.copyWith(color: AppColors.textSecondaryOf(context))),
                              if (isHost)
                                InkWell(
                                  onTap: () => _showEditTitleDialog(context, room.title),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 14, color: AppColors.textSecondaryOf(context)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '수정',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaryOf(context),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLowOf(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderOf(context)),
                            ),
                            child: Text(
                              room.title,
                              style: AppTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // B. Mission Category Setting
                          Text('미션 카테고리', style: AppTypography.labelMd.copyWith(color: AppColors.textSecondaryOf(context))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildCategoryButton('일상 (Daily)', 'daily', category == 'daily', isEnabled: isHost),
                              const SizedBox(width: 8),
                              _buildCategoryButton('학교 (School)', 'school', category == 'school', isEnabled: isHost),
                              const SizedBox(width: 8),
                              _buildCategoryButton('직장 (Work)', 'work', category == 'work', isEnabled: isHost),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // C. Game Duration & Ceiled Deadline Setting (10-min ceiled interval, 30m ~ 12h)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('마감 시간', style: AppTypography.labelMd.copyWith(color: AppColors.textSecondaryOf(context))),
                              if (isHost)
                                InkWell(
                                  onTap: () => _showDurationPickerModal(context, room.gameEndTime),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      children: [
                                        Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondaryOf(context)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '설정',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaryOf(context),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLowOf(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderOf(context)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.alarm_on_rounded,
                                      size: 18,
                                      color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '마감 시간: ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}',
                                      style: AppTypography.bodyMd.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimaryOf(context),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.isDark(context)
                                        ? AppColors.darkPrimaryLight
                                        : AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${deadline.month}/${deadline.day}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDarkOf(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Operatives Header & Invite Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '참여 인원 (${members.length}명)',
                          style: AppTypography.titleMd.copyWith(color: AppColors.textPrimaryOf(context)),
                        ),
                        if (isHost && room.status == RoomStatus.waiting)
                          InkWell(
                            onTap: () => _showInviteFriendsModal(context, members),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.person_add_rounded, size: 14, color: AppColors.textSecondaryOf(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '친구 추가',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryOf(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. Operatives List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final member = members[idx];
                        final isMe = member.userId == currentUserId;
                        final isMemberHost = member.userId == room.hostId;
                        final profile = member.userProfile;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isMe
                                  ? (AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark)
                                  : AppColors.borderOf(context),
                              width: isMe ? 1.5 : 1.0,
                            ),
                            boxShadow: AppColors.cardShadowOf(context),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(
                                imageUrl: profile?.profileImageUrl,
                                size: 44,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          profile?.name ?? (isMe ? '나' : '요원'),
                                          style: AppTypography.titleSm.copyWith(
                                            color: AppColors.textPrimaryOf(context),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (isMemberHost) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.isDark(context)
                                                  ? AppColors.darkPrimaryLight
                                                  : AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '방장',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryDarkOf(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile?.statusMessage?.isNotEmpty == true
                                          ? profile!.statusMessage!
                                          : '코드: ${profile?.uniqueCode ?? "-"}',
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.textSecondaryOf(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: member.joinStatus == '✔️'
                                      ? AppColors.statusGreen.withValues(alpha: 0.15)
                                      : member.joinStatus == 'X'
                                          ? AppColors.statusRed.withValues(alpha: 0.15)
                                          : AppColors.surfaceLowOf(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  member.joinStatus == '✔️'
                                      ? '수락됨'
                                      : member.joinStatus == 'X'
                                          ? '거절됨'
                                          : '대기중',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: member.joinStatus == '✔️'
                                        ? AppColors.statusGreen
                                        : member.joinStatus == 'X'
                                            ? AppColors.statusRed
                                            : AppColors.textSecondaryOf(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // 4. Waiting Notice for Non-host Members
                    if (!isHost) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowOf(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderOf(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.hourglass_top_rounded,
                              color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '방장이 참가자들을 모아 게임을 시작할 때까지 잠시만 대기해주세요.',
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryButton(
    String label,
    String value,
    bool isSelected, {
    bool isEnabled = true,
  }) {
    return Expanded(
      child: InkWell(
        onTap: isEnabled ? () => _updateCategory(value) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceLowOf(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryDark : AppColors.borderOf(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E1E24) : AppColors.textSecondaryOf(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// 10분 대기실 실시간 원형 타이머 링 & 60초 긴급 카운트다운 위젯
class LobbyCircularTimerBanner extends StatefulWidget {
  final DateTime createdAt;
  final VoidCallback? onExpired;

  const LobbyCircularTimerBanner({
    super.key,
    required this.createdAt,
    this.onExpired,
  });

  @override
  State<LobbyCircularTimerBanner> createState() => _LobbyCircularTimerBannerState();
}

class _LobbyCircularTimerBannerState extends State<LobbyCircularTimerBanner> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        final elapsedSec = DateTime.now().difference(widget.createdAt).inSeconds;
        if (elapsedSec >= 600) {
          widget.onExpired?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsedSec = DateTime.now().difference(widget.createdAt).inSeconds;
    final remainingSec = (600 - elapsedSec).clamp(0, 600);
    final progress = remainingSec / 600.0;
    final isUrgent = remainingSec <= 60;
    final isDark = AppColors.isDark(context);

    final themeColor = isUrgent
        ? AppColors.statusRed
        : (isDark ? AppColors.primary : AppColors.primaryDark);
    final bgColor = isUrgent
        ? AppColors.statusRed.withValues(alpha: 0.1)
        : (isDark ? AppColors.primary.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.15));
    final borderColor = isUrgent
        ? AppColors.statusRed.withValues(alpha: 0.5)
        : (isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.4));
    final trackColor = isUrgent
        ? AppColors.statusRed.withValues(alpha: 0.2)
        : (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.25));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: isUrgent ? 1.5 : 1.0),
      ),
      child: Row(
        children: [
          // 1. Text Information (Left-aligned)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isUrgent ? '⚠️ 대기실 폭파 임박!' : '⏱️ 대기실 유효시간',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUrgent
                      ? '지금 게임을 시작하지 않으면 방이 자동으로 삭제됩니다.'
                      : '10분 내 미시작 시 방이 자동으로 폭파(삭제)됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isUrgent
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                        : AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 2. True Clockwise Countdown Progress Ring (Right-aligned)
          SizedBox(
            width: 48,
            height: 48,
            child: CustomPaint(
              painter: ClockwiseTimerPainter(
                progress: progress,
                trackColor: trackColor,
                progressColor: themeColor,
                strokeWidth: 4.0,
              ),
              child: Center(
                child: isUrgent
                    ? Text(
                        '$remainingSec',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.statusRed,
                          height: 1.0,
                        ),
                      )
                    : Text(
                        '${(remainingSec / 60).ceil()}분',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          height: 1.0,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 12시 방향에서 시작하여 시계방향으로 줄어드는 원형 타이머 페인터
class ClockwiseTimerPainter extends CustomPainter {
  final double progress; // 1.0 (가득 참) -> 0.0 (비어있음)
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  ClockwiseTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. 전체 트랙 원 그리기
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // 2. 12시 방향부터 시계방향으로 줄어드는 호(Arc) 그리기
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 12시 방향(-pi/2)에서 경과된 각도만큼 이동한 위치에서 시작하여 남은 각도만큼 시계방향으로 그림
    const startOffset = -math.pi / 2;
    final elapsedAngle = (1.0 - progress) * 2 * math.pi;
    final startAngle = startOffset + elapsedAngle;
    final sweepAngle = progress * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ClockwiseTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
