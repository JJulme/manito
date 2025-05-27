import 'package:carousel_slider/carousel_slider.dart';
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
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ManitoPostScreen extends StatelessWidget {
  ManitoPostScreen({super.key});

  final ManitoPostController _controller = Get.put(ManitoPostController());
  final PostController _postController = Get.find<PostController>();

  /// 앨범에서 이미지 선택 함수
  void _selectImages() async {
    List<AssetEntity>? result = await Get.to(() => AlbumScreen());
    if (result != null) {
      _controller.selectedImages.value = result;
      // 저장 상태 변경
      _controller.isPosting.value = false;
    }
  }

  /// 친구에게 게시물 보내는 함수
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

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0.07 * width,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Text('미션 기록하기'),
              SizedBox(width: 0.02 * width),
              TimerWidget(
                targetDateTime: _controller.missionAccept.deadline,
                fontSize: 0.065 * width,
              ),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 0.02 * width),
              child: IconButton(
                padding: EdgeInsets.all(0),
                icon: Icon(Icons.close_rounded, size: 0.07 * width),
                onPressed: () => Get.back(result: false),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            if (_controller.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            } else {
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // 사진
                        Obx(() {
                          RxList<ImageProvider<Object>>? cachedImages =
                              _controller.cachedImages;
                          var selectedImages = _controller.selectedImages;
                          // 앨범에서 이미지를 선택한 경우
                          if (selectedImages.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 가로 스크롤 - 이미지 추가 버튼, 이미지 보여주는 목록
                                selectedImageRow(width, selectedImages),
                                SizedBox(height: 0.01 * width),
                                // 이미지 보여주는 슬라이더
                                ImageSlider(
                                  images: selectedImages,
                                  width: width,
                                ),
                                SizedBox(height: 0.01 * width),
                              ],
                            );
                          }
                          // 저장된 내용 가져올 경우
                          else if (cachedImages.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 가로 스크롤 - 이미지 추가 버튼, 이미지 보여주는 목록
                                selectedImageRow(width, cachedImages),
                                SizedBox(height: 0.01 * width),
                                // 이미지 보여주는 슬라이더
                                ImageSlider(images: cachedImages, width: width),
                                SizedBox(height: 0.01 * width),
                              ],
                            );
                          }
                          // 이미지가 없을 경우
                          else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                addImageBtn(width),
                                Container(
                                  width: Get.width,
                                  height: Get.width,
                                  margin: EdgeInsets.all(0.02 * width),
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: Text(
                                    '선택된 사진이 없습니다.',
                                    style: Get.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            );
                          }
                        }),
                        // 문구
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            0.02 * width,
                            0,
                            0.02 * width,
                            0.02 * width,
                          ),
                          child: TextField(
                            controller: _controller.descController,
                            minLines: 3,
                            maxLines: null,
                            maxLength: 999,
                            style: Get.textTheme.bodyMedium,
                            onChanged: (value) {
                              _controller.isPosting.value = false;
                            },
                            decoration: InputDecoration(
                              counterText: '',
                              hintText:
                                  '[${_controller.creatorProfile.nickname}] 에게\n[${_controller.missionAccept.content}]\n미션을 어떻게 수행 했는지 작성 해주세요.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 업로드 중 터치방지
                  !_controller.updateLoading.value
                      ? SizedBox.shrink()
                      : ModalBarrier(
                        dismissible: false,
                        color: Colors.black.withAlpha((0.5 * 255).round()),
                      ),
                ],
              );
            }
          }),
        ),
        // 저장, 전송 버튼
        bottomNavigationBar: BottomAppBar(
          child: Container(
            margin: EdgeInsets.all(0.03 * width),
            child: Obx(() {
              return ElevatedButton(
                onPressed:
                    _controller.updateLoading.value
                        ? null
                        : () {
                          // 5글자 이상인지 확인
                          if (_controller.descController.text.length < 5) {
                            customSnackbar(
                              title: '정성부족',
                              message: '5글자 이상 작성해 주세요.',
                            );
                            return;
                          }
                          // 상태에 따라 적절한 함수 호출
                          _controller.isPosting.value
                              ? _completePost()
                              : _controller.updatePost();
                        },
                child:
                    _controller.updateLoading.value
                        ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : Text(
                          _controller.isPosting.value ? '미션 종료' : '임시저장',
                          style: Get.textTheme.titleLarge,
                        ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// 선택한 이미지 목록을 보여주고 삭제 가능
  SingleChildScrollView selectedImageRow(double width, List<dynamic> images) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // 이미지 추가, 목록
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 이미지 추가 버튼
          addImageBtn(width),
          // 추가된 이미지 목록
          SizedBox(
            height: 0.22 * width,
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                var image = images[index];
                return imageItem(width, image, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 앨범에서 선택한 이미지를 작게 보여주는 컨테이너
  Stack imageItem(double width, dynamic image, int index) {
    return Stack(
      children: [
        Container(
          width: 0.2 * width,
          height: 0.2 * width,
          clipBehavior: Clip.hardEdge,
          margin: EdgeInsets.fromLTRB(0, 0.02 * width, 0.02 * width, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0.1 * 0.2 * width),
          ),
          child:
              image is AssetEntity
                  ? AssetEntityImage(image, fit: BoxFit.cover)
                  : Image(image: image, fit: BoxFit.cover),
        ),
        // 이미지 삭제 버튼
        Positioned(
          top: 0,
          right: 0,
          child: SizedBox(
            width: 0.08 * width,
            height: 0.08 * width,
            child: IconButton(
              padding: const EdgeInsets.all(0),
              icon: const Icon(Icons.cancel),
              iconSize: 0.08 * width,
              color: Colors.grey,
              onPressed:
                  image is AssetEntity
                      ? () => _controller.deleteSelectedImage(index)
                      : () => _controller.deletePostImage(index),
            ),
          ),
        ),
      ],
    );
  }

  /// 이미지 슬라이더
  Stack imageSlider(List<dynamic> images, double width) {
    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: images.length,
          itemBuilder: (context, index, realIndex) {
            final image = images[index];
            return Container(
              width: Get.width,
              height: Get.width,
              margin: EdgeInsets.all(0.01 * width),
              child:
                  image is AssetEntity
                      ? AssetEntityImage(image, fit: BoxFit.cover)
                      : Image(image: image, fit: BoxFit.cover),
            );
          },
          options: CarouselOptions(
            enableInfiniteScroll: false,
            viewportFraction: 1,
            height: Get.width,
            onPageChanged: (index, reason) {
              _controller.activeIndex.value = index;
            },
          ),
        ),
        Positioned(
          bottom: 0.02 * width,
          child: Container(
            width: Get.width,
            alignment: Alignment.bottomCenter,
            child: AnimatedSmoothIndicator(
              activeIndex: _controller.activeIndex.value,
              count: images.length,
              effect: JumpingDotEffect(
                dotWidth: 0.02 * width,
                dotHeight: 0.02 * width,
                activeDotColor: Colors.white,
                dotColor: Colors.white.withAlpha((0.5 * 255).round()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 이미지 선택 앨범 이동 버튼
  Container addImageBtn(double width) {
    return Container(
      margin: EdgeInsets.fromLTRB(0.02 * width, 0.02 * width, 0.02 * width, 0),
      child: SizedBox(
        width: 0.2 * width,
        height: 0.2 * width,
        child: OutlinedButton.icon(
          label: Icon(Icons.add_a_photo_outlined, size: 0.07 * width),
          onPressed: _selectImages,
        ),
      ),
    );
  }
}
