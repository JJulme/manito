import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class AlbumScreen extends GetResponsiveView<AlbumController> {
  AlbumScreen({super.key}) {
    Get.put(AlbumController());
  }

  @override
  Widget phone() {
    double width = Get.width;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            return TextButton(
              onPressed:
                  (controller.selectedImages.isEmpty)
                      ? null
                      : () => Get.back(result: controller.selectedImageList),
              child:
                  (controller.selectedImages.isEmpty)
                      ? Text('선택', style: Get.textTheme.labelLarge)
                      : Text(
                        '${controller.selectedImages.length} 선택',
                        style: Get.textTheme.bodySmall,
                      ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          } else if (controller.imageAssets.isEmpty) {
            return const Center(child: Text('이미지가 없습니다.'));
          } else {
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                mainAxisSpacing: 0.01 * width,
                crossAxisSpacing: 0.01 * width,
              ),
              itemCount: controller.imageAssets.length,
              itemBuilder: (context, index) {
                final AssetEntity imageAsset = controller.imageAssets[index];
                final selectedImages = controller.selectedImages;

                return Obx(() {
                  return GestureDetector(
                    onTap: () => controller.toggleImageSelection(imageAsset),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AssetEntityImage(imageAsset, fit: BoxFit.cover),
                        Positioned(
                          top: 0.02 * width,
                          right: 0.02 * width,
                          child:
                              (selectedImages[imageAsset.id] == null)
                                  ? Container(
                                    width: 0.08 * width,
                                    height: 0.08 * width,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 0.008 * width,
                                      ),
                                    ),
                                  )
                                  : Container(
                                    width: 0.08 * width,
                                    height: 0.08 * width,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                    ),
                                    child: Text(
                                      '${selectedImages[imageAsset.id]! + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  );
                });
              },
            );
          }
        }),
      ),
    );
  }
}

class AlbumController extends GetxController {
  var isLoading = false.obs;
  // 앨범에서 가져온 이미지 전부
  var imageAssets = <AssetEntity>[].obs;
  // 선택한 이미지가 들어있는 맵
  final RxMap<String, int> selectedImages = <String, int>{}.obs;

  @override
  void onInit() async {
    super.onInit();
    await fetchImages();
  }

  // 앨범에 이미지 가져오기
  Future<void> fetchImages() async {
    isLoading.value = true;
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    try {
      if (ps.isAuth) {
        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          onlyAll: false,
          type: RequestType.image,
        );
        imageAssets.clear();
        for (var path in paths) {
          final List<AssetEntity> entities = await path.getAssetListPaged(
            page: 0,
            size: await path.assetCountAsync,
          );
          imageAssets.addAll(entities);
        }
        // 이미지 중복제거
        imageAssets.value = imageAssets.toSet().toList();
        // 이미지 최신순으로 정렬
        imageAssets.sort(
          (a, b) => b.createDateTime.compareTo(a.createDateTime),
        );
      } else {
        customSnackbar(
          title: '알림',
          message: '이미지 접근 권한이 필요합니다.',
          onTap: (_) => PhotoManager.openSetting(),
        );
      }
    } catch (e) {
      debugPrint('fetchImages Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 이미지 선택 함수
  void toggleImageSelection(AssetEntity asset) {
    // 이미 선택된 이미지 취소
    if (selectedImages.containsKey(asset.id)) {
      final int removedIndex = selectedImages[asset.id]!;
      selectedImages.removeWhere((key, value) => value == removedIndex);
      for (final key in selectedImages.keys) {
        if (selectedImages[key]! > removedIndex) {
          selectedImages[key] = selectedImages[key]! - 1;
        }
      }
    }
    // 선택 가능 이미지 개수 제한
    else if ((selectedImages.length >= 6)) {
      customSnackbar(title: '선택 제한', message: '최대 6개까지 선택할 수 있습니다.');
    }
    // 선택한 이미지 추가
    else {
      selectedImages[asset.id] = selectedImages.length;
    }
  }

  // 선택한 이미지 전달
  List<AssetEntity> get selectedImageList {
    final sortedEntries =
        selectedImages.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    return sortedEntries
        .map((e) => imageAssets.firstWhere((asset) => asset.id == e.key))
        .toList();
  }
}
