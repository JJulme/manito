import 'package:easy_localization/easy_localization.dart';
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
  late final AutoReplyController _controller;
  // Constants
  static const int _maxReplyLength = 300;
  static const int _minLines = 5;
  static const int _maxLines = 15;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(AutoReplyController());
  }

  // 저장 버튼 함수
  VoidCallback? _handleSave() {
    if (_controller.updateLoading.value) {
      return null;
    } else {
      return () async {
        if (_controller.replyController.text.length < 5) {
          customSnackbar(
            title: context.tr("auto_reply_screen.snack_title"),
            message: context.tr("auto_reply_screen.snack_message"),
          );
        } else {
          String result = await _controller.updateAutoReply(
            _controller.replyController.text,
          );
          if (result != "auto_reply_modify_success") {
            if (!mounted) return;
            customSnackbar(
              title: context.tr("auto_reply_screen.snack_title_error"),
              message: context.tr("auto_reply_screen.$result"),
            );
          }
        }
      };
    }
  }

  // 본체
  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(appBar: _buildAppBar(width), body: _buildBody(width)),
    );
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      centerTitle: false,
      titleSpacing: 0.02 * screenWidth,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      title:
          Text(
            "auto_reply_screen.title",
            style: Get.textTheme.headlineMedium,
          ).tr(),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 0.02 * screenWidth),
          child: Obx(
            () => IconButton(
              icon:
                  _controller.updateLoading.value
                      ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(kGrey),
                      )
                      : Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 0.08 * screenWidth,
                      ),
              onPressed: _handleSave(),
            ),
          ),
        ),
      ],
    );
  }

  // 바디
  Widget _buildBody(double screenWidth) {
    return SafeArea(
      child: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            _buildReplyTextField(screenWidth),
            if (_controller.updateLoading.value) _buildLoadingOverlay(),
          ],
        );
      }),
    );
  }

  // 자동응답 텍스트 필드
  Widget _buildReplyTextField(double screenWidth) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(0.02 * screenWidth),
            child: TextField(
              controller: _controller.replyController,
              minLines: _minLines,
              maxLines: _maxLines,
              maxLength: _maxReplyLength,
              style: Get.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.tr("auto_reply_screen.hint"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 로딩중 입력방지
  Widget _buildLoadingOverlay() {
    return ModalBarrier(
      dismissible: false,
      color: Colors.black.withAlpha((0.5 * 255).round()),
    );
  }
}
