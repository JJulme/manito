import 'package:flutter/material.dart';
import 'package:manito/features_new/report/domain/repositories/report_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRepositoryImpl implements ReportRepository {
  final SupabaseClient _supabase;

  ReportRepositoryImpl(this._supabase);

  @override
  Future<String> reportUser(String reportType) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      Map<String, dynamic> data = {
        "reporter_user_id": userId,
        "reported_user_id": userId,
        "report_type": reportType,
      };
      await _supabase.from('reports_user').insert(data);
      return "success";
    } on PostgrestException catch (e) {
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

  @override
  Future<String> reportPost(String postId, String reportType) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      Map<String, dynamic> data = {
        "reporter_user_id": userId,
        "reported_user_id": userId,
        "post_id": postId,
        "report_type": reportType,
      };
      await _supabase.from('reports_post').insert(data);
      return "success";
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return "duplicate";
      }
      debugPrint('reportPost PostgrestException: $e');
      return "fail";
    } catch (e) {
      debugPrint('reportPost Error: $e');
      return "fail";
    }
  }
}
