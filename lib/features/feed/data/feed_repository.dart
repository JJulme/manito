import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/notifications/notification_sender.dart';

class FeedRepository {
  final SupabaseClient _supabase;

  FeedRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch all records of a completed room (ensures server-side auto-reply generation)
  Future<List<RecordModel>> fetchRoomRecords(String roomId) async {
    try {
      // 1. 서버 RPC 호출로 누락된 참여자 자동응답 일괄 생성 및 완료 처리
      try {
        await _supabase.rpc('finalize_game_and_fill_auto_replies', params: {
          'p_room_id': roomId,
        });
      } catch (rpcErr) {
        AppLogger.w('finalize_game_and_fill_auto_replies RPC warning: $rpcErr', tag: 'FEED');
      }

      // 2. 전체 레코드 조회
      final response = await _supabase
          .from('records')
          .select('*, author:users!records_user_id_fkey(*), suspect_user:users!records_suspect_user_id_fkey(*), comments(*)')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      AppLogger.d('Fetched ${(response as List).length} feed records for room $roomId', tag: 'FEED');
      return response.map((json) => RecordModel.fromJson(json)).toList();
    } catch (e, s) {
      AppLogger.e('fetchRoomRecords Error: $e', tag: 'FEED', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Fetch comments for a specific record
  Future<List<CommentModel>> fetchComments(int recordId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, author:users!user_id(*)')
          .eq('record_id', recordId)
          .order('created_at', ascending: true);

      return (response as List).map((json) => CommentModel.fromJson(json)).toList();
    } catch (e, s) {
      AppLogger.e('fetchComments Error: $e', tag: 'FEED', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Post a new comment (triggers fn_on_comment_created to notify all room members)
  Future<CommentModel> createComment({
    required int recordId,
    required String content,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    try {
      AppLogger.i('Posting comment on record: $recordId', tag: 'FEED');
      final response = await _supabase
          .from('comments')
          .insert({
            'record_id': recordId,
            'user_id': uid,
            'content': content,
          })
          .select('*, author:users!user_id(*)')
          .single();

      final createdComment = CommentModel.fromJson(response);
      AppLogger.i('Comment posted successfully (ID: ${createdComment.commentId})', tag: 'FEED');

      // 푸시 알림 발송 (방 참여자들에게)
      try {
        await _sendCommentPushNotification(
          recordId: recordId,
          commentContent: content,
          authorName: createdComment.author?.name ?? '마니또 요원',
        );
      } catch (err) {
        AppLogger.w('Failed to dispatch comment push notification: $err', tag: 'FEED');
      }

      return createdComment;
    } catch (e, s) {
      AppLogger.e('createComment Error: $e', tag: 'FEED', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _sendCommentPushNotification({
    required int recordId,
    required String commentContent,
    required String authorName,
  }) async {
    try {
      final uid = currentUserId;
      // 1. record로부터 room_id 조회
      final recordData = await _supabase
          .from('records')
          .select('room_id')
          .eq('record_id', recordId)
          .maybeSingle();

      if (recordData == null || recordData['room_id'] == null) {
        AppLogger.w('Record $recordId room_id not found', tag: 'FEED');
        return;
      }
      final roomId = recordData['room_id'] as String;

      // 2. 방 참여자 목록 조회 (작성자 본인 제외)
      final membersData = await _supabase
          .from('room_members')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('join_status', '✔️');

      final targetUserIds = (membersData as List)
          .map((m) => m['user_id'] as String)
          .where((id) => id != uid)
          .toList();

      AppLogger.i('Found ${targetUserIds.length} target users for comment push in room $roomId: $targetUserIds', tag: 'FEED');

      if (targetUserIds.isEmpty) return;

      // 3. NotificationSender를 통해 푸시 알림 발송
      final sender = NotificationSender();
      await sender.sendCommentCreatedNotification(
        roomId: roomId,
        recordId: recordId,
        targetUserIds: targetUserIds,
        authorName: authorName,
        commentText: commentContent,
      );
    } catch (e, s) {
      AppLogger.e('_sendCommentPushNotification error: $e', tag: 'FEED', error: e, stackTrace: s);
    }
  }

  /// Fetch unread comments summary (total, per-room, per-record)
  Future<UnreadCommentSummary> fetchUnreadCommentSummary() async {
    final uid = currentUserId;
    if (uid == null) return const UnreadCommentSummary();

    try {
      final res = await _supabase.rpc('get_unread_comment_counts', params: {
        'p_user_id': uid,
      });

      if (res != null) {
        final map = res is Map<String, dynamic>
            ? res
            : Map<String, dynamic>.from(res as Map);
        return UnreadCommentSummary.fromJson(map);
      }
      return const UnreadCommentSummary();
    } catch (e, s) {
      AppLogger.e('fetchUnreadCommentSummary Error: $e', tag: 'FEED', error: e, stackTrace: s);
      return const UnreadCommentSummary();
    }
  }

  /// Mark all comments in a specific record as read
  Future<void> markRecordCommentsAsRead(int recordId) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _supabase.rpc('mark_record_comments_as_read', params: {
        'p_record_id': recordId,
        'p_user_id': uid,
      });
      AppLogger.d('Marked comments as read for record $recordId', tag: 'FEED');
    } catch (e, s) {
      AppLogger.e('markRecordCommentsAsRead Error: $e', tag: 'FEED', error: e, stackTrace: s);
    }
  }

  /// Mark all comments in room as read for current user
  Future<void> markRoomCommentsAsRead(String roomId) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _supabase.rpc('mark_room_comments_as_read', params: {
        'p_room_id': roomId,
        'p_user_id': uid,
      });
      AppLogger.d('Marked comments as read for room $roomId', tag: 'FEED');
    } catch (e, s) {
      AppLogger.e('markRoomCommentsAsRead Error: $e', tag: 'FEED', error: e, stackTrace: s);
    }
  }

  /// Get unread comments count for a room
  Future<int> getUnreadCommentCount(String roomId) async {
    final summary = await fetchUnreadCommentSummary();
    return summary.roomCounts[roomId] ?? 0;
  }

  /// Fetch completed/archived rooms
  Future<List<RoomModel>> fetchCompletedRooms() async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('rooms')
          .select('*, room_members!inner(user_id, join_status)')
          .eq('room_members.user_id', uid)
          .eq('room_members.join_status', '✔️')
          .inFilter('status', ['COMPLETED', 'ENDED'])
          .order('created_at', ascending: false);

      return (response as List).map((json) => RoomModel.fromJson(json)).toList();
    } catch (e, s) {
      AppLogger.e('fetchCompletedRooms Error: $e', tag: 'FEED', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Fetch the representative thumbnail image for a room (first uploaded image in record blocks)
  Future<String?> fetchRoomThumbnail(String roomId) async {
    try {
      final response = await _supabase
          .from('records')
          .select('content')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      for (final r in response as List) {
        final content = r['content'];
        if (content is List) {
          for (final block in content) {
            if (block is Map && block['type'] == 'image' && (block['value'] as String?)?.isNotEmpty == true) {
              return block['value'] as String;
            }
          }
        }
      }
      return null;
    } catch (e, s) {
      AppLogger.e('fetchRoomThumbnail Error: $e', tag: 'FEED', error: e, stackTrace: s);
      return null;
    }
  }
}
