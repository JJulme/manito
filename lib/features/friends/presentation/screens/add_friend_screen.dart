import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/models.dart';
import '../../../../core/widget/user_avatar.dart';
import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../friends_provider.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvent.friendSearch,
        screenName: 'AddFriendScreen',
        properties: {'query_length': query.length},
      );
      ref.read(friendSearchProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(friendSearchProvider);
    final receivedRequestsAsync = ref.watch(receivedFriendRequestsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Section
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderOf(context)),
                boxShadow: AppColors.cardShadowOf(context),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search, color: AppColors.textSecondaryOf(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                      decoration: InputDecoration(
                        hintText: '8자리 고유 코드 입력 (예: ABCD1234)',
                        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textSecondaryOf(context)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onSubmitted: (_) => _onSearch(),
                    ),
                  ),
                  TextButton(
                    onPressed: searchState.isLoading ? null : _onSearch,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryOf(context),
                      textStyle: AppTypography.titleMd,
                    ),
                    child: const Text('검색'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Loading or Error
            if (searchState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),

            if (searchState.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textSecondaryOf(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        searchState.errorMessage!,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondaryOf(context)),
                      ),
                    ),
                  ],
                ),
              ),

            // Search Result Card
            if (searchState.foundUser != null) ...[
              Text(
                '검색 결과',
                style: AppTypography.labelMd.copyWith(color: AppColors.textSecondaryOf(context)),
              ),
              const SizedBox(height: 8),
              _buildUserSearchResultCard(searchState.foundUser!, searchState.existingFriendship, currentUserId),
              const SizedBox(height: 32),
            ],

            const Divider(),
            const SizedBox(height: 24),

            // Received Friend Requests Section
            receivedRequestsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => Text('요청 목록 조회 실패: $err'),
              data: (requests) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('받은 친구 요청', style: AppTypography.titleMd),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLowOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderOf(context)),
                          ),
                          child: Text(
                            '${requests.length}개 대기중',
                            style: AppTypography.labelSm.copyWith(color: AppColors.textPrimaryOf(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (requests.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: const Text(
                          '새로운 친구 요청이 없습니다.',
                          style: AppTypography.bodyMd,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final req = requests[idx];
                          return _buildReceivedRequestCard(req);
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchResultCard(UserModel user, FriendshipModel? friendship, String? currentUserId) {
    final isSelf = user.userId == currentUserId;
    final isAlreadyFriend = friendship?.status == FriendshipStatus.accepted;
    final isRequested = friendship?.status == FriendshipStatus.requested;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: user.profileImageUrl,
              size: 52,
              fallbackIconSize: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: AppTypography.titleMd.copyWith(color: AppColors.textPrimaryOf(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.statusMessage ?? '코드: ${user.uniqueCode}',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textSecondaryOf(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelf)
              _buildStatusBadge(
                label: '본인',
                backgroundColor: AppColors.surfaceLowOf(context),
                textColor: AppColors.textDisabledOf(context),
                borderColor: AppColors.borderOf(context),
              )
            else if (isAlreadyFriend)
              _buildStatusBadge(
                label: '친구',
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                textColor: AppColors.primaryDark,
                borderColor: AppColors.primary.withValues(alpha: 0.3),
              )
            else if (isRequested)
              _buildStatusBadge(
                label: '요청중',
                backgroundColor: AppColors.surfaceLowOf(context),
                textColor: AppColors.textSecondaryOf(context),
                borderColor: AppColors.borderOf(context),
              )
            else
              _buildStatusBadge(
                label: '요청',
                backgroundColor: AppColors.primary,
                textColor: const Color(0xFF1E1E24),
                isAction: true,
                onTap: () async {
                  ref.read(analyticsServiceProvider).logEvent(
                    AnalyticsEvent.friendRequestSend,
                    screenName: 'AddFriendScreen',
                    properties: {'target_user_id': user.userId},
                  );
                  await ref.read(friendSearchProvider.notifier).sendRequest(user.userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${user.name}님에게 친구 요청을 보냈습니다.')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    VoidCallback? onTap,
    bool isAction = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 76),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor ?? Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedRequestCard(FriendshipModel req) {
    final requester = req.friendProfile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: requester?.profileImageUrl,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requester?.name ?? '알 수 없는 요원',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  if (requester?.statusMessage != null)
                    Text(
                      requester!.statusMessage!,
                      style: AppTypography.bodySm.copyWith(color: AppColors.textSecondaryOf(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Accept Action Button
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppColors.statusGreen, size: 28),
              tooltip: '수락',
              onPressed: () async {
                ref.read(analyticsServiceProvider).logEvent(
                  AnalyticsEvent.friendRequestResponse,
                  screenName: 'AddFriendScreen',
                  properties: {'action': 'accept', 'friendship_id': req.friendshipId},
                );
                await ref.read(friendsRepositoryProvider).acceptFriendRequest(req.friendshipId);
                ref.invalidate(receivedFriendRequestsProvider);
                ref.invalidate(acceptedFriendsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('친구 요청을 수락했습니다.')),
                  );
                }
              },
            ),
            // Reject Action Button
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.statusRed, size: 28),
              tooltip: '거절',
              onPressed: () async {
                ref.read(analyticsServiceProvider).logEvent(
                  AnalyticsEvent.friendRequestResponse,
                  screenName: 'AddFriendScreen',
                  properties: {'action': 'reject', 'friendship_id': req.friendshipId},
                );
                await ref.read(friendsRepositoryProvider).deleteFriendship(req.friendshipId);
                ref.invalidate(receivedFriendRequestsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('친구 요청을 거절했습니다.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
