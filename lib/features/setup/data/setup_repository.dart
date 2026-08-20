import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/util/app_logger.dart';

class SetupRepository {
  final SupabaseClient _supabase;

  SetupRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch the current user's room member record including target user profile
  Future<RoomMemberModel?> fetchMyMemberRecord(String roomId) async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final response = await _supabase
          .from('room_members')
          .select('*, target_user:users!room_members_target_user_id_fkey(*), mission:missions!assigned_mission_id(*)')
          .eq('room_id', roomId)
          .eq('user_id', uid)
          .maybeSingle();

      if (response == null) return null;
      return RoomMemberModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('fetchMyMemberRecord Error: $e', tag: 'SETUP', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Fetch mission candidates for this member
  Future<MissionCandidateModel?> fetchMissionCandidates(int roomMemberId) async {
    try {
      final response = await _supabase
          .from('mission_candidates')
          .select('*, mission_1:missions!candidate_mission_1_id(*), mission_2:missions!candidate_mission_2_id(*)')
          .eq('room_member_id', roomMemberId)
          .order('candidate_id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return MissionCandidateModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('fetchMissionCandidates Error: $e', tag: 'SETUP', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Finalize mission (User selection or Timeout fallback)
  Future<int> finalizeMission(int roomMemberId, [int? selectedMissionId]) async {
    try {
      AppLogger.i('Finalizing mission: member=$roomMemberId, selected=$selectedMissionId', tag: 'SETUP');
      final result = await _supabase.rpc('finalize_member_mission', params: {
        'p_room_member_id': roomMemberId,
        if (selectedMissionId != null) 'p_selected_mission_id': selectedMissionId,
      });

      if (result == null || result['success'] != true) {
        throw Exception('미션 확정 실패: $result');
      }

      AppLogger.i('Mission finalized: assigned=${result['assigned_mission_id']}', tag: 'SETUP');
      return result['assigned_mission_id'] as int;
    } catch (e, s) {
      AppLogger.e('finalizeMission Error: $e', tag: 'SETUP', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Check if all accepted members have selected their missions, and transition room to ONGOING
  Future<bool> checkAndStartOngoingGame(String roomId) async {
    try {
      final members = await _supabase
          .from('room_members')
          .select('is_mission_selected')
          .eq('room_id', roomId)
          .eq('join_status', '✔️');

      final allReady = (members as List).every((m) => m['is_mission_selected'] == true);
      if (allReady) {
        AppLogger.i('All members ready! Starting game for room: $roomId', tag: 'SETUP');
        await _supabase.from('rooms').update({
          'status': 'ONGOING',
          'game_start_time': DateTime.now().toUtc().toIso8601String(),
        }).eq('room_id', roomId);
        return true;
      }
      return false;
    } catch (e, s) {
      AppLogger.e('checkAndStartOngoingGame Error: $e', tag: 'SETUP', error: e, stackTrace: s);
      rethrow;
    }
  }
}
