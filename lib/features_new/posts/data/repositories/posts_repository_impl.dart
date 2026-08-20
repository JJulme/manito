import 'package:flutter/material.dart';
import 'package:manito/features_new/posts/data/models/post_model.dart';
import 'package:manito/features_new/posts/domain/entities/post_entity.dart';
import 'package:manito/features_new/posts/domain/repositories/posts_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostsRepositoryImpl implements PostsRepository {
  final SupabaseClient _supabase;
  PostsRepositoryImpl(this._supabase);

  // 게시물 리스트 가져오기
  @override
  Future<List<PostEntity>> getPosts(String languageCode) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('missions')
          .select('''id, 
            manito_id, 
            creator_id, 
            content_type, 
            content_library:content($languageCode), 
            complete_at
            ''')
          .or('creator_id.eq.$userId, manito_id.eq.$userId')
          .not('guess', 'is', null)
          .order('complete_at', ascending: false);

      // content 빼오기
      List<Map<String, dynamic>> transformedData = [];
      for (var mission in data) {
        Map<String, dynamic> newMission = Map.from(mission);
        if (newMission['content_library'] is Map<String, dynamic>) {
          Map<String, dynamic> contentMap = newMission['content_library'];
          newMission['content'] = contentMap.values.first;
        }
        transformedData.add(newMission);
      }

      return transformedData.map((post) => PostModel.fromJson(post)).toList();
    } catch (e) {
      debugPrint('PostsRepositoryImpl.getPosts Error: $e');
      rethrow;
    }
  }

  // 단일 게시물 가져오기
  @override
  Future<PostEntity> getPost(String postId) async {
    try {
      final data = await _supabase
          .from('missions')
          .select('description, image_url_list, guess')
          .eq('id', postId)
          .single();

      return PostModel.fromJson(data);
    } catch (e) {
      debugPrint('PostsRepositoryImpl.getPost Error: $e');
      rethrow;
    }
  }

  // 댓글 목록 가져오기
  @override
  Future<List<CommentEntity>> getComments(String missionId) async {
    try {
      final data = await _supabase
          .from('comments')
          .select()
          .eq('mission_id', missionId)
          .order('created_at', ascending: false);
      return data.map((comment) => CommentModel.fromJson(comment)).toList();
    } catch (e) {
      debugPrint('PostsRepositoryImpl.getComments Error: $e');
      rethrow;
    }
  }

  // 댓글 달기
  @override
  Future<void> addComment(String missionId, String comment) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('comments').insert({
        "mission_id": missionId,
        "user_id": userId,
        "comment": comment,
      });
    } catch (e) {
      debugPrint('PostsRepositoryImpl.addComment Error: $e');
      rethrow;
    }
  }
}
