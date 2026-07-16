import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MissionService {
  final SupabaseClient _supabase;
  MissionService(this._supabase);

  /// 내가 생성한 미션 데이터 가져오기
  Future<List<Map<String, dynamic>>> fetchMyMissionsData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final List<dynamic> missionsData = await _supabase
          .from('missions')
          .select(
            'id, friend_ids, status, content_type, deadline, accept_deadline, created_at',
          )
          .eq('creator_id', userId)
          .isFilter('guess', null);

      return missionsData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('MissionService.fetchMyMissionsData Error: $e');
      rethrow;
    }
  }
}

class MissionCreateService {
  final SupabaseClient _supabase;
  MissionCreateService(this._supabase);

  // 싱글 미션 생성
  Future<void> createSingleMission({
    required List<String> friendIds,
    required String contentType,
    required DateTime acceptDeadline,
    required DateTime deadline,
  }) async {
    try {
      final creatorId = _supabase.auth.currentUser!.id;
      await _supabase.from('missions').insert({
        "creator_id": creatorId,
        "friend_ids": friendIds,
        "accept_deadline": acceptDeadline.toIso8601String(),
        "deadline": deadline.toIso8601String(),
        "content_type": contentType,
      });
    } catch (e) {
      debugPrint('MissionCreateService.createSingleMission Error: $e');
      rethrow;
    }
  }

  // 그룹 미션 생성
  Future<void> createGroupMission({
    required List<String> friendIds,
    required String contentType,
    required DateTime deadline,
  }) async {
    try {
      final creatorId = _supabase.auth.currentUser!.id;
      friendIds.add(creatorId);
      final data = await _supabase.rpc(
        'create_group_room',
        params: {
          "p_user_ids": friendIds,
          "p_content_type": contentType,
          "p_deadline": deadline.toIso8601String(),
        },
      );
      print(data);

      ///
      /// 미션 만들고 보낸미션, 받은미션 가져옴
      ///
      ///
    } catch (e) {
      debugPrint('MissionCreateService.createGroupMission Error: $e');
      rethrow;
    }
  }
}

class MissionGroupCreateService {
  final SupabaseClient _supabase;
  MissionGroupCreateService(this._supabase);

  Future<String> createGroupRoom({
    required String title,
    required String contentType,
    required String limitTime,
  }) async {
    try {
      final creatorId = _supabase.auth.currentUser!.id;
      final data =
          await _supabase
              .from('group_rooms')
              .insert({
                "creator_id": creatorId,
                "title": title,
                "content_type": contentType,
                "limit_time": limitTime,
              })
              .select('id')
              .single();
      return data['id'];
    } catch (e) {
      debugPrint('MissionGroupCreateService.createGroupMissionRoom Error: $e');
      rethrow;
    }
  }
}

// class MissionGroupSearchService {
//   final SupabaseClient _supabase;
//   MissionGroupSearchService(this._supabase);

//   Future<String?> searchCode(String code) async {
//     try {
//       final result =
//           await _supabase
//               .from("group_room_codes")
//               .select("group_rooms(*)")
//               .eq('code', code)
//               .maybeSingle();
//       // return result;
//     } catch (e) {
//       debugPrint('MissionGroupSearchService.searchCode Error: $e');
//     }
//   }
// }

class MissionGuessService {
  final SupabaseClient _supabase;
  MissionGuessService(this._supabase);

  /// 미션 추측 업데이트 - 수정 필요
  Future<void> updateMissionGuess(String missionId, String text) async {
    try {
      await _supabase.rpc(
        'mission_complete',
        params: {'p_mission_id': missionId, 'p_guess': text},
      );
    } catch (e) {
      debugPrint('MissionGuessService.updateMissionGuess Error: $e');
    }
  }
}
