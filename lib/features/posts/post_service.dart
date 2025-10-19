import 'package:flutter/material.dart';
import 'package:manito/features/posts/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostsService {
  final SupabaseClient _supabase;
  PostsService(this._supabase);

  // 게시물 리스트 가져오기
  Future<List<Post>> fetchPosts(String languageCode) async {
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

      return transformedData.map((post) => Post.fromJson(post)).toList();
    } catch (e) {
      debugPrint('PostService.fetchPosts Error: $e');
      rethrow;
    }
  }

  // 단일 게시물 가져오기
  Future<Post> getPost(String postId) async {
    try {
      final data =
          await _supabase
              .from('missions')
              .select('description, image_url_list, guess')
              .eq('id', postId)
              .single();

      return Post.fromJson(data);
    } catch (e) {
      debugPrint('PostService.getPost Error: $e');
      rethrow;
    }
  }

  // 댓글 목록 가져오기
  Future<List<Comment>> fetchComments(String missionId) async {
    try {
      final data = await _supabase
          .from('comments')
          .select()
          .eq('mission_id', missionId)
          .order('created_at', ascending: false);
      return data.map((comment) => Comment.fromJson(comment)).toList();
    } catch (e) {
      debugPrint('PostsService.fetchComments Error: $e');
      rethrow;
    }
  }

  // 댓글 달기
  Future<void> insertComment(
    String missionId,
    String userId,
    String comment,
  ) async {
    try {
      await _supabase.from('comments').insert({
        "mission_id": missionId,
        "user_id": userId,
        "comment": comment,
      });
    } catch (e) {
      debugPrint('PostsService.insertComment Error: $e');
      rethrow;
    }
  }
}
