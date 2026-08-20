import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/util/game_time_util.dart';
import 'package:manito/features/feed/presentation/feed_provider.dart';
import 'package:manito/features/feed/presentation/screens/result_feed_screen.dart';
import 'package:manito/features/game/presentation/game_provider.dart';
import 'package:manito/features/game/presentation/widgets/block_editor_view.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/setup/presentation/setup_provider.dart';
import 'package:manito/core/notifications/app_notification_service.dart';

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

    final deadline = room?.gameEndTime ??
        (room?.createdAt.add(const Duration(minutes: 30)) ??
            GameTimeUtil.calculateCeiledDeadline(minutesToAdd: 30));

    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative || diff <= Duration.zero) {
      if (_remainingDuration != Duration.zero) {
        setState(() => _remainingDuration = Duration.zero);
      }
      if (!_hasNavigatedToResult && !_isHandlingDeadline) {
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

  String _formatRemainingDuration(Duration d) {
    if (d.inSeconds <= 0) return '00:00:00 (마감)';
    final days = d.inDays;
    final hours = (d.inHours % 24).toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');

    if (days > 0) {
      return '$days일 $hours:$minutes:$seconds';
    }
    return '${d.inHours.toString().padLeft(2, '0')}:$minutes:$seconds';
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

    final success1 = await ref.read(gameRecordFormProvider.notifier).save(
          roomId: widget.roomId,
          recordType: RecordType.missionPerform,
          content: _performBlocks,
        );

    final success2 = await ref.read(gameRecordFormProvider.notifier).save(
          roomId: widget.roomId,
          recordType: RecordType.suspectGuess,
          suspectUserId: _selectedSuspectId,
          content: _guessBlocks,
        );

    if (mounted) {
      if (success1 && success2) {
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
    ref.listen(roomDetailsProvider(widget.roomId), (prev, next) {
      final r = next.value;
      if (r != null && r.status == RoomStatus.ended && !_hasNavigatedToResult && !_isHandlingDeadline) {
        _handleDeadlineReached();
      }
    });

    final roomAsync = ref.watch(roomDetailsProvider(widget.roomId));
    final myMemberAsync = ref.watch(myMemberRecordProvider(widget.roomId));
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final formState = ref.watch(gameRecordFormProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final lang = ref.watch(languageCodeProvider);

    final room = roomAsync.value;
    final deadline = room?.gameEndTime ??
        (room?.createdAt.add(const Duration(minutes: 30)) ??
            GameTimeUtil.calculateCeiledDeadline(minutesToAdd: 30));
    final isUrgent = _remainingDuration.inMinutes <= 10 && _remainingDuration > Duration.zero;

    final hasPerformImage = _performBlocks.any((b) => b.type == BlockType.image && b.value.trim().isNotEmpty);
    final hasGuessImage = _guessBlocks.any((b) => b.type == BlockType.image && b.value.trim().isNotEmpty);
    final isSuspectSelected = _selectedSuspectId != null && _selectedSuspectId!.trim().isNotEmpty;

    final isPerformValid = hasPerformImage;
    final isGuessValid = isSuspectSelected && hasGuessImage;
    final allConditionsMet = isPerformValid && isGuessValid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Tooltip(
          message: '마감 시간: ${GameTimeUtil.formatKoreanDateTime(deadline)}',
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isUrgent
                  ? AppColors.statusRed.withValues(alpha: 0.12)
                  : AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUrgent ? AppColors.statusRed : AppColors.border,
                width: isUrgent ? 1.2 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: isUrgent ? AppColors.statusRed : AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatRemainingDuration(_remainingDuration),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isUrgent ? AppColors.statusRed : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: formState.isSaving ? null : _submitAllRecords,
              style: TextButton.styleFrom(
                foregroundColor: allConditionsMet ? AppColors.primaryDark : AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: formState.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                    )
                  : Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: allConditionsMet
                            ? AppColors.primaryDark
                            : AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoadingRecords
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : roomAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('방 정보 로드 실패: $err')),
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
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
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: ClipOval(
                                      child: targetUser?.profileImageUrl != null
                                          ? (targetUser!.profileImageUrl!.startsWith('http')
                                              ? CachedNetworkImage(
                                                  imageUrl: targetUser.profileImageUrl!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) => Container(color: AppColors.surface),
                                                  errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textSecondary),
                                                )
                                              : Image.asset(targetUser.profileImageUrl!, fit: BoxFit.cover))
                                          : const Icon(Icons.person, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          targetUser?.name ?? '요원',
                                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        if (targetUser?.statusMessage != null &&
                                            targetUser!.statusMessage!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            targetUser.statusMessage!,
                                            style: AppTypography.bodySm,
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.assignment_outlined, size: 20, color: AppColors.primaryDark),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        mission.getContent(lang),
                                        style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w600,
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
                            _buildSuspectSelectionCard(
                              context,
                              otherMembers,
                              hasError: _showValidationErrors && !isSuspectSelected,
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
    );
  }

  /// [마니또 추측] 탭의 친구 선택 프로필 카드 ([미션 기록] 탭의 타겟 프로필과 동일한 UI + 에러 강조 피드백)
  Widget _buildSuspectSelectionCard(
    BuildContext context,
    List<RoomMemberModel> otherMembers, {
    bool hasError = false,
  }) {
    RoomMemberModel? selectedMember;
    if (_selectedSuspectId != null) {
      for (final m in otherMembers) {
        if (m.userId == _selectedSuspectId) {
          selectedMember = m;
          break;
        }
      }
    }
    final profile = selectedMember?.userProfile;
    final hasImg = profile?.profileImageUrl != null && profile!.profileImageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showSuspectSelectionModal(context, otherMembers),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasError
                  ? AppColors.statusRed.withValues(alpha: 0.05)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError
                    ? AppColors.statusRed
                    : (selectedMember != null ? AppColors.primary : AppColors.border),
                width: (hasError || selectedMember != null) ? 1.8 : 1.0,
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: selectedMember != null
                        ? (hasImg
                            ? (profile!.profileImageUrl!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: profile.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: AppColors.surface),
                                    errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textSecondary),
                                  )
                                : Image.asset(profile.profileImageUrl!, fit: BoxFit.cover))
                            : const Icon(Icons.person, color: AppColors.textSecondary))
                        : Icon(
                            Icons.person_search_rounded,
                            color: hasError ? AppColors.statusRed : AppColors.textSecondary,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedMember != null
                            ? (profile?.name ?? '요원')
                            : '친구 선택',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: hasError
                              ? AppColors.statusRed
                              : (selectedMember != null ? AppColors.textPrimary : AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedMember != null
                            ? (profile?.statusMessage?.isNotEmpty == true
                                ? profile!.statusMessage!
                                : '마니또로 지목된 요원')
                            : '나의 마니또로 의심되는 친구를 선택하세요',
                        style: AppTypography.bodySm.copyWith(
                          color: hasError ? AppColors.statusRed : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasError ? AppColors.statusRed : AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '⚠️ 마니또로 의심되는 친구를 선택해 주세요.',
              style: TextStyle(color: AppColors.statusRed, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  /// 친구 선택 모달 바텀시트
  void _showSuspectSelectionModal(BuildContext context, List<RoomMemberModel> otherMembers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('친구 선택', style: AppTypography.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              if (otherMembers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('선택 가능한 참가자가 없습니다.', style: AppTypography.bodyMd)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: otherMembers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final m = otherMembers[idx];
                      final p = m.userProfile;
                      final isSelected = m.userId == _selectedSuspectId;
                      final hasImg = p?.profileImageUrl != null && p!.profileImageUrl!.isNotEmpty;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedSuspectId = m.userId);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.3) : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryDark : AppColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: ClipOval(
                                  child: hasImg
                                      ? (p!.profileImageUrl!.startsWith('http')
                                          ? CachedNetworkImage(
                                              imageUrl: p.profileImageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(color: AppColors.surface),
                                              errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textSecondary),
                                            )
                                          : Image.asset(p.profileImageUrl!, fit: BoxFit.cover))
                                      : const Icon(Icons.person, color: AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p?.name ?? '요원',
                                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    if (p?.statusMessage != null && p!.statusMessage!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        p!.statusMessage!,
                                        style: AppTypography.bodySm,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primaryDark, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required bool isSelected,
    required bool hasError,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTypography.labelSm.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
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
