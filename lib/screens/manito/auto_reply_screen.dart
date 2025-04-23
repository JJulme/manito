import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/manito_controller.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';

class AutoReplyScreen extends StatefulWidget {
  const AutoReplyScreen({super.key});

  @override
  State<AutoReplyScreen> createState() => _AutoReplyScreenState();
}

class _AutoReplyScreenState extends State<AutoReplyScreen> {
  final AutoReplyController _controller = Get.put(AutoReplyController());

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0.02 * width,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Get.back(),
          ),
          title: Text('자동 응답 설정', style: Get.textTheme.headlineMedium),
          actions: [
            Obx(
              () => IconButton(
                icon:
                    _controller.updateLoading.value
                        ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(kGrey),
                        )
                        : Icon(
                          Icons.check,
                          color: Colors.green,
                          size: 0.08 * width,
                        ),
                onPressed:
                    _controller.updateLoading.value
                        ? null
                        : () async {
                          if (_controller.replyController.text.length < 5) {
                            customSnackbar(
                              title: '알림',
                              message: '5글자 이상 작성되어야 합니다.',
                            );
                          } else {
                            String result = await _controller.updateAutoReply(
                              _controller.replyController.text,
                            );
                            customSnackbar(title: '알림', message: result);
                          }
                        },
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
                        // // 사진
                        // GestureDetector(
                        //   onTap: () => _controller.pickImage(),
                        //   child: Obx(() {
                        //     var selectedImage =
                        //         _controller.selectedImage.value;
                        //     var replyImageUrl =
                        //         _controller.autoReply.value?.replyImageUrl ??
                        //             '';
                        //     // 갤러리에서 이미지 선택했을 때
                        //     if (selectedImage != null) {
                        //       return Stack(
                        //         children: [
                        //           Container(
                        //             width: Get.width,
                        //             height: Get.width,
                        //             padding: EdgeInsets.all(0.01 * di),
                        //             child: Image.file(
                        //               selectedImage,
                        //               fit: BoxFit.cover,
                        //             ),
                        //           ),
                        //           Positioned(
                        //             top: 0.01 * di,
                        //             right: 0.01 * di,
                        //             child: IconButton(
                        //               padding: const EdgeInsets.all(0),
                        //               icon: Icon(
                        //                 Icons.cancel_rounded,
                        //                 color: kGrey,
                        //                 size: 0.05 * di,
                        //               ),
                        //               onPressed: () {
                        //                 _controller.deleteImage();
                        //               },
                        //             ),
                        //           ),
                        //         ],
                        //       );
                        //     }
                        //     // 기존 설정된 이미지
                        //     else if (replyImageUrl.isNotEmpty) {
                        //       return Stack(
                        //         children: [
                        //           Container(
                        //             width: Get.width,
                        //             height: Get.width,
                        //             padding: EdgeInsets.all(0.01 * di),
                        //             child: Image(
                        //               image: CachedNetworkImageProvider(
                        //                   replyImageUrl),
                        //               fit: BoxFit.cover,
                        //             ),
                        //           ),
                        //           Positioned(
                        //             top: 0.01 * di,
                        //             right: 0.01 * di,
                        //             child: IconButton(
                        //               padding: const EdgeInsets.all(0),
                        //               icon: Icon(
                        //                 Icons.cancel_rounded,
                        //                 color: kGrey,
                        //                 size: 0.05 * di,
                        //               ),
                        //               onPressed: () {
                        //                 _controller.deleteImage();
                        //               },
                        //             ),
                        //           ),
                        //         ],
                        //       );
                        //     }
                        //     // 이미지가 없을 경우
                        //     else {
                        //       return Container(
                        //         width: Get.width,
                        //         height: Get.width,
                        //         padding: EdgeInsets.all(0.01 * di),
                        //         child: Container(
                        //           decoration: BoxDecoration(
                        //               border: Border.all(width: 0.001 * di)),
                        //           child: Icon(
                        //             Icons.add_a_photo_outlined,
                        //             size: 0.05 * di,
                        //           ),
                        //         ),
                        //       );
                        //     }
                        //   }),
                        // ),

                        // 문구
                        Padding(
                          padding: EdgeInsets.all(0.02 * width),
                          child: TextField(
                            controller: _controller.replyController,
                            minLines: 5,
                            maxLines: 15,
                            maxLength: 300,
                            style: Get.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText:
                                  '미션 이후 게시물을 작성 못 했을 경우 자동으로 친구에게 전송되는 문구입니다.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      ),
    );
  }
}
