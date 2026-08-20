import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/notifications/notification_sender.dart';
import 'package:manito/core/util/app_logger.dart';

class RoomsRepository {
  final SupabaseClient _supabase;

  RoomsRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch ongoing rooms where current user is participating or hosting
  Future<List<RoomModel>> fetchOngoingRooms() async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('rooms')
          .select('*, host:users!host_id(*), room_members!inner(user_id, join_status)')
          .eq('room_members.user_id', uid)
          .eq('room_members.join_status', '✔️')
          .inFilter('status', ['WAITING', 'PREPARING', 'ONGOING'])
          .order('created_at', ascending: false);

      final now = DateTime.now();
      final list = (response as List)
          .map((json) => RoomModel.fromJson(json))
          .where((room) {
            // 게임이 시작되지 않은 대기실은 10분 후 자동 만료
            if (room.status == RoomStatus.waiting) {
              return now.difference(room.createdAt).inSeconds < 600;
            }
            return true;
          })
          .toList();

      AppLogger.d('Fetched ${list.length} valid ongoing rooms', tag: 'ROOMS');
      return list;
    } catch (e, s) {
      AppLogger.e('fetchOngoingRooms Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Fetch received invitations with pending status '-'
  Future<List<RoomMemberModel>> fetchReceivedInvitations() async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('room_members')
          .select('*, room:rooms(*, host:users!host_id(*))')
          .eq('user_id', uid)
          .eq('join_status', '-')
          .order('created_at', ascending: false);

      final now = DateTime.now();
      return (response as List).map((json) {
        final roomJson = json['room'] as Map<String, dynamic>?;
        final roomModel = roomJson != null ? RoomModel.fromJson(roomJson) : null;

        return RoomMemberModel(
          roomMemberId: json['room_member_id'] as int,
          roomId: json['room_id'] as String,
          userId: json['user_id'] as String,
          joinStatus: json['join_status'] as String,
          isMissionSelected: json['is_mission_selected'] as bool? ?? false,
          isInviteViewed: json['is_invite_viewed'] as bool? ?? false,
          createdAt: DateTime.parse(json['created_at'] as String),
          userProfile: roomJson?['host'] != null
              ? UserModel.fromJson(roomJson!['host'] as Map<String, dynamic>)
              : null,
          room: roomModel,
        );
      }).where((invite) {
        // 10분 지난 대기실 초대장은 자동 제외
        if (invite.room != null && invite.room!.status == RoomStatus.waiting) {
          return now.difference(invite.room!.createdAt).inSeconds < 600;
        }
        return true;
      }).toList();
    } catch (e, s) {
      AppLogger.e('fetchReceivedInvitations Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Create a new game room and add host as accepted member
  Future<RoomModel> createRoom({
    String? title,
    String? missionCategory,
    DateTime? gameEndTime,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    try {
      final ongoing = await fetchOngoingRooms();
      if (ongoing.isNotEmpty) {
        throw Exception('이미 진행 중이거나 대기 중인 마니또 방이 있습니다.');
      }

      AppLogger.i('Creating new room: title=$title, category=$missionCategory, end=$gameEndTime', tag: 'ROOMS');
      final roomResponse = await _supabase
          .from('rooms')
          .insert({
            'host_id': uid,
            'title': title ?? '마니또 대기실',
            'status': 'WAITING',
            'mission_category': missionCategory ?? 'daily',
            'game_end_time': gameEndTime?.toUtc().toIso8601String(),
          })
          .select()
          .single();

      final room = RoomModel.fromJson(roomResponse);

      // Host joins as accepted
      await _supabase.from('room_members').insert({
        'room_id': room.roomId,
        'user_id': uid,
        'join_status': '✔️',
        'is_invite_viewed': true,
      });

      AppLogger.i('Room created successfully: ${room.roomId}', tag: 'ROOMS');
      return room;
    } catch (e, s) {
      AppLogger.e('createRoom Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Update room settings by host (Title, Mission Category, Deadline)
  Future<RoomModel> updateRoomSettings({
    required String roomId,
    String? title,
    String? missionCategory,
    DateTime? gameEndTime,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (missionCategory != null) updates['mission_category'] = missionCategory;
      if (gameEndTime != null) updates['game_end_time'] = gameEndTime.toUtc().toIso8601String();

      AppLogger.i('Updating room settings for $roomId: $updates', tag: 'ROOMS');
      final response = await _supabase
          .from('rooms')
          .update(updates)
          .eq('room_id', roomId)
          .eq('host_id', uid)
          .select()
          .single();

      AppLogger.i('Room settings updated successfully: $roomId', tag: 'ROOMS');
      return RoomModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('updateRoomSettings Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Invite friends to room
  Future<void> inviteFriends(String roomId, List<String> friendUserIds) async {
    try {
      final rows = friendUserIds.map((fId) => {
            'room_id': roomId,
            'user_id': fId,
            'join_status': '-',
            'is_invite_viewed': false,
          }).toList();

      if (rows.isNotEmpty) {
        await _supabase.from('room_members').upsert(rows, onConflict: 'room_id, user_id');
        AppLogger.i('Invited ${friendUserIds.length} friends to room $roomId', tag: 'ROOMS');

        // 알림 발송 트리거
        try {
          final roomData = await _supabase.from('rooms').select('title, host_id').eq('room_id', roomId).maybeSingle();
          final hostProfile = await _supabase.from('users').select('name').eq('user_id', _supabase.auth.currentUser?.id ?? '').maybeSingle();
          final hostName = (hostProfile?['name'] as String?)?.trim().isNotEmpty == true
              ? (hostProfile!['name'] as String).trim()
              : '요원';
          final roomTitle = roomData?['title'] as String? ?? '마니또 방';

          final sender = NotificationSender();
          await sender.sendRoomInvitationNotification(
            roomId: roomId,
            invitedUserIds: friendUserIds,
            hostName: hostName,
            roomTitle: roomTitle,
          );
        } catch (notifErr) {
          AppLogger.w('Failed to dispatch room invitation notification: $notifErr', tag: 'ROOMS');
        }
      }
    } catch (e, s) {
      AppLogger.e('inviteFriends Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Respond to room invitation ('✔️' or 'X')
  Future<void> respondToInvitation(int roomMemberId, String status) async {
    try {
      if (status == '✔️') {
        final ongoing = await fetchOngoingRooms();
        if (ongoing.isNotEmpty) {
          throw Exception('이미 참여 중인 마니또가 있어 새로운 방에 참여할 수 없습니다.');
        }
      }

      await _supabase.from('room_members').update({
        'join_status': status,
        'is_invite_viewed': true,
      }).eq('room_member_id', roomMemberId);
      AppLogger.i('Responded to invite $roomMemberId: $status', tag: 'ROOMS');

      // 수락 시 방장에게 알림 발송 트리거
      if (status == '✔️') {
        try {
          final memberData = await _supabase.from('room_members').select('room_id, users(name)').eq('room_member_id', roomMemberId).maybeSingle();
          final rId = memberData?['room_id'] as String?;
          if (rId != null) {
            final roomData = await _supabase.from('rooms').select('host_id, title').eq('room_id', rId).maybeSingle();
            final hostId = roomData?['host_id'] as String?;
            final roomTitle = roomData?['title'] as String? ?? '마니또 방';
            final participantName = memberData?['users']?['name'] as String? ?? '요원';

            if (hostId != null) {
              final sender = NotificationSender();
              await sender.sendInviteAcceptedNotification(
                roomId: rId,
                hostUserId: hostId,
                participantName: participantName,
                roomTitle: roomTitle,
              );
            }
          }
        } catch (notifErr) {
          AppLogger.w('Failed to dispatch invite accepted notification: $notifErr', tag: 'ROOMS');
        }
      }
    } catch (e, s) {
      AppLogger.e('respondToInvitation Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Mark invitation as viewed
  Future<void> markInviteViewed(int roomMemberId) async {
    try {
      await _supabase.from('room_members').update({
        'is_invite_viewed': true,
      }).eq('room_member_id', roomMemberId);
    } catch (e, s) {
      AppLogger.e('markInviteViewed Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
    }
  }

  /// Fetch room details
  Future<RoomModel?> getRoom(String roomId) async {
    try {
      final response = await _supabase
          .from('rooms')
          .select('*, host:users!host_id(*)')
          .eq('room_id', roomId)
          .maybeSingle();

      if (response == null) return null;
      return RoomModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('getRoom Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Fetch all members of a room with profiles and assigned missions
  Future<List<RoomMemberModel>> fetchRoomMembers(String roomId) async {
    try {
      final response = await _supabase
          .from('room_members')
          .select('*, user:users!room_members_user_id_fkey(*), target_user:users!room_members_target_user_id_fkey(*), mission:missions!room_members_assigned_mission_id_fkey(*)')
          .eq('room_id', roomId)
          .order('created_at', ascending: true);

      return (response as List).map((json) => RoomMemberModel.fromJson(json)).toList();
    } catch (e, s) {
      AppLogger.e('fetchRoomMembers Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Delete room as host
  Future<void> deleteRoom(String roomId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    try {
      AppLogger.i('Deleting room as host: $roomId', tag: 'ROOMS');
      await _supabase.from('rooms').delete().eq('room_id', roomId).eq('host_id', uid);
      AppLogger.i('Room deleted successfully: $roomId', tag: 'ROOMS');
    } catch (e, s) {
      AppLogger.e('deleteRoom Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Leave room as member
  Future<void> leaveRoom(String roomId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    try {
      AppLogger.i('Leaving room as member: $roomId', tag: 'ROOMS');
      await _supabase
          .from('room_members')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', uid);
      AppLogger.i('Left room successfully: $roomId', tag: 'ROOMS');
    } catch (e, s) {
      AppLogger.e('leaveRoom Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Execute 1:1 Circular Matching RPC to start the game
  Future<void> startGameAndMatch(String roomId) async {
    try {
      AppLogger.i('Starting game and matching for room: $roomId', tag: 'ROOMS');
      final result = await _supabase.rpc('start_game_and_match', params: {
        'p_room_id': roomId,
      });
      if (result == null || result['success'] != true) {
        throw Exception('게임 시작 및 매칭 실패: $result');
      }
      AppLogger.i('Matching completed successfully for room: $roomId', tag: 'ROOMS');

      // 방 시작 푸시 알림 발송 (전체 참여자 대상)
      try {
        final uid = currentUserId;
        final membersRes = await _supabase
            .from('room_members')
            .select('user_id')
            .eq('room_id', roomId)
            .eq('join_status', '✔️');

        final targetUserIds = (membersRes as List)
            .map((m) => m['user_id'] as String)
            .where((id) => id != uid)
            .toList();

        if (targetUserIds.isNotEmpty) {
          final roomRes = await _supabase
              .from('rooms')
              .select('title')
              .eq('room_id', roomId)
              .maybeSingle();

          final roomTitle = roomRes?['title'] as String? ?? '마니또';

          final sender = NotificationSender();
          await sender.sendGameStartedNotification(
            roomId: roomId,
            memberUserIds: targetUserIds,
            roomTitle: roomTitle,
          );
        }
      } catch (notifErr) {
        AppLogger.w('Failed to send game started push notification: $notifErr', tag: 'ROOMS');
      }
    } catch (e, s) {
      AppLogger.e('startGameAndMatch Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Update room status (e.g. ENDED)
  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      AppLogger.i('Updating room $roomId status to ${status.value}', tag: 'ROOMS');
      await _supabase.from('rooms').update({'status': status.value}).eq('room_id', roomId);
      AppLogger.i('Room status updated to ${status.value}', tag: 'ROOMS');
    } catch (e, s) {
      AppLogger.e('updateRoomStatus Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
    }
  }

  /// Finalize game on server and batch-fill auto replies for all members
  Future<void> finalizeGameAndFillAutoReplies(String roomId) async {
    try {
      AppLogger.i('Calling finalize_game_and_fill_auto_replies RPC for room: $roomId', tag: 'ROOMS');
      await _supabase.rpc('finalize_game_and_fill_auto_replies', params: {
        'p_room_id': roomId,
      });
      AppLogger.i('Game finalized and auto-replies filled on server for room: $roomId', tag: 'ROOMS');
    } catch (e, s) {
      AppLogger.e('finalizeGameAndFillAutoReplies Error: $e', tag: 'ROOMS', error: e, stackTrace: s);
    }
  }
}
