import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/features/feed/presentation/feed_provider.dart';
import 'package:manito/features/feed/presentation/screens/archive_feed_view.dart';
import 'package:manito/features/friends/presentation/friends_provider.dart';

class FriendDetailScreen extends ConsumerStatefulWidget {
  final FriendshipModel friendship;

  const FriendDetailScreen({
    super.key,
    required this.friendship,
  });

  @override
  ConsumerState<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends ConsumerState<FriendDetailScreen> {
  bool _isDeleting = false;

  UserModel? get _profile => widget.friendship.friendProfile;

  String get _friendUserId {
    if (_profile?.userId != null) return _profile!.userId;
    final myUid = ref.read(currentUserProvider)?.id;
    return widget.friendship.requesterId == myUid
        ? widget.friendship.receiverId
        : widget.friendship.requesterId;
  }

  Future<void> _confirmDeleteFriend() async {
    final friendName = _profile?.name ?? '친구';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('친구 삭제', style: AppTypography.titleMedium),
        content: Text(
          '$friendName님을 친구 목록에서 삭제하시겠습니까?\n함께했던 마니또 기록은 안전하게 보관됩니다.',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      AppLogger.i('Deleting friendship: ${widget.friendship.friendshipId}', tag: 'FRIENDS');
      await ref.read(friendsRepositoryProvider).deleteFriendship(widget.friendship.friendshipId);
      ref.invalidate(acceptedFriendsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$friendName님이 친구 목록에서 삭제되었습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      AppLogger.e('Failed to delete friend: $e', tag: 'FRIENDS', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 삭제 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
              title: const Text(
                '친구 삭제',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDeleteFriend();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final friendUserId = _friendUserId;
    final sharedRoomsAsync = ref.watch(sharedCompletedRoomsProvider(friendUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 프로필'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: '더보기',
            onPressed: _isDeleting ? null : _showMoreMenu,
          ),
        ],
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Horizontal Profile Card (Same background and styling as Home friend card)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar (64x64)
                          UserAvatar(
                            imageUrl: profile?.profileImageUrl,
                            size: 64,
                            fallbackIconSize: 32,
                          ),
                          const SizedBox(width: 16),

                          // Name & Status Message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile?.name ?? '알 수 없는 요원',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryOf(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile?.statusMessage?.trim().isNotEmpty == true
                                      ? profile!.statusMessage!
                                      : '등록된 상태메시지가 없습니다.',
                                  style: AppTypography.bodySm.copyWith(
                                    color: profile?.statusMessage?.trim().isNotEmpty == true
                                        ? AppColors.textSecondaryOf(context)
                                        : AppColors.textDisabledOf(context),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Shared Records Header
                  Row(
                    children: [
                      Text(
                        '함께한 기록',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimaryOf(context)),
                      ),
                      const SizedBox(width: 8),
                      sharedRoomsAsync.maybeWhen(
                        data: (rooms) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLightOf(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${rooms.length}',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.isDark(context) ? AppColors.primary : AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Shared Records List
                  sharedRoomsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text('기록을 불러오지 못했습니다: $err'),
                    ),
                    data: (rooms) {
                      if (rooms.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderOf(context)),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 40, color: AppColors.textDisabledOf(context)),
                              const SizedBox(height: 10),
                              Text('아직 함께한 마니또 기록이 없습니다.', style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimaryOf(context))),
                              const SizedBox(height: 4),
                              Text('새로운 마니또 방에서 친구와 함께 플레이해보세요!', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondaryOf(context))),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rooms.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final room = rooms[idx];
                          return RecordHistoryCard(room: room);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
