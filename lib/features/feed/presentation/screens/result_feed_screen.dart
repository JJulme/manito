import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/feed/presentation/feed_provider.dart';
import 'package:manito/features/feed/presentation/widgets/comments_sheet.dart';
import 'package:manito/features/main/main_nav_screen.dart';

class ResultFeedScreen extends ConsumerStatefulWidget {
  final String roomId;

  const ResultFeedScreen({super.key, required this.roomId});

  @override
  ConsumerState<ResultFeedScreen> createState() => _ResultFeedScreenState();
}

class _ResultFeedScreenState extends ConsumerState<ResultFeedScreen> {
  String? _selectedUserId;

  void _handleBackNavigation(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      ref.read(selectedBottomTabProvider.notifier).state = 1;
      context.go('/bottom_nav2');
    }
  }

  void _openCommentsSheet(BuildContext context, int? recordId, String selectedMemberName) {
    if (recordId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작성된 기록이 없어 아직 댓글을 남길 수 없습니다.')),
      );
      return;
    }

    // 해당 레코드 댓글 즉시 읽음 처리
    ref.read(feedRepositoryProvider).markRecordCommentsAsRead(recordId).then((_) {
      if (mounted) {
        ref.invalidate(unreadCommentSummaryProvider);
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(
        recordId: recordId,
        roomId: widget.roomId,
        title: '댓글',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final roomAsync = ref.watch(roomDetailsProvider(widget.roomId));
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final recordsAsync = ref.watch(roomRecordsProvider(widget.roomId));
    final lang = ref.watch(languageCodeProvider);

    return roomAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('마니또 결과')),
        body: Center(child: Text('방 정보를 불러오지 못했습니다: $err')),
      ),
      data: (room) {
        final roomTitle = room?.title ?? '마니또 결과';

        return membersAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(title: Text(roomTitle)),
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (err, _) => Scaffold(
            appBar: AppBar(title: Text(roomTitle)),
            body: Center(child: Text('멤버 정보를 불러오지 못했습니다: $err')),
          ),
          data: (members) {
            final activeMembers = members.where((m) => m.joinStatus == '✔️').toList();

            if (activeMembers.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: Text(roomTitle)),
                body: const Center(child: Text('참여한 멤버가 없습니다.')),
              );
            }

            // 기본 선택: 현재 사용자 또는 첫 번째 멤버
            final currentSelectedId = _selectedUserId ??
                (activeMembers.any((m) => m.userId == currentUserId)
                    ? currentUserId!
                    : activeMembers.first.userId);

            final selectedMember = activeMembers.firstWhere(
              (m) => m.userId == currentSelectedId,
              orElse: () => activeMembers.first,
            );

            // A의 마니또였던 멤버 B (target_user_id == A)
            final manitoMemberB = activeMembers.firstWhere(
              (m) => m.targetUserId == selectedMember.userId,
              orElse: () => selectedMember,
            );

            return recordsAsync.when(
              loading: () => Scaffold(
                appBar: AppBar(title: Text(roomTitle)),
                body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (err, _) => Scaffold(
                appBar: AppBar(title: Text(roomTitle)),
                body: Center(child: Text('기록을 불러오지 못했습니다: $err')),
              ),
              data: (records) {
                // 1. B가 작성한 미션 수행 기록 (B -> A)
                final missionRecord = records.cast<RecordModel?>().firstWhere(
                      (r) => r?.userId == manitoMemberB.userId && r?.recordType == RecordType.missionPerform,
                      orElse: () => null,
                    );

                // 2. A가 작성한 마니또 추측 기록
                final guessRecord = records.cast<RecordModel?>().firstWhere(
                      (r) => r?.userId == selectedMember.userId && r?.recordType == RecordType.suspectGuess,
                      orElse: () => null,
                    );

                // 댓글을 연결할 기준 레코드 ID (추측 기록 우선, 없으면 미션 기록)
                final commentTargetRecordId = guessRecord?.recordId ?? missionRecord?.recordId;
                final selectedMemberName = selectedMember.userProfile?.name ?? '요원';

                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return;
                    _handleBackNavigation(context);
                  },
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(roomTitle),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => _handleBackNavigation(context),
                      ),
                    ),
                    body: Column(
                      children: [
                        // 1. 상단: 참여한 친구들의 프로필 가로 스크롤 바 (Tier 3 뱃지 포함)
                        _buildMemberHorizontalList(activeMembers, currentSelectedId, records),
                        const Divider(height: 1, color: AppColors.border),

                        // 2. 본문 스크롤 영역: [미션 수행 기록] + [추측한 마니또 기록]
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(roomRecordsProvider(widget.roomId));
                              ref.invalidate(roomMembersProvider(widget.roomId));
                              ref.invalidate(unreadCommentSummaryProvider);
                            },
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 섹션 1: A의 마니또였던 B가 작성한 미션 수행 기록
                                  _buildMissionPerformSection(
                                    selectedMember: selectedMember,
                                    manitoMember: manitoMemberB,
                                    record: missionRecord,
                                    lang: lang,
                                  ),
                                  const SizedBox(height: 20),

                                  // 섹션 2: A가 지목한 마니또와 추측 기록
                                  _buildSuspectGuessSection(
                                    selectedMember: selectedMember,
                                    manitoMember: manitoMemberB,
                                    record: guessRecord,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 3. 화면 하단 고정 댓글 바 (Tier 4 뱃지 포함)
                    bottomNavigationBar: _buildBottomCommentBar(
                      targetRecordId: commentTargetRecordId,
                      selectedMemberName: selectedMemberName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 상단 가로 스크롤 친구 프로필 바 (깔끔한 원형 아바타 + 이름 + 미확인 댓글 뱃지)
  Widget _buildMemberHorizontalList(
    List<RoomMemberModel> members,
    String selectedId,
    List<RecordModel> records,
  ) {
    final unreadSummary = ref.watch(unreadCommentSummaryProvider).value;

    return Container(
      height: 90,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) {
          final member = members[idx];
          final isSelected = member.userId == selectedId;
          final profile = member.userProfile;
          final name = profile?.name ?? '요원';
          final imgUrl = profile?.profileImageUrl;

          // A의 마니또였던 B
          final manitoB = members.firstWhere(
            (other) => other.targetUserId == member.userId,
            orElse: () => member,
          );

          // 이 멤버와 관련된 레코드들
          final missionRecord = records.cast<RecordModel?>().firstWhere(
            (r) => r?.userId == manitoB.userId && r?.recordType == RecordType.missionPerform,
            orElse: () => null,
          );
          final guessRecord = records.cast<RecordModel?>().firstWhere(
            (r) => r?.userId == member.userId && r?.recordType == RecordType.suspectGuess,
            orElse: () => null,
          );

          final missionUnread = missionRecord != null ? (unreadSummary?.recordCounts[missionRecord.recordId] ?? 0) : 0;
          final guessUnread = guessRecord != null ? (unreadSummary?.recordCounts[guessRecord.recordId] ?? 0) : 0;
          final hasMemberUnread = (missionUnread + guessUnread) > 0;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedUserId = member.userId;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(
                            color: isSelected ? AppColors.primaryDark : AppColors.border,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                        ),
                        child: ClipOval(
                          child: (imgUrl != null && imgUrl.isNotEmpty)
                              ? (imgUrl.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: imgUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: AppColors.surface),
                                      errorWidget: (_, __, ___) => const Icon(Icons.person, size: 24, color: AppColors.textSecondary),
                                    )
                                  : Image.asset(imgUrl, fit: BoxFit.cover))
                              : const Icon(Icons.person, size: 24, color: AppColors.textSecondary),
                        ),
                      ),
                      if (hasMemberUnread)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// [마니또 미션 수행] 섹션: B 프로필 -> B가 선택한 미션 내용 -> B가 작성한 내용
  Widget _buildMissionPerformSection({
    required RoomMemberModel selectedMember,
    required RoomMemberModel manitoMember,
    required RecordModel? record,
    required String lang,
  }) {
    final aName = selectedMember.userProfile?.name ?? '요원';
    final bProfile = manitoMember.userProfile;
    final bName = bProfile?.name ?? '마니또';
    final bProfileImg = bProfile?.profileImageUrl;
    final assignedMission = manitoMember.assignedMission?.getContent(lang);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. "A님의 마니또" 타이틀
            Text(
              '$aName님의 마니또',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),

            // 2. B의 프로필 (사진, 이름, 상태메시지 - 추측 섹션과 동일한 44px 아바타 & 라운드 카드)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLow,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipOval(
                      child: (bProfileImg != null && bProfileImg.isNotEmpty)
                          ? (bProfileImg.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: bProfileImg,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: AppColors.surface),
                                  errorWidget: (_, __, ___) => const Icon(Icons.person, size: 24, color: AppColors.textSecondary),
                                )
                              : Image.asset(bProfileImg, fit: BoxFit.cover))
                          : const Icon(Icons.person, size: 24, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bName,
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (bProfile?.statusMessage != null && bProfile!.statusMessage!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            bProfile.statusMessage!,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
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
            const SizedBox(height: 14),

            // 2. B가 선택한 미션 내용
            if (assignedMission != null && assignedMission.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎯 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        assignedMission,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 3. B가 작성한 내용 (사진 및 텍스트)
            if (record != null) ...[
              _renderRecordContentBlocks(record.content),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Text(
                  '$bName님이 등록한 기록이 없습니다.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// [마니또 추측] 섹션: "A님이 추측한 마니또" -> 선택된 사용자 프로필(사진, 이름, 상태메시지) -> A가 작성한 내용
  Widget _buildSuspectGuessSection({
    required RoomMemberModel selectedMember,
    required RoomMemberModel manitoMember,
    required RecordModel? record,
  }) {
    final aName = selectedMember.userProfile?.name ?? '요원';
    final suspectUser = record?.suspectUser;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. "A님이 추측한 마니또" 타이틀
            Text(
              '$aName님이 추측한 마니또',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),

            // 2. 선택한 사용자 프로필 (사진, 이름, 상태메시지)
            if (suspectUser != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceLow,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipOval(
                        child: (suspectUser.profileImageUrl != null && suspectUser.profileImageUrl!.isNotEmpty)
                            ? (suspectUser.profileImageUrl!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: suspectUser.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: AppColors.surface),
                                    errorWidget: (_, __, ___) => const Icon(Icons.person, size: 24, color: AppColors.textSecondary),
                                  )
                                : Image.asset(suspectUser.profileImageUrl!, fit: BoxFit.cover))
                            : const Icon(Icons.person, size: 24, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suspectUser.name,
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          if (suspectUser.statusMessage != null && suspectUser.statusMessage!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              suspectUser.statusMessage!,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
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
              const SizedBox(height: 14),
            ],

            // 3. A가 작성한 단서 및 추측 내용 (사진 & 텍스트)
            if (record != null) ...[
              _renderRecordContentBlocks(record.content),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Text(
                  '$aName님이 등록한 기록이 없습니다.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 블록 렌더러 (이미지 & 텍스트)
  Widget _renderRecordContentBlocks(List<RecordBlock> blocks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks.map((block) {
        if (block.type == BlockType.image) {
          if (block.value.trim().isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: block.value.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: block.value,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        height: 200,
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 100,
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
                      ),
                    )
                  : Image.asset(
                      block.value,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    ),
            ),
          );
        } else {
          if (block.value.trim().isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              block.value,
              style: AppTypography.bodyMd.copyWith(height: 1.45),
            ),
          );
        }
      }).toList(),
    );
  }

  /// 화면 하단 고정 댓글 바 (Tier 4 뱃지 포함)
  Widget _buildBottomCommentBar({
    required int? targetRecordId,
    required String selectedMemberName,
  }) {
    final commentsAsync = targetRecordId != null
        ? ref.watch(recordCommentsProvider(targetRecordId))
        : null;
    final commentCount = commentsAsync?.value?.length ?? 0;
    final unreadCount = targetRecordId != null
        ? ref.watch(recordUnreadCommentCountProvider(targetRecordId))
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: AppColors.cardShadow,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: InkWell(
            onTap: () => _openCommentsSheet(context, targetRecordId, selectedMemberName),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: unreadCount > 0 ? AppColors.error.withValues(alpha: 0.5) : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.textSecondary),
                      if (unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -3,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '댓글을 남겨보세요.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled),
                    ),
                  ),
                  if (commentCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: unreadCount > 0
                            ? AppColors.error.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '댓글 $commentCount',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: unreadCount > 0 ? AppColors.error : AppColors.primaryDark,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+$unreadCount',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
