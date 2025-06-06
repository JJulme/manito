import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manito/models/auto_reply.dart';
import 'package:manito/models/mission.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 미션 제안/진행 목록
class ManitoController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var missionProposeList = <MissionProposeList>[].obs; // 수락가능 미션
  var missionAcceptList = <MissionAccept>[].obs; // 진행중 미션
  var missionGuessList = <MissionGuess>[].obs; // 추측중 미션

  @override
  void onInit() async {
    super.onInit();
    isLoading.value = true;
    await fetchMissionProposeList();
    await fetchMissionAcceptList();
    await fetchMissionGuessList();
    isLoading.value = false;
  }

  /// 나에게 온 미션 제의 목록 가져오는 함수
  Future<void> fetchMissionProposeList() async {
    // isLoading.value = true;
    try {
      final List<dynamic> data = await _supabase
          .from('mission_propose')
          .select('id, missions:mission_id(creator_id, accept_deadline)')
          .eq('friend_id', _supabase.auth.currentUser!.id);

      missionProposeList.value =
          data.map((e) => MissionProposeList.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchMissionProposeList Error: $e');
    } finally {
      // isLoading.value = false;
    }
  }

  // 내가 수락한 미션 목록 가져오기
  Future<void> fetchMissionAcceptList() async {
    try {
      final List<dynamic> data = await _supabase
          .from('missions')
          .select('''id, 
              creator_id, 
              content, 
              status, 
              deadline, 
              deadline_type
              ''')
          .eq('manito_id', _supabase.auth.currentUser!.id)
          .eq('status', '진행중');
      missionAcceptList.value =
          data.map((e) => MissionAccept.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchMissionAcceptList Error: $e');
    }
  }

  //
  Future<void> fetchMissionGuessList() async {
    try {
      final List<dynamic> data = await _supabase
          .from('missions')
          .select('''
              creator_id
              ''')
          .eq('manito_id', _supabase.auth.currentUser!.id)
          .eq('status', '추측중');
      missionGuessList.value =
          data.map((e) => MissionGuess.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchMissionGuessList Error: $e');
    } finally {
      // isLoading.value = false;
    }
  }
}

/// 미션 제안 화면 컨트롤러
class MissionProposeController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  late String missionProposeId;
  late var creatorProfile;
  var missionPropose = Rx<MissionPropose?>(null);
  Rx<String?> selectedContent = Rx<String?>(null);

  @override
  void onInit() async {
    super.onInit();
    missionProposeId = Get.arguments[0];
    creatorProfile = Get.arguments[1];
    await fetchMissionPropose();
  }

  /// 미션 제의 정보 가져옴
  Future<void> fetchMissionPropose() async {
    isLoading.value = true;
    try {
      final Map<String, dynamic> data =
          await _supabase
              .from('mission_propose')
              .select('''
              mission_id,
              random_contents,
              missions:mission_id(accept_deadline, deadline_type, deadline)
              ''')
              .eq('id', missionProposeId)
              .single();
      missionPropose.value = MissionPropose.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        Get.back(result: true); // 새로고침 명령
        customSnackbar(title: '늦었음', message: '존재하지 않는 제안입니다.');
      } else {
        debugPrint('fetchMissionPropose Postgrest Error: $e');
        customSnackbar(title: '오류', message: '알 수 없는 오류: $e');
      }
    } catch (e) {
      debugPrint('fetchMissionPropose Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 미션 선택지 추가
  Future<void> addRandomMissionContent() async {
    try {
      await _supabase.rpc(
        'add_random_mission_content',
        params: {
          'p_mission_propose_id': missionProposeId,
          'p_deadline': missionPropose.value!.deadlineType,
        },
      );
    } catch (e) {
      debugPrint('addRandomMissionContent Error: $e');
    }
  }

  /// 미션 선택 후 미션 수락
  Future<String> acceptMissionPropose(String content) async {
    try {
      await _supabase.rpc(
        'accept_mission',
        params: {
          'p_id': missionPropose.value!.missionId,
          'p_manito_id': _supabase.auth.currentUser!.id,
          'p_content': content,
        },
      );
      Get.back(result: true);
      return '미션을 수락 했습니다.';
    } on PostgrestException catch (e) {
      Get.back(result: true);
      if (e.code == 'P0001') {
        return '이미 수락된 미션입니다.';
      } else {
        return '이미 삭제된 미션입니다.';
      }
    } catch (e) {
      // 화면을 나가고 제안 새로고침 필요함
      Get.back(result: true);
      debugPrint('acceptMissionPropose Error: $e');
      return '이미 삭제된 미션입니다.';
    }
  }
}

/// 미션 게시물 작성 컨트롤러
class ManitoPostController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var updateLoading = false.obs;
  var isPosting = true.obs;
  // Get.arguments로 받아올 변수
  late MissionAccept missionAccept;
  late var creatorProfile;
  // 서버에서 가져오는 게시물 또는 자동응답
  var missionPost = Rx<MissionPost?>(null);
  final TextEditingController descController = TextEditingController();
  // 선택한 이미지
  var selectedImages = <AssetEntity>[].obs;
  var cachedImages = <ImageProvider<Object>>[].obs;
  var activeIndex = 0.obs;

  @override
  void onInit() async {
    super.onInit();
    missionAccept = Get.arguments[0];
    creatorProfile = Get.arguments[1];
    await getPost();
  }

  /// 작성해둔 게시물이 있으면 가져오고 없으면 자동응답 가져옴
  Future<void> getPost() async {
    isLoading.value = true;
    try {
      final post =
          await _supabase
              .from('missions')
              .select('description, image_url_list')
              .eq('id', missionAccept.id)
              .eq('manito_id', _supabase.auth.currentUser!.id)
              .single();

      missionPost.value = MissionPost.fromJson(post);
      descController.text = missionPost.value?.description ?? '';

      // 이미지 캐쉬로 저장
      for (String image in missionPost.value!.imageUrlList!) {
        cachedImages.add(CachedNetworkImageProvider(image));
      }
    } catch (e) {
      debugPrint('getPost Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 선택 이미지 리스트에서 삭제
  void deleteSelectedImage(int index) {
    selectedImages.removeAt(index);
    // 저장 상태 변경
    isPosting.value = false;
  }

  /// 저장된 이미지 리스트에서 삭제
  void deletePostImage(int index) {
    // 기존 서버에 저장된 리스트에서 삭제
    missionPost.value!.imageUrlList!.removeAt(index);
    // 현재 디바이스의 캐쉬 삭제
    cachedImages.removeAt(index);
    // 저장 상태 변경
    isPosting.value = false;
  }

  /// 게시물 저장
  Future<void> updatePost() async {
    updateLoading.value = true;
    try {
      final postTable = _supabase.from('missions');
      final postImageBucket = _supabase.storage.from('post-image');
      const String baseUrl =
          'https://rkfdbtdicxarrctsvmif.supabase.co/storage/v1/object/public/';
      final Map<String, dynamic> upsertData = {
        'id': missionAccept.id,
        'manito_id': _supabase.auth.currentUser!.id,
        'description': descController.text,
      };

      List<String> imagePathList = [];
      // 선택한 이미지가 있을 경우
      if (selectedImages.isNotEmpty) {
        for (AssetEntity assetImage in selectedImages) {
          // 파일 형식으로 변환
          var fileImage = await assetImage.originFile;
          if (fileImage == null) continue;

          // 이미지 크기변환
          File? fileToUpload = await compressImageFileUnified(fileImage);

          String fileName =
              '${missionAccept.id}_post_${DateTime.now().millisecondsSinceEpoch}.png';
          final String fullPath = await postImageBucket.upload(
            fileName,
            fileToUpload,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
          imagePathList.add(baseUrl + fullPath);
        }
        upsertData['image_url_list'] = imagePathList;
      }
      // 서버에 저장된 이미지를 수정한 경우
      else if (missionPost.value?.imageUrlList?.isNotEmpty == true) {
        upsertData['image_url_list'] = missionPost.value!.imageUrlList!;
      }
      // 아무 사진도 저장 안하는 경우
      else {
        upsertData['image_url_list'] = [];
      }

      // 게시물 저장
      await postTable.update(upsertData).eq('id', missionAccept.id);
      // 저장 상태 변경
      isPosting.value = true;
      // customSnackbar(title: '저장 성공', message: '미션종료 버튼을 누르면 친구에게 알림이 갑니다.');
    } catch (e) {
      customSnackbar(title: '오류', message: '$e');
      debugPrint('updatePost Error: $e');
    } finally {
      updateLoading.value = false;
    }
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

  /// 게시하기 - mission_manito(status 수정), missions(status 수정)
  Future<String> completePost() async {
    updateLoading.value = true;
    try {
      await _supabase.rpc(
        'mission_status_guess',
        params: {
          'p_mission_id': missionAccept.id,
          'p_creator_id': missionAccept.creatorId,
        },
      );
      Get.back(result: true);
      return '친구에게 게시물 전송을 완료 했습니다.';
    } catch (e) {
      debugPrint('completePost Error: $e');
      return '게시물 전송에 실패 했습니다.';
    } finally {
      updateLoading.value = false;
    }
  }
}

/// 자동 응답 수정 컨트롤러
class AutoReplyController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var updateLoading = false.obs;
  var autoReply = Rx<AutoReply?>(null);
  var selectedImage = Rx<File?>(null);
  final TextEditingController replyController = TextEditingController();

  @override
  void onInit() async {
    super.onInit();
    await getAutoReply();
  }

  /// 저장된 자동응답 문구, 사진 가져오기
  Future<void> getAutoReply() async {
    isLoading.value = true;
    final String userId = _supabase.auth.currentUser!.id;
    try {
      // final userId = await SecureStorage.getUserId();
      final data = await _supabase
          .from('auto_reply')
          .select('reply, reply_image_url')
          .eq('id', userId);
      autoReply.value = AutoReply.fromJson(data);
      replyController.text = autoReply.value!.reply;
    } catch (e) {
      debugPrint('getAutoReply Erorr: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 이미지 선택
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    // 갤러리에서 단일 이미지 선택
    final XFile? xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      selectedImage.value = File(xFile.path);
    }
  }

  /// 이미지 제거
  void deleteImage() {
    selectedImage.value = null;
    autoReply.value!.replyImageUrl = '';
  }

  /// 자동응답 서버 업로드
  Future<String> updateAutoReply(String text) async {
    updateLoading.value = true;
    final String userId = _supabase.auth.currentUser!.id;
    try {
      final autoReplyTable = _supabase.from('auto_reply');
      final autoReplyImageBucket = _supabase.storage.from('auto-reply-image');
      const String baseUrl =
          'https://rkfdbtdicxarrctsvmif.supabase.co/storage/v1/object/public/';
      final updateData = {'reply': text};

      // 선택한 이미지가 있을 경우
      if (selectedImage.value != null) {
        String fileName =
            '${userId}_reply_${DateTime.now().millisecondsSinceEpoch}.png';
        final String fullPath = await autoReplyImageBucket.upload(
          fileName,
          selectedImage.value!,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
        updateData['reply_image_url'] = baseUrl + fullPath;
      }
      // 이미지 설정을 안하는 경우
      else if (selectedImage.value == null &&
          autoReply.value!.replyImageUrl.isEmpty) {
        updateData['reply_image_url'] = '';
      }
      // 자동 응답 수정
      await autoReplyTable.upsert(updateData).eq('id', userId);

      Get.back(result: true);
      return '자동 응답 수정 성공';
    } on StorageException catch (e) {
      debugPrint('updateAutoReply StorageException Error: $e');
      return '저장 오류: $e';
    } catch (e) {
      debugPrint('updateAutoReply Error: $e');
      return '알 수 없는 오류: $e';
    } finally {
      updateLoading.value = false;
    }
  }
}
