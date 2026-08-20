import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/models.dart';
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 8,
                      decoration: const InputDecoration(
                        hintText: '8자리 고유 코드 입력 (예: ABCD1234)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onSubmitted: (_) => _onSearch(),
                    ),
                  ),
                  TextButton(
                    onPressed: searchState.isLoading ? null : _onSearch,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
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
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        searchState.errorMessage!,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

            // Search Result Card
            if (searchState.foundUser != null) ...[
              const Text('검색 결과', style: AppTypography.labelMd),
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${requests.length}개 대기중',
                            style: AppTypography.labelSm.copyWith(color: AppColors.textPrimary),
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
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
              ),
              child: ClipOval(
                child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? (user.profileImageUrl!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: user.profileImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surface),
                            errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textSecondary, size: 30),
                          )
                        : Image.asset(user.profileImageUrl!, fit: BoxFit.cover))
                    : const Icon(Icons.person, color: AppColors.textSecondary, size: 30),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppTypography.titleMd),
                  const SizedBox(height: 2),
                  Text(
                    user.statusMessage ?? '코드: ${user.uniqueCode}',
                    style: AppTypography.bodySm,
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
                backgroundColor: AppColors.surfaceLow,
                textColor: AppColors.textDisabled,
                borderColor: AppColors.border,
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
                backgroundColor: AppColors.surfaceLow,
                textColor: AppColors.textSecondary,
                borderColor: AppColors.border,
              )
            else
              _buildStatusBadge(
                label: '요청',
                backgroundColor: AppColors.primary,
                textColor: AppColors.textPrimary,
                isAction: true,
                onTap: () async {
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
    final hasImg = requester?.profileImageUrl != null && requester!.profileImageUrl!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
              ),
              child: ClipOval(
                child: hasImg
                    ? (requester.profileImageUrl!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: requester.profileImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surface),
                            errorWidget: (_, __, ___) => const Icon(Icons.person, color: AppColors.textSecondary),
                          )
                        : Image.asset(requester.profileImageUrl!, fit: BoxFit.cover))
                    : const Icon(Icons.person, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(requester?.name ?? '알 수 없는 요원', style: AppTypography.titleSmall),
                  if (requester?.statusMessage != null)
                    Text(
                      requester!.statusMessage!,
                      style: AppTypography.bodySm,
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
