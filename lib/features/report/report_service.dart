import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supabase;
  ReportService(this._supabase);

  // 유저 신고하기
  Future<String> reportUser(String reportType) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      Map<String, dynamic> data = {
        "reporter_user_id": _supabase.auth.currentUser!.id,
        "reported_user_id": userId,
        "report_type": reportType,
      };
      await _supabase.from('reports_user').insert(data);
      return "success";
    } on PostgrestException catch (e) {
      // 중복 예외
      if (e.code == '23505') {
        return "duplicate";
      }
      debugPrint('reportUser PostgrestException: $e');
      return "fail";
    } catch (e) {
      debugPrint('reportUser Error: $e');
      return "fail";
    }
  }

  // 게시물 신고하기
  Future<String> reportPost(String postId, String reportType) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      Map<String, dynamic> data = {
        "reporter_user_id": _supabase.auth.currentUser!.id,
        "reported_user_id": userId,
        "post_id": postId,
        "report_type": reportType,
      };
      await _supabase.from('reports_post').insert(data);
      return "success";
    } on PostgrestException catch (e) {
      // 중복 예외
      if (e.code == '23505') {
        return "duplicate";
      }
      debugPrint('reportUser PostgrestException: $e');
      return "fail";
    } catch (e) {
      debugPrint('reportPost Error: $e');
      return "fail";
    }
  }
}
