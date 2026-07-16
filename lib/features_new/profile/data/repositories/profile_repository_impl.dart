import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:manito/core/utils/image_formatter.dart';
import 'package:manito/core/utils/logger.dart';
import 'package:manito/features_new/profile/data/models/my_profile_model.dart';
import 'package:manito/features_new/profile/data/models/user_model.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/features_new/profile/domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _supabase;
  ProfileRepositoryImpl(this._supabase);

  // 사용자 프로필 가져오기
  @override
  Future<MyProfileEntity> getMyProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data =
          await _supabase
              .from('profiles')
              .select(
                'id, email, nickname, status_message, profile_image_url, auto_reply',
              )
              .eq('id', userId)
              .single();
      final myProfile = MyProfileModel.fromJson(data);
      return myProfile;
    } catch (e) {
      rethrow;
    }
  }

  // // 친구들 프로필 가져오기
  // @override
  // Future<List<FriendProfileEntity>> getFriends() async {
  //   try {
  //     final userId = _supabase.auth.currentUser!.id;
  //     // 1. Supabase에서 친구 기본 데이터 및 프로필 Join해서 가져오기
  //     final data = await _supabase
  //         .from('friends')
  //         .select('''
  //           friend_nickname,
  //           profiles!friends_friend_id_fkey(
  //             id,
  //             nickname,
  //             status_message,
  //             profile_image_url
  //           )
  //         ''')
  //         .eq('user_id', userId);
  //     if ((data as List).isEmpty) return [];

  //     final List<Map<String, dynamic>> friendsData =
  //         List<Map<String, dynamic>>.from(data);

  //     // 2. 친구들의 미션 개수 정보 가져오기 (데이터 로직 분리)
  //     final friendIds =
  //         friendsData.map((e) => e['profiles']['id'] as String).toList();
  //     final missionCounts = await _fetchMissionCounts(friendIds);

  //     // 3. Model을 거쳐 최종 Entity 리스트로 변환
  //     final List<FriendProfileEntity> friendList =
  //         friendsData.map((json) {
  //           final String friendId = json['profiles']['id'];
  //           final int count = missionCounts[friendId] ?? 0;

  //           // Model의 factory 생성자를 사용하여 Entity 생성
  //           return FriendProfileModel.fromJson(json, missionCount: count);
  //         }).toList();

  //     // 4. 비즈니스 로직: 이름순 정렬
  //     friendList.sort((a, b) => a.displayName.compareTo(b.displayName));

  //     // 5. 부수 효과: 이미지 캐시 비우기 (필요 시)
  //     _evictProfileImageCache(friendList);

  //     return friendList;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  // // 친구 미션 카운트 가져오기 - getFriends()
  // Future<Map<String, int>> _fetchMissionCounts(List<String> friendIds) async {
  //   if (friendIds.isEmpty) return {};
  //   final data = await _supabase
  //       .from('missions')
  //       .select('creator_id')
  //       .neq('status', 'complete')
  //       .inFilter('creator_id', friendIds);
  //   Map<String, int> counts = {};
  //   for (var item in data) {
  //     final String creatorId = item['creator_id'];
  //     counts[creatorId] = (counts[creatorId] ?? 0) + 1;
  //   }
  //   return counts;
  // }

  // // 캐시 관리 - getFriends()
  // void _evictProfileImageCache(List<FriendProfileEntity> friends) {
  //   for (var friend in friends) {
  //     if (friend.profileImageUrl != null &&
  //         friend.profileImageUrl!.isNotEmpty) {
  //       CachedNetworkImage.evictFromCache(friend.profileImageUrl!);
  //     }
  //   }
  // }

  // // 친구 별명 설정
  // @override
  // Future<void> updateFriendNickname(String friendId, String nickname) async {
  //   try {
  //     final userId = _supabase.auth.currentUser!.id;
  //     await _supabase
  //         .from('friends')
  //         .update({'friend_nickname': nickname})
  //         .eq('friend_id', friendId)
  //         .eq('user_id', userId);
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  @override
  Future<MyProfileEntity> updateMyProfile({
    required String nickname,
    required String statusMessage,
    required String autoReply,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final profileTable = _supabase.from('profiles');
      final storageBucket = _supabase.storage.from('profile-image');
      final updateData = {
        'nickname': nickname,
        'status_message': statusMessage,
        'auto_reply': autoReply,
      };
      final String fileName = '$userId.jpg';

      // 2. 이미지 처리 로직
      if (imageFile != null) {
        // (1) 새 이미지가 있는 경우 -> 업로드
        final File fileToUpload = await ImageFormatter.compressImage(imageFile);
        final String fullPath = await storageBucket.upload(
          fileName,
          fileToUpload,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        // 캐시 방지를 위해 타임스탬프 추가
        final String timestamp =
            DateTime.now().millisecondsSinceEpoch.toString();
        final String baseUrl =
            '${dotenv.env['SUPABASE_URL']}/storage/v1/object/public/';
        updateData['profile_image_url'] = '$baseUrl$fullPath?t=$timestamp';
      } else if (existingImageUrl == null || existingImageUrl.isEmpty) {
        // (2) 새 이미지도 없고 기존 이미지도 비워달라고 온 경우 -> 삭제
        try {
          await storageBucket.remove([fileName]);
        } catch (e) {
          // 이미 파일이 없는 경우 에러가 날 수 있으나 무시해도 됨
        }
        updateData['profile_image_url'] = '';
      }

      // 3. DB 업데이트 수행
      final data =
          await profileTable
              .update(updateData)
              .eq('id', userId)
              .select()
              .single();
      return MyProfileModel.fromJson(data);
    } catch (e) {
      Log.e('$e');
      rethrow;
    }
  }

  // 친구가 아닌 사용자 프로필 가져오기
  @override
  Future<UserEntity> getUserProfile(String unknownId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // 1. Supabase RPC 호출
      final List<dynamic> data = await _supabase.rpc(
        'get_user_profile_safe',
        params: {'p_my_id': userId, 'p_unknown_id': unknownId},
      );

      // 2. 결과가 없을 경우 '알 수 없는 사용자' 모델 반환
      if (data.isEmpty) {
        return UserModel.unknown(unknownId);
      }

      // 3. 모델 생성 (첫 번째 아이템 사용)
      final userModel = UserModel.fromJson(data[0]); // List<Map> 형식 처리

      // 4. 부수 효과: 캐시 비우기
      if (userModel.profileImageUrl != null &&
          userModel.profileImageUrl!.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(userModel.profileImageUrl!);
      }

      return userModel;
    } catch (e) {
      return UserModel.unknown(unknownId);
    }
  }
}
