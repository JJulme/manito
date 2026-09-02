import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/widget/network_error_view.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/analytics/analytics_event.dart';
import 'package:manito/core/analytics/analytics_service.dart';
import 'package:manito/features/rooms/presentation/rooms_provider.dart';
import 'package:manito/features/feed/presentation/feed_provider.dart';
import 'package:manito/features/feed/presentation/widgets/comments_sheet.dart';
import 'package:manito/features/feed/presentation/widgets/feed_bottom_comment_bar.dart';
import 'package:manito/features/feed/presentation/widgets/feed_member_horizontal_list.dart';
import 'package:manito/features/feed/presentation/widgets/feed_mission_perform_section.dart';
import 'package:manito/features/feed/presentation/widgets/feed_suspect_guess_section.dart';
import 'package:manito/features/main/main_nav_screen.dart';

class ResultFeedScreen extends ConsumerStatefulWidget {
  final String roomId;

  const ResultFeedScreen({super.key, required this.roomId});

  @override
  ConsumerState<ResultFeedScreen> createState() => _ResultFeedScreenState();
}

class _ResultFeedScreenState extends ConsumerState<ResultFeedScreen> {
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvent.resultFeedView,
        screenName: 'ResultFeedScreen',
        properties: {'room_id': widget.roomId},
      );
    });
  }

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
        appBar: AppBar(
          title: const Text('마니또 결과'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => _handleBackNavigation(context),
          ),
        ),
        body: SafeArea(
          child: NetworkErrorView(
            title: '방 정보를 불러오지 못했어요',
            onRetry: () => ref.invalidate(roomDetailsProvider(widget.roomId)),
          ),
        ),
      ),
      data: (room) {
        final roomTitle = room?.title ?? '마니또 결과';

        return membersAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(
              title: Text(roomTitle),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => _handleBackNavigation(context),
              ),
            ),
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (err, _) => Scaffold(
            appBar: AppBar(
              title: Text(roomTitle),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => _handleBackNavigation(context),
              ),
            ),
            body: SafeArea(
              child: NetworkErrorView(
                title: '멤버 정보를 불러오지 못했어요',
                onRetry: () => ref.invalidate(roomMembersProvider(widget.roomId)),
              ),
            ),
          ),
          data: (members) {
            final activeMembers = members.where((m) => m.joinStatus == '✔️').toList();

            if (activeMembers.isEmpty) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(roomTitle),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => _handleBackNavigation(context),
                  ),
                ),
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
                appBar: AppBar(
                  title: Text(roomTitle),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => _handleBackNavigation(context),
                  ),
                ),
                body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (err, _) => Scaffold(
                appBar: AppBar(
                  title: Text(roomTitle),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => _handleBackNavigation(context),
                  ),
                ),
                body: SafeArea(
                  child: NetworkErrorView(
                    title: '기록을 불러오지 못했어요',
                    onRetry: () => ref.invalidate(roomRecordsProvider(widget.roomId)),
                  ),
                ),
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
                    body: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          automaticallyImplyLeading: false,
                          backgroundColor: Theme.of(context).cardTheme.color ?? AppColors.cardOf(context),
                          floating: true,
                          snap: true,
                          pinned: false,
                          toolbarHeight: 91,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          flexibleSpace: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FeedMemberHorizontalList(
                                members: activeMembers,
                                selectedId: currentSelectedId,
                                records: records,
                                onMemberSelected: (userId) {
                                  ref.read(analyticsServiceProvider).logEvent(
                                    AnalyticsEvent.resultMemberFilter,
                                    screenName: 'ResultFeedScreen',
                                    properties: {
                                      'room_id': widget.roomId,
                                      'target_user_id': userId,
                                    },
                                  );
                                  setState(() => _selectedUserId = userId);
                                },
                              ),
                              Divider(height: 1, color: AppColors.borderOf(context)),
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 섹션 1: A의 마니또였던 B가 작성한 미션 수행 기록
                                FeedMissionPerformSection(
                                  selectedMember: selectedMember,
                                  manitoMember: manitoMemberB,
                                  record: missionRecord,
                                  lang: lang,
                                ),
                                const SizedBox(height: 20),

                                // 섹션 2: A가 지목한 마니또와 추측 기록
                                FeedSuspectGuessSection(
                                  selectedMember: selectedMember,
                                  manitoMember: manitoMemberB,
                                  record: guessRecord,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 3. 화면 하단 고정 댓글 바 (Tier 4 뱃지 포함)
                    bottomNavigationBar: FeedBottomCommentBar(
                      targetRecordId: commentTargetRecordId,
                      selectedMemberName: selectedMemberName,
                      onTap: () => _openCommentsSheet(context, commentTargetRecordId, selectedMemberName),
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
}
