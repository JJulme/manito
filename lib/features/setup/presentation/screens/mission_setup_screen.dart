import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/features/game/presentation/screens/main_play_dashboard_screen.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/setup/presentation/setup_provider.dart';

class MissionSetupScreen extends ConsumerStatefulWidget {
  final String roomId;

  const MissionSetupScreen({super.key, required this.roomId});

  @override
  ConsumerState<MissionSetupScreen> createState() => _MissionSetupScreenState();
}

class _MissionSetupScreenState extends ConsumerState<MissionSetupScreen> {
  Timer? _timer;
  int _secondsLeft = 30;
  bool _hasTimedOut = false;
  bool _hasNavigatedToGame = false;
  RealtimeChannel? _roomChannel;

  @override
  void initState() {
    super.initState();
    _subscribeToRoomRealtime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _roomChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRoomRealtime() {
    try {
      final supabase = ref.read(supabaseProvider);
      _roomChannel = supabase
          .channel('public:setup_${widget.roomId}')
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
              if (mounted) {
                ref.invalidate(roomMembersProvider(widget.roomId));
                ref.invalidate(myMemberRecordProvider(widget.roomId));
              }
            },
          );

      _roomChannel?.subscribe();
    } catch (e) {
      AppLogger.e('Failed to subscribe to setup realtime updates: $e', tag: 'SETUP');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  Future<void> _onTimeout() async {
    if (_hasTimedOut || _hasNavigatedToGame) return;
    _hasTimedOut = true;

    AppLogger.i('Mission setup timeout for room: ${widget.roomId}', tag: 'SETUP');

    final myMemberAsync = ref.read(myMemberRecordProvider(widget.roomId));
    final member = myMemberAsync.value;

    if (member != null && !member.isMissionSelected) {
      await ref
          .read(missionSetupProvider.notifier)
          .confirmSelection(member.roomMemberId, widget.roomId, null);
    }

    // 30초 경과 시 전원 준비 상태 체크 후 게임 시작(ONGOING) 전환
    try {
      final isStarted = await ref.read(setupRepositoryProvider).checkAndStartOngoingGame(widget.roomId);
      if (!isStarted) {
        // 30초가 경과했으면 미선택 인원도 fallback 완료되었으므로 강제 ONGOING 처리
        await ref.read(supabaseProvider).from('rooms').update({
          'status': 'ONGOING',
          'game_start_time': DateTime.now().toUtc().toIso8601String(),
        }).eq('room_id', widget.roomId);
      }
    } catch (e) {
      AppLogger.w('Failed to transition to ONGOING on timeout: $e', tag: 'SETUP');
    }

    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    if (_hasNavigatedToGame || !mounted) return;
    _hasNavigatedToGame = true;
    _timer?.cancel();
    _roomChannel?.unsubscribe();

    AppLogger.i('Navigating to MainPlayDashboardScreen for room: ${widget.roomId}', tag: 'SETUP');
    ref.invalidate(ongoingRoomsProvider);
    ref.invalidate(roomDetailsProvider(widget.roomId));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainPlayDashboardScreen(roomId: widget.roomId),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myMemberAsync = ref.watch(myMemberRecordProvider(widget.roomId));
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final setupState = ref.watch(missionSetupProvider);
    final lang = ref.watch(languageCodeProvider);

    return PopScope(
      canPop: false, // 뒤로가기 완전 차단 (미션 선택 강제)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('마니또 미션 선택'),
          automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        ),
        body: myMemberAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('정보 로드 실패: $err')),
          data: (myMember) {
            if (myMember == null) {
              return const Center(child: Text('참가자 정보를 찾을 수 없습니다.'));
            }

            final targetUser = myMember.targetUserProfile;

            // Fetch candidate missions
            final candidatesAsync = ref.watch(missionCandidatesProvider(myMember.roomMemberId));

            return Column(
              children: [
                // Global Ready Status Bar
                membersAsync.maybeWhen(
                  data: (members) {
                    final readyCount = members.where((m) => m.isMissionSelected).length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      color: AppColors.surface,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.sync_rounded, size: 16, color: AppColors.textSecondary),
                              SizedBox(width: 6),
                              Text('다른 친구들 미션 선택 중...', style: AppTypography.labelSm),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$readyCount/${members.length}',
                              style: AppTypography.labelSm.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Countdown Timer Display
                        Center(
                          child: Column(
                            children: [
                              const Text('미션 선택 제한시간', style: AppTypography.labelSm),
                              const SizedBox(height: 4),
                              Text(
                                '00:${_secondsLeft.toString().padLeft(2, '0')}',
                                style: AppTypography.timerDisplay.copyWith(
                                  fontSize: 36,
                                  color: _secondsLeft <= 5 ? Colors.red : AppColors.timerUrgent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _secondsLeft / 30.0,
                                  backgroundColor: AppColors.surface,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _secondsLeft <= 5 ? Colors.red : AppColors.timerUrgent,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Confidential Target User Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Column(
                            children: [
                              Text(
                                '당신은 ${targetUser?.name ?? "친구"}의 마니또 입니다',
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.border, width: 2),
                                ),
                                child: ClipOval(
                                  child: targetUser?.profileImageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: targetUser!.profileImageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: AppColors.surface),
                                        errorWidget: (_, __, ___) => const Icon(Icons.person, size: 36, color: AppColors.textSecondary),
                                      )
                                    : const Icon(Icons.person, size: 36, color: AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                targetUser?.name ?? '마니또 대상',
                                style: AppTypography.headlineMd,
                              ),
                              if (targetUser?.statusMessage != null && targetUser!.statusMessage!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '"${targetUser.statusMessage!}"',
                                  style: AppTypography.bodySm.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Candidate Missions Section
                        candidatesAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          ),
                          error: (err, _) => Text('미션 후보 로드 실패: $err'),
                          data: (candidates) {
                            if (candidates == null || candidates.mission1 == null || candidates.mission2 == null) {
                              return const Center(child: Text('제시된 미션 후보가 없습니다.'));
                            }

                            final m1 = candidates.mission1!;
                            final m2 = candidates.mission2!;
                            final selectedId = setupState.selectedMissionId ?? myMember.assignedMissionId;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('미션 선택', style: AppTypography.titleMd),
                                const SizedBox(height: 12),

                                // Mission 1 Card
                                _buildMissionCard(
                                  mission: m1,
                                  isSelected: selectedId == m1.missionId,
                                  isFinalized: setupState.isFinalized || myMember.isMissionSelected,
                                  lang: lang,
                                  onTap: () => ref.read(missionSetupProvider.notifier).selectMission(m1.missionId),
                                ),
                                const SizedBox(height: 12),

                                // Mission 2 Card
                                _buildMissionCard(
                                  mission: m2,
                                  isSelected: selectedId == m2.missionId,
                                  isFinalized: setupState.isFinalized || myMember.isMissionSelected,
                                  lang: lang,
                                  onTap: () => ref.read(missionSetupProvider.notifier).selectMission(m2.missionId),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Finalize Button
                        if (!myMember.isMissionSelected && !setupState.isFinalized)
                          ElevatedButton(
                            onPressed: setupState.selectedMissionId == null || setupState.isSubmitting
                                ? null
                                : () async {
                                    final success = await ref
                                        .read(missionSetupProvider.notifier)
                                        .confirmSelection(myMember.roomMemberId, widget.roomId);

                                    if (mounted && success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('미션이 선택되었습니다!')),
                                      );
                                      // 모든 인원이 완료되었는지 검사
                                      await ref.read(setupRepositoryProvider).checkAndStartOngoingGame(widget.roomId);
                                      if (mounted) {
                                        _navigateToDashboard();
                                      }
                                    }
                                  },
                            child: setupState.isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                                  )
                                : const Text('미션 선택'),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.statusGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.statusGreen),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_circle_rounded, color: AppColors.statusGreen),
                                SizedBox(width: 8),
                                Text('미션 선택 완료', style: AppTypography.titleSmall),
                              ],
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMissionCard({
    required MissionModel mission,
    required bool isSelected,
    required bool isFinalized,
    required String lang,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isFinalized ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppColors.elevatedShadow : AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.category.toUpperCase(),
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mission.getContent(lang),
                    style: AppTypography.titleMd,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryDark, size: 26)
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
