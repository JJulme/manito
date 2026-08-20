import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/util/game_time_util.dart';
import 'package:manito/features/friends/presentation/friends_provider.dart';
import 'package:manito/features/friends/presentation/widgets/friend_selection_card.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';

/// 친구 초대 화면 (방 개설 전 전체 화면 & 대기실 내 바텀시트 모달 겸용 재사용 화면)
class InviteFriendsScreen extends ConsumerStatefulWidget {
  final String? existingRoomId; // 기존 방 ID (대기실에서 추가 초대 시 사용)
  final Set<String>? excludedUserIds; // 이미 방에 참여/초대된 요원 ID 목록 (필터링용)
  final bool isBottomSheet; // 바텀시트 모달로 열렸는지 여부
  final VoidCallback? onInviteSuccess; // 초대 성공 콜백

  const InviteFriendsScreen({
    super.key,
    this.existingRoomId,
    this.excludedUserIds,
    this.isBottomSheet = false,
    this.onInviteSuccess,
  });

  /// 대기실 등에서 바텀시트로 친구 초대 모달을 띄우는 헬퍼 메서드
  static Future<void> showAsBottomSheet(
    BuildContext context, {
    required String roomId,
    required Set<String> excludedUserIds,
    VoidCallback? onInviteSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InviteFriendsScreen(
        existingRoomId: roomId,
        excludedUserIds: excludedUserIds,
        isBottomSheet: true,
        onInviteSuccess: onInviteSuccess,
      ),
    );
  }

  @override
  ConsumerState<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends ConsumerState<InviteFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedFriendUserIds = {};
  bool _isCreating = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFriendSelection(String userId) {
    setState(() {
      if (_selectedFriendUserIds.contains(userId)) {
        _selectedFriendUserIds.remove(userId);
      } else {
        _selectedFriendUserIds.add(userId);
      }
    });
  }

  Future<void> _handleCreateAndInvite() async {
    if (_isCreating) return;

    setState(() => _isCreating = true);

    try {
      final roomsRepo = ref.read(roomsRepositoryProvider);

      if (widget.existingRoomId != null) {
        // [대기실 추가 초대 모드]
        final targetRoomId = widget.existingRoomId!;
        if (_selectedFriendUserIds.isNotEmpty) {
          await roomsRepo.inviteFriends(targetRoomId, _selectedFriendUserIds.toList());
        }

        ref.invalidate(roomMembersProvider(targetRoomId));
        widget.onInviteSuccess?.call();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_selectedFriendUserIds.length}명의 친구를 초대했습니다.')),
          );
        }
      } else {
        // [신규 방 개설 모드]
        final userProfile = ref.read(currentUserProfileProvider).value;
        final hostName = (userProfile?.name.trim().isNotEmpty == true) ? userProfile!.name.trim() : '요원';
        final defaultTitle = '$hostName의 마니또 방';
        final defaultDeadline = GameTimeUtil.calculateCeiledDeadline(minutesToAdd: 30);
        final newRoom = await roomsRepo.createRoom(
          title: defaultTitle,
          missionCategory: 'daily',
          gameEndTime: defaultDeadline,
        );

        if (_selectedFriendUserIds.isNotEmpty) {
          await roomsRepo.inviteFriends(newRoom.roomId, _selectedFriendUserIds.toList());
        }

        ref.invalidate(ongoingRoomsProvider);

        if (mounted) {
          AppLogger.i('Room created/invited. Navigating to lobby: ${newRoom.roomId}', tag: 'ROOMS');
          context.pushReplacement('/lobby/${newRoom.roomId}');
        }
      }
    } catch (e, s) {
      setState(() => _isCreating = false);
      AppLogger.e('Failed to create room/invite: $e', tag: 'ROOMS', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('방 개설/초대 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(acceptedFriendsProvider);
    final isNewRoomMode = widget.existingRoomId == null;

    final content = Column(
      children: [
        if (widget.isBottomSheet) ...[
          // Bottom Sheet Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Bottom Sheet Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('친구 초대하기', style: AppTypography.headlineMd),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _selectedFriendUserIds.isNotEmpty
                            ? AppColors.primary
                            : AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedFriendUserIds.isNotEmpty
                              ? AppColors.primaryDark
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '${_selectedFriendUserIds.length}명 선택',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _selectedFriendUserIds.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
        ],

        // 1. Search Field + Friend List Scroll Area
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input Field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: '친구 이름 또는 상태메시지 검색...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                          onPressed: () => _searchController.clear(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Friends Selection List
                friendsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (err, _) => Center(child: Text('친구 목록 로드 실패: $err')),
                  data: (friends) {
                    // Filter out already participating/invited members if excludedUserIds provided
                    final invitableFriends = friends.where((f) {
                      final friendId = f.friendProfile?.userId ??
                          (f.requesterId == ref.read(currentUserProvider)?.id
                              ? f.receiverId
                              : f.requesterId);
                      if (widget.excludedUserIds != null && widget.excludedUserIds!.contains(friendId)) {
                        return false;
                      }
                      return true;
                    }).toList();

                    if (invitableFriends.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(Icons.group_outlined, size: 48, color: AppColors.textDisabled),
                            const SizedBox(height: 12),
                            Text(
                              widget.excludedUserIds != null
                                  ? '초대 가능한 모든 친구가 이미 대기실에 있습니다!'
                                  : '초대할 친구가 없습니다.',
                              style: AppTypography.titleSm,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            if (widget.excludedUserIds == null) ...[
                              const Text(
                                '먼저 친구를 추가하면 이곳에서 바로 선택하여 초대할 수 있습니다.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySm,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/add_friend'),
                                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                label: const Text('친구 추가하러 가기'),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    // Filter by search query
                    final filteredFriends = invitableFriends.where((f) {
                      if (_searchQuery.isEmpty) return true;
                      final name = f.friendProfile?.name.toLowerCase() ?? '';
                      final status = f.friendProfile?.statusMessage?.toLowerCase() ?? '';
                      final code = f.friendProfile?.uniqueCode.toLowerCase() ?? '';
                      return name.contains(_searchQuery) ||
                          status.contains(_searchQuery) ||
                          code.contains(_searchQuery);
                    }).toList();

                    if (filteredFriends.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: const Text('검색 결과가 없습니다.', style: AppTypography.bodyMd),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredFriends.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final friendship = filteredFriends[idx];
                        final friend = friendship.friendProfile;
                        if (friend == null) return const SizedBox.shrink();

                        final isSelected = _selectedFriendUserIds.contains(friend.userId);

                        return FriendSelectionCard(
                          friend: friend,
                          isSelected: isSelected,
                          onToggle: () => _toggleFriendSelection(friend.userId),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // 2. Bottom Fixed CTA Button
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12 + MediaQuery.of(context).viewInsets.bottom + (widget.isBottomSheet ? 16 : 0),
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isCreating || (widget.isBottomSheet && _selectedFriendUserIds.isEmpty)
                  ? null
                  : _handleCreateAndInvite,
              icon: _isCreating
                  ? const SizedBox.shrink()
                  : Icon(
                      widget.isBottomSheet ? Icons.send_rounded : Icons.rocket_launch_rounded,
                      size: 20,
                    ),
              label: _isCreating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.isBottomSheet
                          ? (_selectedFriendUserIds.isEmpty
                              ? '초대할 친구를 선택해주세요'
                              : '${_selectedFriendUserIds.length}명 초대 발송하기')
                          : (_selectedFriendUserIds.isEmpty
                              ? '대기실 생성하기'
                              : '대기실 생성 & ${_selectedFriendUserIds.length}명 초대하기'),
                    ),
            ),
          ),
        ),
      ],
    );

    if (widget.isBottomSheet) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 초대'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedFriendUserIds.isNotEmpty
                      ? AppColors.primary
                      : AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedFriendUserIds.isNotEmpty
                        ? AppColors.primaryDark
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  '${_selectedFriendUserIds.length}명 선택됨',
                  style: AppTypography.labelSm.copyWith(
                    color: _selectedFriendUserIds.isNotEmpty
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: content),
    );
  }
}
