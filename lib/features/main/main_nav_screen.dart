import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notifications/app_notification_service.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/util/app_logger.dart';
import '../feed/presentation/feed_provider.dart';
import '../feed/presentation/screens/archive_feed_view.dart';
import '../feed/presentation/screens/result_feed_screen.dart';
import '../profile/presentation/screens/profile_screen.dart';
import '../rooms/presentation/rooms_provider.dart';
import '../rooms/presentation/screens/home_dashboard_view.dart';

final selectedBottomTabProvider = StateProvider<int>((ref) => 0);

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> with WidgetsBindingObserver {
  Timer? _globalDeadlineCheckTimer;
  final Set<String> _processedCompletedRoomIds = {};
  final Set<String> _scheduledNotificationRoomIds = {};
  bool _isProcessingRoom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startGlobalDeadlineChecker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _globalDeadlineCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppLogger.i('App resumed to foreground: auto-refreshing unread comments and rooms', tag: 'MAIN');
      ref.invalidate(unreadCommentSummaryProvider);
      ref.invalidate(ongoingRoomsProvider);
      ref.invalidate(completedRoomsProvider);
    }
  }

  void _startGlobalDeadlineChecker() {
    _globalDeadlineCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkOngoingRoomsDeadline();
    });
  }

  void _checkOngoingRoomsDeadline() {
    if (_isProcessingRoom) return;

    final ongoingRoomsAsync = ref.read(ongoingRoomsProvider);
    final rooms = ongoingRoomsAsync.value;
    if (rooms == null || rooms.isEmpty) return;

    final now = DateTime.now();

    for (final room in rooms) {
      // ⚠️ 대기실(WAITING) 등 게임이 실제로 시작되지 않은 방은 마감 알림 스케줄링 및 마감 처리 대상에서 제외
      if (room.status != RoomStatus.ongoing || room.gameEndTime == null) {
        continue;
      }

      final deadline = room.gameEndTime!;

      // 알림 스케줄링 등록 (실제 진행 중인 방에 대해서만 1회 등록)
      if (!_scheduledNotificationRoomIds.contains(room.roomId)) {
        _scheduledNotificationRoomIds.add(room.roomId);
        ref.read(appNotificationServiceProvider).scheduleGameDeadlineNotifications(
          roomId: room.roomId,
          roomTitle: room.title,
          gameEndTime: deadline,
        );
      }

      if (_processedCompletedRoomIds.contains(room.roomId)) continue;

      final isEnded = now.isAfter(deadline);
      if (isEnded) {
        _processedCompletedRoomIds.add(room.roomId);
        _handleRoomDeadline(room.roomId, room.title);
        break; // 한 번에 한 방씩 순차 처리
      }
    }
  }

  /// 백그라운드 자동응답 저장 및 전역 [기록 상세] 즉시 화면 전환
  Future<void> _handleRoomDeadline(String roomId, String roomTitle) async {
    _isProcessingRoom = true;
    try {
      AppLogger.i('Handling global deadline reached for room: $roomId', tag: 'MAIN');

      // 1. 서버 RPC 호출: 참여자 전원의 미작성 자동응답 일괄 생성 및 방 상태 ENDED 처리
      await ref.read(roomsRepositoryProvider).finalizeGameAndFillAutoReplies(roomId);

      // 2. 마감 완료 푸시 알림 발송
      await ref.read(appNotificationServiceProvider).showImmediateDeadlineCompleteNotification(
        roomId: roomId,
        roomTitle: roomTitle,
      );

      // 3. 프로바이더 새로고침
      ref.invalidate(ongoingRoomsProvider);
      ref.invalidate(completedRoomsProvider);
    } catch (e, s) {
      AppLogger.e('Global auto-reply error: $e', tag: 'MAIN', error: e, stackTrace: s);
    } finally {
      _isProcessingRoom = false;
    }

    if (mounted) {
      // 5. 전역 즉시 강제 이동 ([기록 상세] 화면으로 push)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultFeedScreen(roomId: roomId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(selectedBottomTabProvider);
    final totalUnreadComments = ref.watch(totalUnreadCommentCountProvider);
    final invitationsAsync = ref.watch(receivedRoomInvitationsProvider);
    final hasInvitations = invitationsAsync.value?.isNotEmpty ?? false;
    // 진행중인 방 상태 지속 구독
    ref.watch(ongoingRoomsProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: const [
          HomeDashboardView(),
          ArchiveFeedView(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  currentIndex: currentTab,
                  icon: Icons.home_rounded,
                  label: '홈',
                  hasBadge: hasInvitations,
                ),
                _buildNavItem(
                  index: 1,
                  currentIndex: currentTab,
                  icon: Icons.auto_stories_rounded,
                  label: '기록',
                  hasBadge: totalUnreadComments > 0,
                ),
                _buildNavItem(
                  index: 2,
                  currentIndex: currentTab,
                  icon: Icons.account_circle_rounded,
                  label: '프로필',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    bool hasBadge = false,
  }) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: () => ref.read(selectedBottomTabProvider.notifier).state = index,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? AppColors.textPrimary : AppColors.textDisabled,
                ),
                if (hasBadge)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isSelected
                  ? AppTypography.labelSm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    )
                  : AppTypography.labelSm.copyWith(
                      color: AppColors.textDisabled,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
