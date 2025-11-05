import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase;
  ProfileService(this._supabase);

  // 사용자 프로필 정보 가져오기
  Future<UserProfile> getProfile() async {
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
      print(data);
      final userProfile = UserProfile.fromJson(data);
      // 캐시 비우기
      if (userProfile.profileImageUrl != null) {
        await CachedNetworkImage.evictFromCache(userProfile.profileImageUrl!);
      }

      return userProfile;
    } catch (e) {
      debugPrint('ProfileService.getProfile error: $e');
      rethrow;
    }
  }

  // 친구들 프로필 정보 가져오기
  Future<List<FriendProfile>> fetchFriendList() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('friends')
          .select('''
            friend_nickname, 
            profiles!friends_friend_id_fkey(
              id,
              nickname,
              status_message,
              profile_image_url
            )
          ''')
          .eq('user_id', userId)
          .order('profiles(nickname)', ascending: false);
      // 친구 리스트 생성
      List<FriendProfile> friendList =
          data.map((e) => FriendProfile.fromJson(e)).toList();

      // 이름순 정렬
      friendList.sort((a, b) => a.nickname.compareTo(b.nickname));

      // 친구들의 진행중인 미션 개수 업데이트
      if (friendList.isNotEmpty) {
        await _updateProgressMissions(friendList);
      }

      // 캐시 비우기
      for (var friend in friendList) {
        if (friend.profileImageUrl != null) {
          await CachedNetworkImage.evictFromCache(friend.profileImageUrl!);
        }
      }

      return friendList;
    } catch (e) {
      debugPrint('ProfileService.fetchFriendList error: $e');
      rethrow;
    }
  }

  // 친구 진행중인 미션 개수 업데이트
  Future<void> _updateProgressMissions(List<FriendProfile> friendList) async {
    try {
      // 친구 ID 목록 만들기
      final Map<String, FriendProfile> friendMap = {
        for (var friend in friendList) friend.id: friend,
      };
      final missionData = await _supabase
          .from('missions')
          .select('creator_id')
          .neq('status', 'complete')
          .inFilter('creator_id', friendMap.keys.toList());
      //  미션 카운트
      Map<String, int> creatorIdCounts = {};
      for (var item in missionData) {
        final String creatorId = item['creator_id'];
        creatorIdCounts[creatorId] = (creatorIdCounts[creatorId] ?? 0) + 1;
      }

      // 친구 객체에 미션 개수 업데이트
      creatorIdCounts.forEach((creatorId, count) {
        final friend = friendMap[creatorId];
        if (friend != null) {
          friend.progressMissions = count;
        }
      });
    } catch (e) {
      debugPrint('ProfileService._updateProgressMissions error: $e');
    }
  }
}

class ProfileEditService {
  final SupabaseClient _supabase;
  ProfileEditService(this._supabase);

  // 프로필 정보 수정
  Future<void> updateProfile({
    required String nickname,
    required String statusMessage,
    required String autoReply,
    required File? selectedImage,
    required String profileImageUrl,
  }) async {
    try {
      final profileTable = _supabase.from('profiles');
      final profileImageBucket = _supabase.storage.from('profile-image');
      String baseUrl =
          '${dotenv.env['SUPABASE_URL']!}/storage/v1/object/public/';
      final updateData = {
        'nickname': nickname,
        'status_message': statusMessage,
        'auto_reply': autoReply,
      };
      // 저장 이미지 이름 설정
      final String fileName = '${_supabase.auth.currentUser!.id}.jpg';

      // 선택한 이미지가 있을 경우
      if (selectedImage != null) {
        File fileToUpload = await compressImageFileUnified(selectedImage);
        final String fullPath = await profileImageBucket.upload(
          fileName,
          fileToUpload,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
        final String timestamp =
            DateTime.now().millisecondsSinceEpoch.toString();
        updateData['profile_image_url'] = '$baseUrl$fullPath?t=$timestamp';
      }
      // 기존 이미지도 없고 새 이미지도 없는 경우 → 삭제
      else if (selectedImage == null && profileImageUrl.isEmpty) {
        await profileImageBucket.remove([fileName]);
        updateData['profile_image_url'] = '';
      }
      await profileTable
          .update(updateData)
          .eq('id', _supabase.auth.currentUser!.id);
    } on StorageException catch (e) {
      debugPrint(
        'ProfileImageService.updateProfile StorageException Error: $e',
      );
      rethrow;
    } catch (e) {
      debugPrint('ProfileImageService.updateProfile Error: $e');
      rethrow;
    }
  }

  // 이미지 크기 변환
  Future<File> compressImageFileUnified(
    File originalFile, {
    int minWidth = 640,
    int quality = 70,
  }) async {
    final extension = path.extension(originalFile.path).toLowerCase();
    Uint8List? compressedData;
    CompressFormat? format;
    String targetExtension = extension;

    if (extension == '.heic' || extension == '.heif') {
      format = CompressFormat.jpeg;
      targetExtension = '.jpeg';
      final Uint8List imageData = await originalFile.readAsBytes();
      compressedData = await FlutterImageCompress.compressWithList(
        imageData,
        format: format,
        minWidth: minWidth,
        quality: quality,
      );
    } else if (extension == '.jpg' || extension == '.jpeg') {
      format = CompressFormat.jpeg;
      compressedData = await FlutterImageCompress.compressWithList(
        await originalFile.readAsBytes(),
        format: format,
        minWidth: minWidth,
        quality: quality,
      );
    } else if (extension == '.png') {
      format = CompressFormat.png;
      compressedData = await FlutterImageCompress.compressWithList(
        await originalFile.readAsBytes(),
        format: format,
        minWidth: minWidth,
        quality: 100, // PNG는 무손실
      );
    } else {
      debugPrint('지원하지 않는 이미지 형식: $extension');
      return originalFile; // 또는 null
    }

    final String tempDir = (await getTemporaryDirectory()).path;
    final String compressedPath =
        '$tempDir/${DateTime.now().millisecondsSinceEpoch}$targetExtension';
    final File compressedFile = File(compressedPath);
    await compressedFile.writeAsBytes(compressedData);
    return compressedFile;
  }

  Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      return File(xFile.path);
    }
    return null;
  }
}
