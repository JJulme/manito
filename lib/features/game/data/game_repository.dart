import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/util/app_logger.dart';

class GameRepository {
  final SupabaseClient _supabase;

  GameRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch existing record for current user in a room
  Future<RecordModel?> fetchMyRecord(String roomId, RecordType type) async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final response = await _supabase
          .from('records')
          .select('*, author:users!records_user_id_fkey(*), suspect_user:users!records_suspect_user_id_fkey(*)')
          .eq('room_id', roomId)
          .eq('user_id', uid)
          .eq('record_type', type.value)
          .eq('is_deleted', false)
          .maybeSingle();

      if (response == null) return null;
      return RecordModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('fetchMyRecord Error: $e', tag: 'GAME', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Upload evidence image to Supabase Storage
  Future<String> uploadEvidenceImage(File file) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    try {
      AppLogger.i('Uploading evidence image...', tag: 'GAME');
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'evidence/$fileName';

      await _supabase.storage.from('records').upload(path, file);
      final publicUrl = _supabase.storage.from('records').getPublicUrl(path);
      AppLogger.i('Evidence image uploaded: $publicUrl', tag: 'GAME');
      return publicUrl;
    } catch (e, s) {
      AppLogger.e('uploadEvidenceImage Error: $e', tag: 'GAME', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Save or update activity record (JSONB blocks)
  Future<RecordModel> saveRecord({
    required String roomId,
    required RecordType recordType,
    String? suspectUserId,
    required List<RecordBlock> content,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    try {
      AppLogger.i('Saving record: room=$roomId, type=${recordType.value}, blocks=${content.length}', tag: 'GAME');
      final contentJson = content.map((b) => b.toJson()).toList();

      final response = await _supabase
          .from('records')
          .upsert(
            {
              'room_id': roomId,
              'user_id': uid,
              'record_type': recordType.value,
              'suspect_user_id': suspectUserId,
              'content': contentJson,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'room_id, user_id, record_type',
          )
          .select('*, author:users!records_user_id_fkey(*), suspect_user:users!records_suspect_user_id_fkey(*)')
          .single();

      AppLogger.i('Record saved successfully', tag: 'GAME');
      return RecordModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('saveRecord Error: $e', tag: 'GAME', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Fetch all active room members for suspect candidate selection
  Future<List<RoomMemberModel>> fetchSuspectCandidates(String roomId) async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final response = await _supabase
          .from('room_members')
          .select('*, user:users!room_members_user_id_fkey(*)')
          .eq('room_id', roomId)
          .eq('join_status', '✔️')
          .neq('user_id', uid);

      return (response as List).map((json) => RoomMemberModel.fromJson(json)).toList();
    } catch (e, s) {
      AppLogger.e('fetchSuspectCandidates Error: $e', tag: 'GAME', error: e, stackTrace: s);
      rethrow;
    }
  }
}
