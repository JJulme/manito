import 'package:flutter/material.dart';
import 'package:manito/core/image/image_service.dart';
import 'package:manito/features_new/manito/domain/entities/manito_entity.dart';
import 'package:manito/features_new/manito/domain/repositories/manito_repository.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManitoRepositoryImpl implements ManitoRepository {
  final SupabaseClient _supabase;
  final ImageService _imageService;

  ManitoRepositoryImpl(this._supabase)
      : _imageService = ImageService(_supabase);

  @override
  Future<List<ManitoProposeEntity>> fetchProposeList() async {
    try {
      final data = await _supabase
          .from('mission_propose')
          .select('id, missions:mission_id(creator_id, accept_deadline)')
          .eq('friend_id', _supabase.auth.currentUser!.id);

      return data.map((e) => ManitoProposeEntity.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ManitoRepositoryImpl.fetchProposeList Error: $e');
      rethrow;
    }
  }

  @override
  Future<ManitoProposeEntity> fetchProposeDetail(
    String proposeId,
    String languageCode,
  ) async {
    try {
      final Map<String, dynamic> data = await _supabase
          .from('mission_propose')
          .select('''
          mission_id,
          random_contents,
          missions:mission_id(accept_deadline, content_type, deadline)
          ''')
          .eq('id', proposeId)
          .single();

      final List<String> textIdList =
          (data["random_contents"] as List).map((e) => e.toString()).toList();

      final contents = await _supabase.rpc(
        "fetch_mission_contents_from_ids",
        params: {'id_array': textIdList, "locale_code": languageCode},
      );

      List<ManitoContentEntity> contentList = [];
      if (data["random_contents"].length == contents.length) {
        for (int i = 0; i < contents.length; i++) {
          final String textId = data["random_contents"][i].toString();
          final String content = contents[i]["content_text"].toString();
          contentList.add(ManitoContentEntity(id: textId, content: content));
        }
      }
      final missionsData = data['missions'] as Map<String, dynamic>;

      return ManitoProposeEntity(
        id: proposeId,
        missionId: data['mission_id'] as String,
        creatorId: '', // Will be updated by caller if needed
        acceptDeadline: DateTime.parse(missionsData['accept_deadline'] as String),
        randomContents: contentList,
        contentType: missionsData['content_type'] as String,
        deadline: DateTime.parse(missionsData['deadline'] as String),
      );
    } catch (e) {
      debugPrint('ManitoRepositoryImpl.fetchProposeDetail Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> acceptPropose(String missionId, String selectedContentId) async {
    try {
      await _supabase.rpc(
        'accept_mission',
        params: {
          'p_id': missionId,
          'p_manito_id': _supabase.auth.currentUser!.id,
          'p_content': selectedContentId,
        },
      );
    } catch (e) {
      debugPrint('ManitoRepositoryImpl.acceptPropose Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAcceptData([String languageCode = 'en']) async {
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
      debugPrint('ManitoRepositoryImpl.fetchAcceptData Error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGuessData() async {
    try {
      final List<dynamic> data = await _supabase
          .from('missions')
          .select('id, creator_id')
          .eq('manito_id', _supabase.auth.currentUser!.id)
          .eq('status', 'guessing');

      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ManitoRepositoryImpl.fetchGuessData Error: $e');
      rethrow;
    }
  }

  @override
  Future<ManitoPostEntity?> getManitoPost(String acceptId) async {
    try {
      final data = await _supabase
          .from('missions')
          .select('description, image_url_list')
          .eq('id', acceptId)
          .eq('manito_id', _supabase.auth.currentUser!.id)
          .single();
      return ManitoPostEntity.fromJson(data);
    } catch (e) {
      debugPrint('ManitoRepositoryImpl.getManitoPost Error: $e');
      return null;
    }
  }

  @override
  Future<List<String>> uploadImages(List<AssetEntity> assets) async {
    if (assets.isEmpty) return [];
    return _imageService.uploadImages(
      assets: assets,
      bucket: 'post-image',
      prefix: 'post',
    );
  }

  @override
  Future<void> saveManitoPost(
    String acceptId,
    String description,
    List<AssetEntity> assets,
  ) async {
    try {
      List<String> imageUrls = [];
      if (assets.isNotEmpty) {
        imageUrls = await _imageService.uploadImages(
          assets: assets,
          bucket: 'post-image',
          prefix: '${acceptId}_post',
        );
      }
      await _supabase.from('missions').update({
        'description': description,
        'image_url_list': imageUrls,
      }).eq('id', acceptId);
    } catch (e) {
      debugPrint('ManitoRepositoryImpl.saveManitoPost Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeManitoPost(
    String acceptId,
    String description,
    List<AssetEntity> assets,
  ) async {
    try {
      await saveManitoPost(acceptId, description, assets);
    } catch (e) {
      debugPrint('ManitoRepositoryImpl.completeManitoPost Error: $e');
      rethrow;
    }
  }
}
