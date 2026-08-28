import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notifications/app_notification_service.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/util/app_logger.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/analytics_service.dart';
import '../feed/presentation/feed_provider.dart';
import '../feed/presentation/screens/archive_feed_view.dart';
import '../feed/presentation/screens/result_feed_screen.dart';
import '../friends/presentation/friends_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvent.appOpen,
        screenName: 'MainNavScreen',
      );
    });
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
      ref.invalidate(receivedFriendRequestsProvider);
    }
  }

  void _startGlobalDeadlineChecker() {
    _globalDeadlineCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkOngoingRoomsDeadline();
    });
  }

  Future<void> _checkOngoingRoomsDeadline() async {
    final ongoingRooms = ref.read(ongoingRoomsProvider).value ?? [];
    if (ongoingRooms.isEmpty) return;

    final now = DateTime.now();

    for (final room in ongoingRooms) {
      if (room.status != RoomStatus.ongoing) continue;
      final deadline = room.gameEndTime;
      if (deadline == null) continue;

      // 1. 백그라운드 푸시 알림 예약
      if (!_scheduledNotificationRoomIds.contains(room.roomId)) {
        _scheduledNotificationRoomIds.add(room.roomId);
        ref.read(appNotificationServiceProvider).scheduleGameDeadlineNotifications(
          roomId: room.roomId,
          roomTitle: room.title,
          gameEndTime: deadline,
        );
      }

      // 2. 포그라운드 마감 체크
      if (now.isAfter(deadline)) {
        if (_processedCompletedRoomIds.contains(room.roomId) || _isProcessingRoom) {
          continue;
        }

        _isProcessingRoom = true;
        _processedCompletedRoomIds.add(room.roomId);
        AppLogger.i('Global deadline reached for room: ${room.roomId}', tag: 'MAIN');

        try {
          await ref.read(roomsRepositoryProvider).finalizeGameAndFillAutoReplies(room.roomId);
          await ref.read(appNotificationServiceProvider).showImmediateDeadlineCompleteNotification(
            roomId: room.roomId,
            roomTitle: room.title,
          );

          ref.invalidate(ongoingRoomsProvider);
          ref.invalidate(completedRoomsProvider);
          ref.invalidate(roomDetailsProvider(room.roomId));
          ref.invalidate(roomRecordsProvider(room.roomId));

          if (mounted) {
            _showDeadlineCompletionModal(room.roomId, room.title);
          }
        } catch (e, s) {
          AppLogger.e('Error during global deadline finalization: $e', tag: 'MAIN', error: e, stackTrace: s);
        } finally {
          _isProcessingRoom = false;
        }
        break;
      }
    }
  }

  void _showDeadlineCompletionModal(String roomId, String roomTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: AppColors.primaryDark),
            SizedBox(width: 8),
            Text('마니또 마감!'),
          ],
        ),
        content: Text(
          '\'$roomTitle\' 방의 마니또 활동이 종료되었습니다!\n지금 바로 마니또 결과와 친구들의 인증 피드를 확인해보세요.',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResultFeedScreen(roomId: roomId),
                ),
              );
            },
            child: const Text('결과 보러가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(selectedBottomTabProvider);
    final totalUnreadComments = ref.watch(totalUnreadCommentCountProvider);
    final invitationsAsync = ref.watch(receivedRoomInvitationsProvider);
    final hasInvitations = invitationsAsync.value?.isNotEmpty ?? false;
    final friendRequestsAsync = ref.watch(receivedFriendRequestsProvider);
    final hasFriendRequests = friendRequestsAsync.value?.isNotEmpty ?? false;
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
          color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
          border: Border(
            top: BorderSide(color: AppColors.borderOf(context), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.25 : 0.04),
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
                  hasBadge: hasInvitations || hasFriendRequests,
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
                  color: isSelected ? AppColors.textPrimaryOf(context) : AppColors.textDisabledOf(context),
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
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w700,
                    )
                  : AppTypography.labelSm.copyWith(
                      color: AppColors.textDisabledOf(context),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
