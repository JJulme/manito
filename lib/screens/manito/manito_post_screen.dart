import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/manito_controller.dart';
import 'package:manito/controllers/post_controller.dart';
import 'package:manito/screens/album_screen.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/mission/timer.dart';
import 'package:manito/widgets/post/image_slider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class ManitoPostScreen extends StatefulWidget {
  const ManitoPostScreen({super.key});

  @override
  State<ManitoPostScreen> createState() => _ManitoPostScreenState();
}

class _ManitoPostScreenState extends State<ManitoPostScreen> {
  late final ManitoPostController _controller;
  late final PostController _postController;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ManitoPostController());
    _postController = Get.find<PostController>();
  }

  // 앨범에서 이미지 선택 함수
  void _selectImages() async {
    final List<AssetEntity>? result = await Get.to(() => AlbumScreen());
    if (result != null) {
      _controller.selectedImages.value = result;
      // 저장 상태 변경
      _controller.isPosting.value = false;
    }
  }

  // 친구에게 게시물 보내는 함수
  void _completePost() async {
    kDefaultDialog(
      '미션 완료',
      '미션을 종료하고 친구에게 알립니다.',
      onYesPressed: () async {
        String result = await _controller.completePost();
        await _postController.fetchPosts();
        customSnackbar(title: '알림', message: result);
      },
    );
  }

  // 게시물 저장 또는 완료 처리
  Future<void> _handlePostAction() async {
    // 작성 문구 짧을 때
    if (_controller.descController.text.length < 5) {
      customSnackbar(title: '정성부족', message: '5글자 이상 작성해 주세요.');
      return;
    }

    // 게시물 저장이 완료 되고 나서
    if (_controller.isPosting.value) {
      _completePost();
    }
    // 게시물 저장을 해야 할 때
    else {
      final bool result = await _controller.updatePost();
      if (!result) {
        final String snackTitle = context.tr(
          "manito_post_screen.error_snack_title",
        );
        final String snackMessage = context.tr(
          "manito_post_screen.error_snack_message",
        );
        customSnackbar(title: snackTitle, message: snackMessage);
      }
    }
  }

  // 본체
  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(width),
        body: _buildBody(width),
        // 저장, 전송 버튼
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      centerTitle: false,
      titleSpacing: screenWidth * 0.07,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Text('미션 기록하기'),
          SizedBox(width: screenWidth * 0.02),
          TimerWidget(
            targetDateTime: _controller.missionAccept.deadline,
            fontSize: screenWidth * 0.065,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: screenWidth * 0.02),
          child: IconButton(
            padding: EdgeInsets.all(0),
            icon: Icon(Icons.close_rounded, size: screenWidth * 0.07),
            onPressed: () => Get.back(result: false),
          ),
        ),
      ],
    );
  }

  // 바디
  Widget _buildBody(screenWidth) {
    return SafeArea(
      child: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _ImageSection(
                    controller: _controller,
                    onSelectImages: _selectImages,
                  ),
                  _buildDescriptionSection(screenWidth),
                ],
              ),
            ),
            if (_controller.updateLoading.value)
              ModalBarrier(
                dismissible: false,
                color: Colors.black.withAlpha((0.5 * 255).round()),
              ),
          ],
        );
      }),
    );
  }

  // 설명 입력 텍스트 필드
  Widget _buildDescriptionSection(screenWidth) {
    final String hintText =
        '[${_controller.creatorProfile.nickname}] 에게\n'
        '[${_controller.missionAccept.content}]\n'
        '미션을 어떻게 수행 했는지 작성 해주세요.';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.02,
        0,
        screenWidth * 0.02,
        screenWidth * 0.02,
      ),
      child: TextField(
        controller: _controller.descController,
        minLines: 3,
        maxLines: null,
        maxLength: 999,
        style: Get.textTheme.bodyMedium,
        onChanged: (_) => _controller.isPosting.value = false,
        decoration: InputDecoration(counterText: '', hintText: hintText),
      ),
    );
  }

  // 바텀 버튼
  Widget _buildBottomNavigationBar() {
    final double width = Get.width;

    return BottomAppBar(
      child: Container(
        margin: EdgeInsets.all(width * 0.03),
        child: Obx(
          () => _ActionButton(
            isLoading: _controller.updateLoading.value,
            isPosting: _controller.isPosting.value,
            onPressed:
                _controller.updateLoading.value ? null : _handlePostAction,
          ),
        ),
      ),
    );
  }
}

// 전체 이미지 섹션
class _ImageSection extends StatelessWidget {
  final ManitoPostController controller;
  final VoidCallback onSelectImages;

  const _ImageSection({required this.controller, required this.onSelectImages});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final RxList<ImageProvider<Object>>? cachedImages =
          controller.cachedImages;
      final selectedImages = controller.selectedImages;
      final double width = Get.width;

      // 선택된 이미지가 있는 경우
      if (selectedImages.isNotEmpty) {
        return _buildImageContent(width, selectedImages, isAssetEntity: true);
      }

      // 캐시된 이미지가 있는 경우
      if (cachedImages?.isNotEmpty == true) {
        return _buildImageContent(width, cachedImages!, isAssetEntity: false);
      }

      // 이미지가 없는 경우
      return _buildEmptyImageContent(width);
    });
  }

  // 이미지가 있을 때
  Widget _buildImageContent(
    double width,
    List<dynamic> images, {
    required bool isAssetEntity,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ImageRow(
          width: width,
          images: images,
          controller: controller,
          onSelectImages: onSelectImages,
        ),
        SizedBox(height: width * 0.01),
        ImageSlider(
          images: images,
          width: width,
          boxFit: isAssetEntity ? BoxFit.contain : null,
        ),
        SizedBox(height: width * 0.01),
      ],
    );
  }

  // 이미지가 없을 때
  Widget _buildEmptyImageContent(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddImageButton(width: width, onPressed: onSelectImages),
        Container(
          width: Get.width,
          height: Get.width,
          margin: EdgeInsets.all(width * 0.02),
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Text('선택된 사진이 없습니다.', style: Get.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

// 이미지 추가 버튼, 선택된 이미지 목록
class _ImageRow extends StatelessWidget {
  final double width;
  final List<dynamic> images;
  final ManitoPostController controller;
  final VoidCallback onSelectImages;

  const _ImageRow({
    required this.width,
    required this.images,
    required this.controller,
    required this.onSelectImages,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _AddImageButton(width: width, onPressed: onSelectImages),
          SizedBox(
            height: width * 0.22,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder:
                  (context, index) => _ImageItem(
                    width: width,
                    image: images[index],
                    index: index,
                    controller: controller,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// 선택한 이미지 작은 크기
class _ImageItem extends StatelessWidget {
  final double width;
  final dynamic image;
  final int index;
  final ManitoPostController controller;

  const _ImageItem({
    required this.width,
    required this.image,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [_buildImageContainer(), _buildDeleteButton()]);
  }

  // 선택한 이미지 작은 컨테이너
  Widget _buildImageContainer() {
    return Container(
      width: width * 0.2,
      height: width * 0.2,
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.fromLTRB(0, width * 0.02, width * 0.02, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.02),
      ),
      child:
          image is AssetEntity
              ? AssetEntityImage(image, fit: BoxFit.cover)
              : Image(image: image, fit: BoxFit.cover),
    );
  }

  // 선택한 이미지 삭제 버튼
  Widget _buildDeleteButton() {
    return Positioned(
      top: 0,
      right: 0,
      child: SizedBox(
        width: width * 0.08,
        height: width * 0.08,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.cancel),
          iconSize: width * 0.08,
          color: Colors.grey,
          onPressed:
              image is AssetEntity
                  ? () => controller.deleteSelectedImage(index)
                  : () => controller.deletePostImage(index),
        ),
      ),
    );
  }
}

// 이미지 추가 버튼
class _AddImageButton extends StatelessWidget {
  final double width;
  final VoidCallback onPressed;

  const _AddImageButton({required this.width, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(width * 0.02, width * 0.02, width * 0.02, 0),
      child: SizedBox(
        width: width * 0.2,
        height: width * 0.2,
        child: OutlinedButton.icon(
          label: Icon(Icons.add_a_photo_outlined, size: width * 0.07),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

// 바텀 버튼
class _ActionButton extends StatelessWidget {
  final bool isLoading;
  final bool isPosting;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.isLoading,
    required this.isPosting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child:
          isLoading
              ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
              : Text(
                isPosting ? '미션 종료' : '임시저장',
                style: Get.textTheme.titleLarge,
              ),
    );
  }
}
