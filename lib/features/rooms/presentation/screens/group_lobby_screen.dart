import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/analytics/analytics_event.dart';
import 'package:manito/core/analytics/analytics_service.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/notifications/app_notification_service.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/router.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/widget/network_error_view.dart';
import 'package:manito/features/friends/presentation/screens/invite_friends_screen.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/rooms/presentation/widgets/lobby_circular_timer_banner.dart';
import 'package:manito/features/rooms/presentation/widgets/lobby_leave_bottom_sheet.dart';
import 'package:manito/features/rooms/presentation/widgets/lobby_member_list.dart';
import 'package:manito/features/rooms/presentation/widgets/lobby_options_card.dart';
import 'package:manito/features/rooms/presentation/widgets/lobby_room_expired_bottom_sheet.dart';
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
          LobbyRoomExpiredBottomSheet.show(rootCtx, isTimeExpired: isTimeExpired);
        }
      });
    }
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
    } catch (e, s) {
      if (mounted) {
        AppLogger.e('카테고리 수정 실패', error: e, stackTrace: s);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카테고리 수정에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    }
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
    } catch (e, s) {
      if (mounted) {
        AppLogger.e('게임 시작 실패', error: e, stackTrace: s);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게임 시작에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
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
          icon: const Icon(LucideIcons.chevron_left),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.log_out, color: AppColors.statusRed),
            tooltip: isHost ? '방 삭제 및 나가기' : '대기실 나가기',
            onPressed: () => LobbyLeaveBottomSheet.show(
              context,
              roomId: widget.roomId,
              isHost: isHost,
              onLeaveStart: () {
                _isVoluntaryExit = true;
                _isHandlingExpiration = true;
                _expirationCheckTimer?.cancel();
                _roomChannel?.unsubscribe();
              },
            ),
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
                        : const Icon(LucideIcons.play, size: 22),
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
      body: SafeArea(
        child: roomAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => NetworkErrorView(
            title: '대기실을 불러오지 못했어요',
            onRetry: () => ref.invalidate(roomDetailsProvider(widget.roomId)),
          ),
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
              error: (err, _) => NetworkErrorView(
                title: '참가자 목록을 불러오지 못했어요',
                onRetry: () => ref.invalidate(roomMembersProvider(widget.roomId)),
              ),
              data: (members) {
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
                      LobbyOptionsCard(
                        room: room,
                        isHost: isHost,
                        onCategoryChanged: _updateCategory,
                      ),
                      const SizedBox(height: 24),

                      // 2. Operatives Member List
                      LobbyMemberList(
                        members: members,
                        room: room,
                        currentUserId: currentUserId,
                        isHost: isHost,
                        onInviteTap: () => _showInviteFriendsModal(context, members),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
