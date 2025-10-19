import 'package:flutter/material.dart';
import 'package:manito/features/image/image_service.dart';
import 'package:manito/features/manito/manito.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManitoService {
  final SupabaseClient _supabase;
  ManitoService(this._supabase);

  // 제안 리스트 가져옴
  Future<List<ManitoPropose>> fetchProposeList() async {
    try {
      final data = await _supabase
          .from('mission_propose')
          .select('id, missions:mission_id(creator_id, accept_deadline)')
          .eq('friend_id', _supabase.auth.currentUser!.id);

      return data.map((e) => ManitoPropose.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ManitoService.fetchProposeList Error: $e');
      rethrow;
    }
  }

  // 진행중인 목록 가져옴
  Future<List<Map<String, dynamic>>> fetchAcceptList(
    String languageCode,
  ) async {
    try {
      final List<dynamic> data = await _supabase
          .from('missions')
          .select('''
          id,
          creator_id,
          content_library:content($languageCode),
          status,
          deadline,
          content_type
        ''')
          .eq('manito_id', _supabase.auth.currentUser!.id)
          .eq('status', 'progressing');

      // content 추출
      List<Map<String, dynamic>> transformedData = [];
      for (var mission in data) {
        Map<String, dynamic> newMission = Map.from(mission);
        if (newMission['content_library'] is Map<String, dynamic>) {
          Map<String, dynamic> contentMap = newMission['content_library'];
          if (contentMap.isNotEmpty) {
            newMission['content'] = contentMap.values.first;
          } else {
            newMission['content'] = null;
          }
        }
        transformedData.add(newMission);
      }
      return transformedData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ManitoService.fetchAcceptList Error: $e');
      rethrow;
    }
  }

  // 상대방이 추측중인 목록 가져옴
  Future<List<Map<String, dynamic>>> fetchGuessList() async {
    try {
      final List<dynamic> data = await _supabase
          .from('missions')
          .select('id, creator_id')
          .eq('manito_id', _supabase.auth.currentUser!.id)
          .eq('status', 'guessing');

      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ManitoService.fetchGuessList Error: $e');
      rethrow;
    }
  }
}

class ManitoProposeService {
  final SupabaseClient _supabase;
  ManitoProposeService(this._supabase);

  Future<ManitoPropose> getManitoPropose(
    String languageCode,
    ManitoPropose propose,
  ) async {
    try {
      final Map<String, dynamic> data =
          await _supabase
              .from('mission_propose')
              .select('''
              mission_id,
              random_contents,
              missions:mission_id(accept_deadline, content_type, deadline)
              ''')
              .eq('id', propose.id)
              .single();
      // text id 문자열 리스트
      final List<String> textIdList =
          (data["random_contents"] as List).map((e) => e.toString()).toList();
      // 언어 설정에 맞게 미션 내용 가져오기
      final contents = await _supabase.rpc(
        "fetch_mission_contents_from_ids",
        params: {'id_array': textIdList, "locale_code": languageCode},
      );
      // 가져온 데이터를 Map으로 변경
      List<ManitoContent> contentList = [];
      if (data["random_contents"].length == contents.length) {
        for (int i = 0; i < contents.length; i++) {
          final String textId = data["random_contents"][i].toString();
          final String content = contents[i]["content_text"].toString();
          contentList.add(ManitoContent(id: textId, content: content));
        }
      }
      final missionsData = data['missions'] as Map<String, dynamic>;
      return propose.copyWith(
        missionId: data['mission_id'] as String,
        randomContents: contentList,
        contentType: missionsData['content_type'] as String,
        deadline: DateTime.parse(missionsData['deadline'] as String),
      );
    } catch (e) {
      debugPrint('ManitoProposeService.getManitoPropose Error: $e');
      rethrow;
    }
  }

  Future<void> acceptManitoPropose(String missionId, String contentId) async {
    try {
      await _supabase.rpc(
        'accept_mission',
        params: {
          'p_id': missionId,
          'p_manito_id': _supabase.auth.currentUser!.id,
          'p_content': contentId,
        },
      );
    } catch (e) {
      debugPrint('ManitoProposeService.acceptManitoPropose Error: $e');
    }
  }
}

class ManitoPostService {
  final SupabaseClient _supabase;
  final ImageService _imageService;
  ManitoPostService(this._supabase, this._imageService);

  /// 작성해둔 게시물이 있으면 가져옴
  Future<ManitoPost> getManitoPost(String missionId) async {
    try {
      final data =
          await _supabase
              .from('missions')
              .select('description, image_url_list')
              .eq('id', missionId)
              .eq('manito_id', _supabase.auth.currentUser!.id)
              .single();
      return ManitoPost.fromJson(data);
    } catch (e) {
      debugPrint('ManitoPostService.getManitoPost Error: $e');
      rethrow;
    }
  }

  /// 게시물 저장
  Future<List<String>> saveManitoPost({
    required String missionId,
    required String description,
    required List<String> existingImageUrls,
    required List<AssetEntity> selectedImages,
  }) async {
    try {
      List<String> finalImageUrls = [];
      if (selectedImages.isNotEmpty) {
        final uploadedImageUrls = await _imageService.uploadImages(
          assets: selectedImages,
          bucket: 'post-image',
          prefix: '${missionId}_post',
        );
        finalImageUrls = uploadedImageUrls;
      } else if (existingImageUrls.isNotEmpty) {
        finalImageUrls = existingImageUrls;
      } else {
        finalImageUrls = [];
      }

      await _updatePostInDatabase(
        missionId: missionId,
        description: description,
        imageUrls: finalImageUrls,
      );
      return finalImageUrls;
    } catch (e) {
      debugPrint('ManitoPostService.saveManitoPost Error: $e');
      rethrow;
    }
  }

  /// 게시물 완료
  Future<void> completeManitoPost({
    required String missionId,
    required String creatorId,
  }) async {
    try {
      await _supabase.rpc(
        'mission_status_guess',
        params: {'p_mission_id': missionId, 'p_creator_id': creatorId},
      );
    } catch (e) {
      debugPrint('ManitoPostService.completeManitoPost: $e');
    }
  }

  // Private helper
  Future<void> _updatePostInDatabase({
    required String missionId,
    required String description,
    required List<String> imageUrls,
  }) async {
    final updateData = {
      'id': missionId,
      'manito_id': _supabase.auth.currentUser!.id,
      'description': description,
      'image_url_list': imageUrls,
    };

    await _supabase.from('missions').update(updateData).eq('id', missionId);
  }
}
