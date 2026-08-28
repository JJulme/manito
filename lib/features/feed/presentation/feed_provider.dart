import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/models/models.dart';
import '../data/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return FeedRepository(supabase);
});

final roomRecordsProvider =
    FutureProvider.autoDispose.family<List<RecordModel>, String>((ref, roomId) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.fetchRoomRecords(roomId);
});

final recordCommentsProvider =
    FutureProvider.autoDispose.family<List<CommentModel>, int>((ref, recordId) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.fetchComments(recordId);
});

/// 전체 미확인 댓글 요약 Provider
final unreadCommentSummaryProvider =
    FutureProvider.autoDispose<UnreadCommentSummary>((ref) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.fetchUnreadCommentSummary();
});

/// [Tier 1] 바텀 네비게이션용 전체 안 읽은 댓글 수
final totalUnreadCommentCountProvider = Provider.autoDispose<int>((ref) {
  final summaryAsync = ref.watch(unreadCommentSummaryProvider);
  return summaryAsync.maybeWhen(
    data: (summary) => summary.total,
    orElse: () => 0,
  );
});

/// [Tier 2] 방 카드용 해당 방의 안 읽은 댓글 수
final roomUnreadCommentCountProvider =
    Provider.autoDispose.family<int, String>((ref, roomId) {
  final summaryAsync = ref.watch(unreadCommentSummaryProvider);
  return summaryAsync.maybeWhen(
    data: (summary) => summary.roomCounts[roomId] ?? 0,
    orElse: () => 0,
  );
});

/// [Tier 4] 특정 레코드의 안 읽은 댓글 수
final recordUnreadCommentCountProvider =
    Provider.autoDispose.family<int, int>((ref, recordId) {
  final summaryAsync = ref.watch(unreadCommentSummaryProvider);
  return summaryAsync.maybeWhen(
    data: (summary) => summary.recordCounts[recordId] ?? 0,
    orElse: () => 0,
  );
});

/// 하위 호환용
final unreadCommentCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, roomId) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.getUnreadCommentCount(roomId);
});

final completedRoomsProvider = FutureProvider.autoDispose<List<RoomModel>>((ref) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.fetchCompletedRooms();
});

final roomThumbnailProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, roomId) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.fetchRoomThumbnail(roomId);
});

final sharedCompletedRoomsProvider =
    FutureProvider.autoDispose.family<List<RoomModel>, String>((ref, friendUserId) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.fetchSharedCompletedRooms(friendUserId);
});
