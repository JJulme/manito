import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/feed/presentation/feed_provider.dart';
import '../../features/friends/presentation/friends_provider.dart';
import '../../features/rooms/presentation/rooms_provider.dart';
import '../util/app_logger.dart';

final realtimeNotificationListenerProvider = Provider<RealtimeNotificationListener>((ref) {
  return RealtimeNotificationListener(ref);
});

/// Supabase Realtime 기반 포그라운드(앱 켜짐) 실시간 데이터 자동 동기화 리스너
class RealtimeNotificationListener {
  final Ref _ref;
  RealtimeChannel? _userChannel;
  StreamSubscription? _authSubscription;

  RealtimeNotificationListener(this._ref);

  /// 실시간 리스닝 시작
  void startListening(String userId) {
    if (_userChannel != null) {
      AppLogger.d('Realtime listener already active for $userId', tag: 'REALTIME_NOTIF');
      return;
    }

    AppLogger.i('Starting Realtime notification listener for user: $userId', tag: 'REALTIME_NOTIF');

    final supabase = Supabase.instance.client;

    _userChannel = supabase.channel('user-notifications-$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'room_members',
        callback: (payload) => _handleRoomMemberChange(payload, userId),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'friendships',
        callback: (payload) => _handleFriendshipChange(payload, userId),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'comments',
        callback: (payload) => _handleCommentInsert(payload, userId),
      )
      ..subscribe((status, [error]) {
        AppLogger.i('Realtime subscription status: $status, error: $error', tag: 'REALTIME_NOTIF');
      });
  }

  /// 실시간 리스닝 종료
  void stopListening() {
    if (_userChannel != null) {
      _userChannel?.unsubscribe();
      _userChannel = null;
      AppLogger.i('Realtime notification listener stopped', tag: 'REALTIME_NOTIF');
    }
    _authSubscription?.cancel();
    _authSubscription = null;
  }

  void _handleRoomMemberChange(PostgresChangePayload payload, String userId) {
    final record = payload.newRecord;
    final targetUserId = record['user_id'] as String?;
    final roomId = record['room_id'] as String?;
    final joinStatus = record['join_status'] as String?;

    if (targetUserId != userId) return;

    AppLogger.i('Realtime room_member change event: ${payload.eventType}, joinStatus: $joinStatus, roomId: $roomId', tag: 'REALTIME_NOTIF');

    if (payload.eventType == PostgresChangeEvent.insert) {
      // 신규 초대 도착 (joinStatus == '-')
      if (joinStatus == '-') {
        AppLogger.i('New room invitation received! Invalidating receivedRoomInvitationsProvider', tag: 'REALTIME_NOTIF');
        _ref.invalidate(receivedRoomInvitationsProvider);
        _ref.invalidate(ongoingRoomsProvider);
      }
    } else if (payload.eventType == PostgresChangeEvent.update) {
      // 상태 변경 (수락, 게임 시작 등)
      _ref.invalidate(receivedRoomInvitationsProvider);
      _ref.invalidate(ongoingRoomsProvider);
      if (roomId != null) {
        _ref.invalidate(roomMembersProvider(roomId));
        _ref.invalidate(roomDetailsProvider(roomId));
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      _ref.invalidate(receivedRoomInvitationsProvider);
      _ref.invalidate(ongoingRoomsProvider);
    }
  }

  void _handleFriendshipChange(PostgresChangePayload payload, String userId) {
    final record = payload.newRecord;
    final requesterId = record['requester_id'] as String?;
    final receiverId = record['receiver_id'] as String?;
    final status = record['status'] as String?;

    if (requesterId != userId && receiverId != userId) return;

    AppLogger.i('Realtime friendship change: status=$status', tag: 'REALTIME_NOTIF');
    _ref.invalidate(acceptedFriendsProvider);
    _ref.invalidate(receivedFriendRequestsProvider);
  }

  Future<void> _handleCommentInsert(PostgresChangePayload payload, String currentUserId) async {
    try {
      final record = payload.newRecord;
      final authorId = record['user_id'] as String?;
      final recordId = record['record_id'] as int?;

      // 작성자가 본인이면 스킵
      if (authorId == null || authorId == currentUserId || recordId == null) return;

      AppLogger.i('Realtime comment received: author=$authorId, recordId=$recordId', tag: 'REALTIME_NOTIF');

      final supabase = Supabase.instance.client;

      // 1. record로부터 room_id 조회
      final recordData = await supabase
          .from('records')
          .select('room_id')
          .eq('record_id', recordId)
          .maybeSingle();

      if (recordData == null || recordData['room_id'] == null) return;
      final roomId = recordData['room_id'] as String;

      // 2. 현재 사용자가 이 방의 멤버인지 확인
      final isMember = await supabase
          .from('room_members')
          .select('room_member_id')
          .eq('room_id', roomId)
          .eq('user_id', currentUserId)
          .eq('join_status', '✔️')
          .maybeSingle();

      if (isMember == null) return;

      // 4. Riverpod 프로바이더 실시간 갱신 (댓글 창이 열려있으면 즉시 새 댓글 렌더링)
      _ref.invalidate(recordCommentsProvider(recordId));
      _ref.invalidate(roomRecordsProvider(roomId));
      _ref.invalidate(unreadCommentCountProvider(roomId));
      _ref.invalidate(unreadCommentSummaryProvider);
    } catch (e, s) {
      AppLogger.e('Error handling realtime comment insert: $e', tag: 'REALTIME_NOTIF', error: e, stackTrace: s);
    }
  }
}
