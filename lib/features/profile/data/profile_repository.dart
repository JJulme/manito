import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/util/app_logger.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch user profile
  Future<UserModel?> getProfile([String? userId]) async {
    final uid = userId ?? currentUserId;
    if (uid == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (response == null) {
        AppLogger.w('Profile not found in public.users for UID: $uid', tag: 'PROFILE');
        return null;
      }
      AppLogger.d('Profile loaded successfully for UID: $uid', tag: 'PROFILE');
      return UserModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('getProfile Error: $e', tag: 'PROFILE', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Update user profile & auto-reply presets
  Future<UserModel> updateProfile({
    String? name,
    String? statusMessage,
    String? profileImageUrl,
    String? manitoAutoReplyText,
    String? manitoAutoReplyImg,
    String? guessAutoReplyText,
    String? guessAutoReplyImg,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    try {
      final updates = <String, dynamic>{
        'manito_auto_reply_img': manitoAutoReplyImg,
        'guess_auto_reply_img': guessAutoReplyImg,
      };
      if (name != null) updates['name'] = name;
      if (statusMessage != null) updates['status_message'] = statusMessage;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;
      if (manitoAutoReplyText != null) updates['manito_auto_reply_text'] = manitoAutoReplyText;
      if (guessAutoReplyText != null) updates['guess_auto_reply_text'] = guessAutoReplyText;

      AppLogger.i('Updating profile for UID: $uid (manitoImg: $manitoAutoReplyImg, guessImg: $guessAutoReplyImg)', tag: 'PROFILE');
      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('user_id', uid)
          .select()
          .single();

      AppLogger.i('Profile updated successfully', tag: 'PROFILE');
      return UserModel.fromJson(response);
    } catch (e, s) {
      AppLogger.e('updateProfile Error: $e', tag: 'PROFILE', error: e, stackTrace: s);
      rethrow;
    }
  }
}
