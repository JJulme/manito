import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manito/models/post.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 친구 화면 컨트롤러
class FriendsController extends GetxController {
  final _supabase = Supabase.instance.client;
  var userProfile = Rx<UserProfile?>(null); // 사용자 프로필 정보
  // var friendList = <UserProfile>[].obs; // 친구 목록
  var friendList = <FriendProfile>[].obs; // 친구 목록
  var isLoading = false.obs; // 친구 화면 로딩

  // var friendProfile = Rx<UserProfile?>(null); // 검색된 사용자

  // @override
  // void onInit() async {
  //   super.onInit();
  //   isLoading.value = true;
  //   await getProfile(); // 내 프로필 정보 가져오기
  //   await fetchFriendList(); // 친구 목록 가져오기
  //   isLoading.value = false;
  // }

  /// 프로필 가져오기
  Future<void> getProfile() async {
    // isLoading.value = true;
    try {
      final data =
          await _supabase
              .from('profiles')
              .select('id, email, nickname, status_message, profile_image_url')
              .eq('id', _supabase.auth.currentUser!.id)
              .single();
      userProfile.value = UserProfile.fromJson(data);
      // 최신 프로필 이미지를 가져오기 위해서 캐쉬 비우기
      await CachedNetworkImage.evictFromCache(
        userProfile.value!.profileImageUrl!,
      );
    } on PostgrestException catch (e) {
      debugPrint('getProfile PostgrestException Error: $e');
    } catch (e) {
      debugPrint('getProfile Error: $e');
    } finally {
      // isLoading.value = false;
    }
  }

  // 친구 목록 화면
  /// 친구 리스트 가져오기
  Future<void> fetchFriendList() async {
    // isLoading.value = true;
    try {
      // 친구 목록을 이름순으로 가져옴
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
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('profiles(nickname)', ascending: false);

      // 유저 정보 모델 변환
      friendList.value = data.map((e) => FriendProfile.fromJson(e)).toList();

      // 친구의 미션 현황 만들기
      // 친구가 있을 경우
      if (friendList.isNotEmpty) {
        // 친구 id 목록 만들기
        final Map<String, FriendProfile> friendMap = {
          for (var friend in friendList) friend.id: friend,
        };
        // 친구들의 진행중인 미션 가져오기
        final missionData = await _supabase
            .from('missions')
            .select('creator_id')
            .neq('status', '완료')
            .inFilter('creator_id', friendMap.keys.map((id) => id).toList());
        // 친구들의 진행중인 미션 카운트
        Map<String, int> creatorIdCounts = {};
        for (var item in missionData) {
          final String creatorId = item['creator_id'];
          creatorIdCounts[creatorId] = (creatorIdCounts[creatorId] ?? 0) + 1;
        }
        // 친구가 진행중인 미션 개수 업데이트
        creatorIdCounts.forEach((creatorId, count) {
          final friend = friendMap[creatorId];
          if (friend != null) {
            friend.progressMissions = count;
          }
        });
      }

      // 캐시 비우기
      for (var friend in friendList) {
        await CachedNetworkImage.evictFromCache(friend.profileImageUrl!);
      }
    } catch (e) {
      debugPrint('fetchFriendsList Error: $e');
    } finally {
      // isLoading.value = false;
    }
  }

  /// ID 넣어서 친구목록에서 친구 정보 가져오기 - 한명
  searchFriendProfile(String friendId) {
    try {
      // 내 id 이면 내 정보 넘겨줌
      if (userProfile.value!.id == friendId) {
        return userProfile.value;
      }
      // 내 id 아니면 친구 목록에서 가져옴
      else {
        FriendProfile? friendProfile = friendList.firstWhere(
          (friend) => friend.id == friendId,
          orElse:
              () => FriendProfile(
                id: '',
                nickname: '(알수없음)',
                profileImageUrl: '',
              ),
        );
        return friendProfile;
      }
    } catch (e) {
      debugPrint('searchFriendProfile Error: $e');
    }
    return null;
  }

  /// ID 넣어서 친구목록에서 친구 정보 가져오기 - 여러명
  List<FriendProfile> searchFriendProfiles(List<dynamic> ids) {
    List<FriendProfile> friendProfiles = [];
    try {
      for (String id in ids) {
        FriendProfile friendProfile = friendList.firstWhere(
          (friend) => friend.id == id,
        );
        friendProfiles.add(friendProfile);
      }
      return friendProfiles;
    } catch (e) {
      debugPrint('searchFriendProfiles Error: $e');
    }
    return friendProfiles;
  }
}

/// 친구 검색 컨트롤러
class FriendSearchController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs; // 검색 화면 로딩
  var searchProfile = Rx<UserProfile?>(null); // 검색된 사용자
  final TextEditingController emailController = TextEditingController();

  @override
  void onInit() async {
    super.onInit();
    searchProfile.value = null;
  }

  // 친구 검색 화면
  /// 이메일 검색 - 검색 DB 함수 만들어야 함
  Future<void> searchEmail() async {
    isLoading.value = true;
    try {
      var result =
          await _supabase
              .from('profiles')
              .select()
              .eq('email', emailController.text)
              .single();
      searchProfile.value = UserProfile.fromJson(result);
    } catch (e) {
      searchProfile.value = null;
      customSnackbar(title: '알림', message: '검색 결과가 없습니다.');
      debugPrint('searchEmail Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 친구 신청 보내기
  Future<String> sendFriendRequest() async {
    final String userId = _supabase.auth.currentUser!.id;
    try {
      final String result = await _supabase.rpc(
        'send_friend_request',
        params: {'sender_id': userId, 'receiver_id': searchProfile.value!.id},
      );
      return result;
    } catch (e) {
      debugPrint('sendFriendRequest Error: $e');
      return 'Error: $e';
    }
  }
}

/// 친구 요청 목록 컨트롤러
class FriendRequestController extends GetxController {
  final _supabase = Supabase.instance.client;
  var requestUserList = <UserProfile>[].obs; // 친구 요청 목록
  var requestLoading = false.obs; // 친구 요청 화면 로딩

  @override
  void onInit() async {
    super.onInit();
    fetchFriendRequest();
  }

  /// 친구 요청 목록 가져오기
  void fetchFriendRequest() async {
    requestLoading.value = true;
    final String userId = _supabase.auth.currentUser!.id;
    try {
      // 친구 신청 목록 가져오기
      final data = await _supabase
          .from('friend_requests')
          .select('''
            profiles!friend_requests_sender_id_fkey(id, email, nickname, status_message, profile_image_url)''')
          .eq('receiver_id', userId)
          .order('created_at');
      requestUserList.value =
          data.map((e) => UserProfile.fromJson(e['profiles'])).toList();
    } catch (e) {
      debugPrint('fetchFriendRequest Error: $e');
    } finally {
      requestLoading.value = false;
    }
  }

  /// 친구 수락
  Future<String> acceptFriendRequest(String senderId) async {
    final String userId = _supabase.auth.currentUser!.id;
    try {
      // 수락
      await _supabase.rpc(
        'accept_friend_request',
        params: {'req_sender_id': senderId, 'req_receiver_id': userId},
      );
      fetchFriendRequest();
      return 'request_accept';
    } catch (e) {
      debugPrint('acceptFriendRequest Error: $e');
      return 'request_accept_error';
    }
  }

  /// 친구 거절
  Future<String> rejectFriendRequest(String senderId) async {
    final String userId = _supabase.auth.currentUser!.id;
    try {
      // 거절
      await _supabase.rpc(
        'reject_friend_request',
        params: {'req_sender_id': senderId, 'req_receiver_id': userId},
      );
      fetchFriendRequest();
      return 'request_reject';
    } catch (e) {
      debugPrint('acceptFriendRequest Error: $e');
      return 'request_reject_error';
    }
  }
}

/// 차단 목록 컨트롤러
class BlacklistController extends GetxController {
  final _supabase = Supabase.instance.client;
  var blackList = <UserProfile>[].obs; // 차단된 사용자 목록
  var blacklistLoading = false.obs; // 차단 목록 화면 로딩

  @override
  void onInit() async {
    super.onInit();
    fetchBlacklist();
  }

  /// 차단 목록 가져오기
  void fetchBlacklist() async {
    blacklistLoading.value = true;
    final String userId = _supabase.auth.currentUser!.id;
    try {
      // 친구 신청 목록 가져오기
      final data = await _supabase
          .from('blacklist')
          .select('''
            profiles!blacklist_black_user_id_fkey(id, email, nickname, status_message, profile_image_url)''')
          .eq('user_id', userId)
          .order('created_at');
      blackList.value =
          data.map((e) => UserProfile.fromJson(e['profiles'])).toList();
    } catch (e) {
      debugPrint('fetchBlacklist Error: $e');
    } finally {
      blacklistLoading.value = false;
    }
  }

  /// 차단 해제
  Future<String> unblackUser(String blackUserId) async {
    final String userId = _supabase.auth.currentUser!.id;
    try {
      await _supabase.from('blacklist').delete().match({
        'user_id': userId,
        'black_user_id': blackUserId,
      });
      return 'unblack_success';
    } catch (e) {
      debugPrint('unblackUser Error: $e');
      return 'unblack_error';
    }
  }
}

/// 프로필 수정 컨트롤러
class ModifyController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs; // 친구 화면 로딩
  // 프로필 이미지 변수들
  var selectedImage = Rx<File?>(null); // 갤러리에서 가져온 이미지
  var profileImageUrl = ''.obs; // 이미지 삭제하는 경우의 변수
  // 텍스트 변수들
  final TextEditingController nameController = TextEditingController();
  final TextEditingController statusController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    profileImageUrl.value = Get.arguments[0];
    nameController.text = Get.arguments[1];
    statusController.text = Get.arguments[2];
  }

  /// 프로필 정보 수정
  Future<String> updateProfile() async {
    isLoading.value = true;
    try {
      final profileTable = _supabase.from('profiles');
      final profileImageBucket = _supabase.storage.from('profile-image');
      String baseUrl =
          '${dotenv.env['SUPABASE_URL']!}/storage/v1/object/public/';
      final updateData = {
        'nickname': nameController.text.trim(),
        'status_message': statusController.text,
      };

      // 저장 이미지 이름 설정
      final String fileName = '${_supabase.auth.currentUser!.id}.jpg';

      // 선택한 이미지가 있을 경우
      if (selectedImage.value != null) {
        File? fileToUpload = await compressImageFileUnified(
          selectedImage.value!,
        );
        final String fullPath = await profileImageBucket.upload(
          fileName,
          fileToUpload,
          fileOptions: FileOptions(cacheControl: '3600', upsert: true),
        );
        // 캐쉬 무효화를 위해서 쿼리파라미터(타임스탬프) 추가
        final String timestamp =
            DateTime.now().millisecondsSinceEpoch.toString();
        updateData['profile_image_url'] = '$baseUrl$fullPath?t=$timestamp';
      }
      // 프로필 이미지 설정 안하는 경우
      else if (selectedImage.value == null && profileImageUrl.value.isEmpty) {
        await profileImageBucket.remove([fileName]);
        updateData['profile_image_url'] = '';
      }

      await profileTable
          .update(updateData)
          .eq('id', _supabase.auth.currentUser!.id);
      Get.back(result: true);
      return '프로필 수정 성공';
    } on StorageException catch (e) {
      debugPrint('updateProfile StorageException Error: $e');
      return '저장 오류: $e';
    } catch (e) {
      debugPrint('updateProfile Error: $e');
      return '알 수 없는 오류: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 1개의 이미지 선택
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      selectedImage.value = File(xFile.path);
      profileImageUrl.value = '';
    }
  }

  // 이미지 삭제
  void deleteImage() {
    profileImageUrl.value = '';
    selectedImage.value = null;
  }

  // 이미지 크기 변환
  Future<File> compressImageFileUnified(
    File originalFile, {
    int minWidth = 640,
    int quality = 70,
  }) async {
    final String extension = path.extension(originalFile.path).toLowerCase();

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
}

/// 친구 상세화면 컨트롤러
class FriendsDetailCrontroller extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var manitoPostCount = 0.obs;
  var creatorPostCount = 0.obs;
  late FriendProfile friendProfile;
  var postList = <Post>[].obs; // 게시물 목록

  @override
  void onInit() {
    super.onInit();
    friendProfile = Get.arguments;
    fetchPosts();
  }

  /// 친구 차단
  Future<void> blockFriend() async {
    String userId = _supabase.auth.currentUser!.id;
    String friendId = friendProfile.id;
    try {
      await _supabase.rpc(
        'block_friend',
        params: {'user_id': userId, 'friend_id': friendId},
      );
      Get.back();
    } catch (e) {
      customSnackbar(title: '오류', message: '$e');
      debugPrint('blockFriend Error: $e');
    }
  }

  /// 친구와의 게시물만 가져옴
  Future<void> fetchPosts() async {
    isLoading.value = true;
    String userId = _supabase.auth.currentUser!.id;
    try {
      final originData = await _supabase
          .from('missions')
          .select(
            'id, manito_id, creator_id, deadline_type, content, complete_at',
          )
          .or(
            'manito_id.eq.${friendProfile.id},creator_id.eq.${friendProfile.id}',
          )
          .order('complete_at', ascending: true);
      final manitoPost =
          originData
              .where((post) => post['manito_id'] == friendProfile.id)
              .toList();
      final creatorPost =
          originData
              .where((post) => post['creator_id'] == friendProfile.id)
              .toList();
      final relatedPost =
          originData
              .where(
                (post) =>
                    post['manito_id'] == userId || post['creator_id'] == userId,
              )
              .toList();
      manitoPostCount.value = manitoPost.length;
      creatorPostCount.value = creatorPost.length;
      postList.value = relatedPost.map((post) => Post.fromJson(post)).toList();
    } catch (e) {
      debugPrint('fetchPosts Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

/// 친구 이름 설정
class FriendsModifyController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var isUpdate = false.obs;
  late String friendId;
  late String nickname;
  late String? friendNickname;
  final TextEditingController friendNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    friendId = Get.arguments;
    getFriendNickname();
  }

  /// 친구의 이름과 내가 설정한 이름 가져오기
  void getFriendNickname() async {
    isLoading.value = true;
    try {
      final data =
          await _supabase
              .from('friends')
              .select('''
              friend_nickname, 
              profiles!friends_friend_id_fkey(
              nickname
              )''')
              .eq('friend_id', friendId)
              .eq('user_id', _supabase.auth.currentUser!.id)
              .single();

      // 원래 이름
      nickname = data['profiles']['nickname'];
      // 설정된 이름
      friendNickname = data['friend_nickname'] ?? '';
      friendNameController.text = friendNickname!;
    } catch (e) {
      debugPrint('getFriendNickname Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 친구 이름 변경
  Future<String> updateFriendName() async {
    isUpdate.value = true;
    try {
      await _supabase
          .from('friends')
          .update({'friend_nickname': friendNameController.text.trim()})
          .eq('friend_id', friendId)
          .eq('user_id', _supabase.auth.currentUser!.id);

      Get.back(result: true);
      return '이름 수정 성공';
    } catch (e) {
      debugPrint('updateFriendName Error: $e');
      return '저장 오류: $e';
    } finally {
      isUpdate.value = false;
    }
  }
}
