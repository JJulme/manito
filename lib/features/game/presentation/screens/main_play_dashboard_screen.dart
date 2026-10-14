import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/util/game_time_util.dart';
import 'package:manito/core/util/text_sanitizer.dart';
import 'package:manito/core/analytics/analytics_event.dart';
import 'package:manito/core/analytics/analytics_service.dart';
import 'package:manito/features/feed/presentation/feed_provider.dart';
import 'package:manito/features/feed/presentation/screens/result_feed_screen.dart';
import 'package:manito/features/game/presentation/game_provider.dart';
import 'package:manito/features/game/presentation/widgets/block_editor_view.dart';
import 'package:manito/features/game/presentation/widgets/game_timer_header.dart';
import 'package:manito/features/game/presentation/widgets/suspect_selection_modal.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/setup/presentation/setup_provider.dart';
import 'package:manito/features/setup/presentation/screens/mission_setup_screen.dart';
import 'package:manito/core/notifications/app_notification_service.dart';
import 'package:manito/core/widget/network_error_view.dart';
import 'package:manito/core/widget/user_avatar.dart';

class MainPlayDashboardScreen extends ConsumerStatefulWidget {
  final String roomId;

  const MainPlayDashboardScreen({super.key, required this.roomId});

  @override
  ConsumerState<MainPlayDashboardScreen> createState() => _MainPlayDashboardScreenState();
}

class _MainPlayDashboardScreenState extends ConsumerState<MainPlayDashboardScreen> {
  int _selectedTab = 0; // 0: 미션 기록, 1: 마니또 추측
  List<RecordBlock> _performBlocks = [];
  List<RecordBlock> _guessBlocks = [];
  String? _selectedSuspectId;
  Timer? _countdownTimer;
  Duration _remainingDuration = Duration.zero;
  bool _showValidationErrors = false;
  bool _isLoadingRecords = true;
  bool _isHandlingDeadline = false;
  bool _hasNavigatedToResult = false;
  bool _hasScheduledNotifications = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _loadExistingRecords();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _scheduleDeadlineNotificationsOnce(RoomModel room) {
    if (_hasScheduledNotifications) return;
    if (room.status != RoomStatus.ongoing || room.gameEndTime == null) return;
    _hasScheduledNotifications = true;

    ref.read(appNotificationServiceProvider).scheduleGameDeadlineNotifications(
      roomId: room.roomId,
      roomTitle: room.title,
      gameEndTime: room.gameEndTime!,
    );
  }

  Future<void> _loadExistingRecords() async {
    try {
      final repo = ref.read(gameRepositoryProvider);
      final performRecord = await repo.fetchMyRecord(widget.roomId, RecordType.missionPerform);
      final guessRecord = await repo.fetchMyRecord(widget.roomId, RecordType.suspectGuess);

      if (mounted) {
        setState(() {
          if (performRecord != null && performRecord.content.isNotEmpty) {
            _performBlocks = List.from(performRecord.content);
          }
          if (guessRecord != null) {
            if (guessRecord.content.isNotEmpty) {
              _guessBlocks = List.from(guessRecord.content);
            }
            if (guessRecord.suspectUserId != null && guessRecord.suspectUserId!.isNotEmpty) {
              _selectedSuspectId = guessRecord.suspectUserId;
            }
          }
          _isLoadingRecords = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecords = false);
      }
    }
  }

  void _startCountdown() {
    _updateRemainingTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingTime();
      }
    });
  }

  void _updateRemainingTime() {
    final room = ref.read(roomDetailsProvider(widget.roomId)).value;
    if (room != null) {
      _scheduleDeadlineNotificationsOnce(room);
    }

    final deadline = room?.gameEndTime;
    if (deadline == null) return;

    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative || diff <= Duration.zero) {
      if (_remainingDuration != Duration.zero) {
        setState(() => _remainingDuration = Duration.zero);
      }
      if (room?.status == RoomStatus.ongoing && !_hasNavigatedToResult && !_isHandlingDeadline) {
        _handleDeadlineReached();
      }
    } else {
      setState(() => _remainingDuration = diff);
    }
  }

  /// 마감 시간 도달 시 자동응답 프리셋 채우기 및 [기록 상세] 화면으로 전환
  Future<void> _handleDeadlineReached() async {
    if (_hasNavigatedToResult || _isHandlingDeadline) return;
    _isHandlingDeadline = true;
    _countdownTimer?.cancel();

    try {
      AppLogger.i('Handling deadline reached for room: ${widget.roomId}', tag: 'GAME');
      final room = ref.read(roomDetailsProvider(widget.roomId)).value;
      final roomTitle = room?.title ?? '마니또';

      // 1. 서버 RPC 호출: 참여자 전원의 미작성 자동응답 일괄 생성 및 방 상태 ENDED 처리
      await ref.read(roomsRepositoryProvider).finalizeGameAndFillAutoReplies(widget.roomId);

      // 2. 마감 완료 푸시 알림 발송
      await ref.read(appNotificationServiceProvider).showImmediateDeadlineCompleteNotification(
        roomId: widget.roomId,
        roomTitle: roomTitle,
      );

      // 3. 프로바이더 새로고침
      ref.invalidate(roomRecordsProvider(widget.roomId));
      ref.invalidate(roomDetailsProvider(widget.roomId));
      ref.invalidate(ongoingRoomsProvider);
      ref.invalidate(completedRoomsProvider);
    } catch (e, s) {
      AppLogger.e('Auto-reply save error on deadline: $e', tag: 'GAME', error: e, stackTrace: s);
    }

    if (mounted) {
      _hasNavigatedToResult = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultFeedScreen(roomId: widget.roomId),
        ),
      );
    }
  }

  /// 3대 필수 조건 검증 및 일괄 저장
  Future<void> _submitAllRecords() async {
    final hasPerformImage = _performBlocks.any((b) => b.type == BlockType.image && b.value.trim().isNotEmpty);
    final hasGuessImage = _guessBlocks.any((b) => b.type == BlockType.image && b.value.trim().isNotEmpty);
    final isSuspectSelected = _selectedSuspectId != null && _selectedSuspectId!.trim().isNotEmpty;

    if (!hasPerformImage || !isSuspectSelected || !hasGuessImage) {
      setState(() => _showValidationErrors = true);
      if (!hasPerformImage) {
        if (_selectedTab != 0) setState(() => _selectedTab = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💡 [미션 기록] 탭에 인증 사진을 1장 이상 첨부해 주세요!'),
            backgroundColor: AppColors.statusRed,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (!isSuspectSelected) {
        if (_selectedTab != 1) setState(() => _selectedTab = 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💡 [마니또 추측] 탭에서 마니또로 의심되는 친구를 선택해 주세요!'),
            backgroundColor: AppColors.statusRed,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (!hasGuessImage) {
        if (_selectedTab != 1) setState(() => _selectedTab = 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('💡 [마니또 추측] 탭에 사진 단서를 1장 이상 첨부해 주세요!'),
            backgroundColor: AppColors.statusRed,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final sanitizedPerformBlocks = _performBlocks.map((b) {
      if (b.type == BlockType.text) {
        return RecordBlock(type: BlockType.text, value: TextSanitizer.sanitizeMultiLine(b.value));
      }
      return b;
    }).toList();

    final sanitizedGuessBlocks = _guessBlocks.map((b) {
      if (b.type == BlockType.text) {
        return RecordBlock(type: BlockType.text, value: TextSanitizer.sanitizeMultiLine(b.value));
      }
      return b;
    }).toList();

    final success1 = await ref.read(gameRecordFormProvider.notifier).save(
          roomId: widget.roomId,
          recordType: RecordType.missionPerform,
          content: sanitizedPerformBlocks,
        );

    final success2 = await ref.read(gameRecordFormProvider.notifier).save(
          roomId: widget.roomId,
          recordType: RecordType.suspectGuess,
          suspectUserId: _selectedSuspectId,
          content: sanitizedGuessBlocks,
        );

    if (mounted) {
      if (success1 && success2) {
        ref.read(analyticsServiceProvider).logEvent(
          AnalyticsEvent.postWriteComplete,
          screenName: 'MainPlayDashboardScreen',
          properties: {
            'room_id': widget.roomId,
            'perform_blocks_count': _performBlocks.length,
            'guess_blocks_count': _guessBlocks.length,
            'has_suspect': _selectedSuspectId != null,
          },
        );
        setState(() => _showValidationErrors = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미션 기록 및 마니또 지목이 모두 안전하게 저장되었습니다!'),
            backgroundColor: AppColors.statusGreen,
          ),
        );
      } else {
        final err = ref.read(gameRecordFormProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${err ?? "오류가 발생했습니다."}'),
            backgroundColor: AppColors.statusRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RoomModel?>>(roomDetailsProvider(widget.roomId), (prev, next) {
      final r = next.valueOrNull;
      if (r != null && r.status == RoomStatus.ended && !_hasNavigatedToResult && !_isHandlingDeadline) {
        _handleDeadlineReached();
      }
      if (r != null && r.status == RoomStatus.preparing && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MissionSetupScreen(roomId: widget.roomId),
          ),
        );
      }
    });

    ref.listen<AsyncValue<RoomMemberModel?>>(myMemberRecordProvider(widget.roomId), (prev, next) {
      final member = next.valueOrNull;
      final currentRoom = ref.read(roomDetailsProvider(widget.roomId)).valueOrNull;
      if (member != null && !member.isMissionSelected && mounted) {
        if (currentRoom?.status == RoomStatus.ongoing) {
          // 게임 진행 중이면 미션을 백그라운드에서 자동 랜덤 확정 처리
          ref.read(missionSetupProvider.notifier).confirmSelection(member.roomMemberId, widget.roomId, null);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MissionSetupScreen(roomId: widget.roomId),
            ),
          );
        }
      }
    });

    final roomAsync = ref.watch(roomDetailsProvider(widget.roomId));
    final myMemberAsync = ref.watch(myMemberRecordProvider(widget.roomId));
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final formState = ref.watch(gameRecordFormProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final lang = ref.watch(languageCodeProvider);

    final room = roomAsync.value;
    if (room != null && room.status == RoomStatus.preparing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MissionSetupScreen(roomId: widget.roomId),
            ),
          );
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final myMember = myMemberAsync.value;
    if (myMember != null && !myMember.isMissionSelected) {
      if (room?.status == RoomStatus.ongoing) {
        // 이미 진행 중인 게임이므로 미션을 백그라운드 자동 배정하고 대시보드 화면 유지
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(missionSetupProvider.notifier).confirmSelection(myMember.roomMemberId, widget.roomId, null);
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MissionSetupScreen(roomId: widget.roomId),
              ),
            );
          }
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }
    }
    final deadline = room?.gameEndTime ??
        (room?.createdAt.add(const Duration(minutes: 30)) ??
            GameTimeUtil.calculateCeiledDeadline(minutesToAdd: 30));

    final hasPerformImage = _performBlocks.any((b) => b.type == BlockType.image && b.value.trim().isNotEmpty);
    final hasGuessImage = _guessBlocks.any((b) => b.type == BlockType.image && b.value.trim().isNotEmpty);
    final isSuspectSelected = _selectedSuspectId != null && _selectedSuspectId!.trim().isNotEmpty;

    final isPerformValid = hasPerformImage;
    final isGuessValid = isSuspectSelected && hasGuessImage;
    final allConditionsMet = isPerformValid && isGuessValid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevron_left),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: GameTimerHeaderBadge(
          deadline: deadline,
          remainingDuration: _remainingDuration,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: formState.isSaving ? null : _submitAllRecords,
              style: TextButton.styleFrom(
                foregroundColor: allConditionsMet
                    ? (AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark)
                    : AppColors.textSecondaryOf(context),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: formState.isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                      ),
                    )
                  : Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: allConditionsMet
                            ? (AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark)
                            : AppColors.textSecondaryOf(context).withValues(alpha: 0.6),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingRecords
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : roomAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => NetworkErrorView(
                title: '방 정보를 불러오지 못했어요',
                onRetry: () => ref.invalidate(roomDetailsProvider(widget.roomId)),
              ),
              data: (room) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 탭 전환 바 (미션 기록 / 마니또 추측)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowOf(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.borderOf(context)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          index: 0,
                          title: '미션 기록',
                          isSelected: _selectedTab == 0,
                          hasError: _showValidationErrors && !isPerformValid,
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          index: 1,
                          title: '마니또 추측',
                          isSelected: _selectedTab == 1,
                          hasError: _showValidationErrors && !isGuessValid,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab 0 & Tab 1 Content (IndexedStack으로 탭 간 개별 상태 및 텍스트 100% 분리 유지)
                IndexedStack(
                  index: _selectedTab,
                  children: [
                    // Tab 0: 미션 기록
                    myMemberAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (err, _) => Text('미션 로드 실패: $err'),
                      data: (myMember) {
                        final targetUser = myMember?.targetUserProfile;
                        final mission = myMember?.assignedMission;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 타겟 프로필 카드
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderOf(context)),
                                boxShadow: AppColors.cardShadowOf(context),
                              ),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    imageUrl: targetUser?.profileImageUrl,
                                    size: 44,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          targetUser?.name ?? '요원',
                                          style: AppTypography.titleSmall.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimaryOf(context),
                                          ),
                                        ),
                                        if (targetUser?.statusMessage != null &&
                                            targetUser!.statusMessage!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            targetUser.statusMessage!,
                                            style: AppTypography.bodySm.copyWith(
                                              color: AppColors.textSecondaryOf(context),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 미션 내용 표시
                            if (mission != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLowOf(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderOf(context)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(LucideIcons.clipboard_list, size: 20, color: AppColors.primaryDark),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        mission.getContent(lang),
                                        style: AppTypography.bodyMd.copyWith(
                                          color: AppColors.textPrimaryOf(context),
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Block Editor (Tab 0 전용 독립 에디터)
                            BlockEditorView(
                              key: const ValueKey('perform_block_editor'),
                              initialBlocks: _performBlocks,
                              hintText: '미션을 어떻게 했는지 작성해 주세요.',
                              hasError: _showValidationErrors && !hasPerformImage,
                              errorMessage: '⚠️ 저장하려면 미션 인증 사진을 1장 이상 등록해야 합니다',
                              onBlocksChanged: (blocks) => setState(() => _performBlocks = blocks),
                              onUploadImage: (file) =>
                                  ref.read(gameRepositoryProvider).uploadEvidenceImage(file),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),

                    // Tab 1: 마니또 추측
                    membersAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (err, _) => Text('멤버 로드 실패: $err'),
                      data: (members) {
                        final otherMembers = members.where((m) => m.userId != currentUserId).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 친구 선택 프로필 카드 ([미션 기록]과 동일한 디자인 적용 + 에러 시 붉은색 테두리)
                            SuspectSelectionCard(
                              otherMembers: otherMembers,
                              selectedSuspectId: _selectedSuspectId,
                              hasError: _showValidationErrors && !isSuspectSelected,
                              onSuspectSelected: (suspectId) {
                                ref.read(analyticsServiceProvider).logEvent(
                                  AnalyticsEvent.suspectSelect,
                                  screenName: 'MainPlayDashboardScreen',
                                  properties: {
                                    'room_id': widget.roomId,
                                    'suspect_user_id': suspectId,
                                  },
                                );
                                setState(() => _selectedSuspectId = suspectId);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Block Editor (Tab 1 전용 독립 에디터)
                            BlockEditorView(
                              key: const ValueKey('guess_block_editor'),
                              initialBlocks: _guessBlocks,
                              hintText: '마니또로 추측되는 이유를 작성해 주세요.',
                              hasError: _showValidationErrors && !hasGuessImage,
                              errorMessage: '⚠️ 저장하려면 추측 단서 사진을 1장 이상 등록해야 합니다',
                              onBlocksChanged: (blocks) => setState(() => _guessBlocks = blocks),
                              onUploadImage: (file) =>
                                  ref.read(gameRepositoryProvider).uploadEvidenceImage(file),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required bool isSelected,
    required bool hasError,
  }) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : const Color(0xFF222222))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTypography.labelSm.copyWith(
                color: isSelected
                    ? (isDark ? const Color(0xFF1E1E24) : Colors.white)
                    : AppColors.textSecondaryOf(context),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (hasError) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.statusRed,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
