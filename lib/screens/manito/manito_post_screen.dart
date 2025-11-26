import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/manito/manito.dart';
import 'package:manito/features/manito/manito_provider.dart';
import 'package:manito/features/theme/theme.dart';
import 'package:manito/main.dart';
import 'package:manito/share/common_dialog.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/image_slider.dart';
import 'package:manito/widgets/timer.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class ManitoPostScreen extends ConsumerStatefulWidget {
  final ManitoAccept manitoAccept;
  const ManitoPostScreen({super.key, required this.manitoAccept});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManitoPostScreenState();
}

class _ManitoPostScreenState extends ConsumerState<ManitoPostScreen> {
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
  }

  // 설명 동기화
  void initDescription(ManitoPostState state) {
    if (state.description != _descController.text &&
        !_descController.selection.isValid) {
      _descController.text = state.description;
    }
  }

  // 앨범 이동
  void _toAlbumScreen() async {
    await context.push('/album', extra: widget.manitoAccept);
  }

  // 이미지 삭제
  void _handleDeleteImage(dynamic image, int index) {
    final notifier = ref.read(manitoPostProvider(widget.manitoAccept).notifier);
    if (image is AssetEntity) {
      notifier.removeSelectedImage(index);
    } else {
      notifier.removeExistingImage(index);
    }
  }

  // 설명 입력시 스테이트에 추가
  void _handleDescription(String description) {
    final notifier = ref.read(manitoPostProvider(widget.manitoAccept).notifier);
    notifier.updateDescription(description);
  }

  // 버튼 동작
  void _handleBottomButton(ManitoPostState state) async {
    // 저장중, 미션 종료중
    if (state.status == ManitoPostStatus.saving ||
        state.status == ManitoPostStatus.posting) {
      null;
    }
    // 미션 종료 가능할 때
    else if (state.status == ManitoPostStatus.saved) {
      final result = await DialogHelper.showConfirmDialog(
        context,
        title: '미션 종료',
        message: '미션을 종료하시겠습니까?',
      );
      if (result!) {
        await ref
            .read(manitoPostProvider(widget.manitoAccept).notifier)
            .completePost();
      }
    }
    // 설명 글자수가 5글자 보다 많을 때 저장 가능
    else if (_descController.text.length >= 5) {
      ref.read(manitoPostProvider(widget.manitoAccept).notifier).savePost();
    }
    // 글자 수 부족
    else {
      customToast(msg: '정성부족');
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(manitoPostProvider(widget.manitoAccept));

    ref.listen(manitoPostProvider(widget.manitoAccept), (previous, next) {
      next.whenOrNull(
        data: (state) {
          // 미션종료가 완료되면 실행
          if (state.status == ManitoPostStatus.posted) {
            context.pop(true);
            customToast(msg: '미션 완료! 친구의 추측을 기다려보세요!');
            ref
                .read(manitoListProvider.notifier)
                .refreshAll(context.locale.languageCode);
          }
          // 임시저장 성공하면 실행
          else if (previous?.value?.status == ManitoPostStatus.saving &&
              state.status == ManitoPostStatus.saved) {
            customToast(msg: '저장 성공');
          }
        },
      );
    });

    return postAsync.when(
      loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Center(child: Text(error.toString())),
      data: (state) {
        initDescription(state);
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            appBar: SubAppbar(
              title: Row(
                children: [
                  Text('미션 기록하기'),
                  SizedBox(width: width * 0.02),
                  TimerWidget(
                    targetDateTime: widget.manitoAccept.deadline,
                    fontSize: width * 0.063,
                  ),
                ],
              ),
            ),
            body: _buildBody(state),
            bottomNavigationBar: _buildBottomButton(state),
          ),
        );
      },
    );
  }

  // 바디
  Widget _buildBody(ManitoPostState state) {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildImageSection(state),
                _buildDescriptionSection(),
                _buildWarningMessage(),
              ],
            ),
          ),
          // 로딩 시 입력 불가
          if (state.status == ManitoPostStatus.saving ||
              state.status == ManitoPostStatus.posting)
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withAlpha((0.5 * 255).round()),
            ),
        ],
      ),
    );
  }

  // 이미지
  Widget _buildImageSection(ManitoPostState state) {
    // 서버에 저장된 이미지가 있는 경우
    if (state.existingImageUrls.isNotEmpty) {
      return _buildImageContent(state.existingImageUrls);
    }
    // 앨범에서 선택된 이미지가 있는 경우
    else if (state.selectedImages.isNotEmpty) {
      return _buildImageContent(state.selectedImages);
    }
    // 이미지가 없는 경우
    else {
      return _buildEmptyImageContent(context);
    }
  }

  // 이미지가 있을 때
  Widget _buildImageContent(List<dynamic> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _ImageRow(images: images, addPressed: () {}, delPressed: () {}),
        _buildImageRow(images),
        SizedBox(height: width * 0.01),
        ImageSlider(images: images),
        SizedBox(height: width * 0.01),
      ],
    );
  }

  // 이미지가 없을 때
  Widget _buildEmptyImageContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddImageButton(onPressed: _toAlbumScreen),
        Container(
          width: width - (width * 0.04),
          height: width - (width * 0.04),
          margin: EdgeInsets.all(width * 0.02),
          color: ColorScheme.of(context).primaryContainer,
          alignment: Alignment.center,
          child:
              Text(
                'manito_post_screen.no_image',
                style: Theme.of(context).textTheme.bodyMedium,
              ).tr(),
        ),
      ],
    );
  }

  // 이미지 추가 버튼, 이미지 목록
  Widget _buildImageRow(List<dynamic> images) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _AddImageButton(onPressed: _toAlbumScreen),
          SizedBox(
            height: width * 0.22,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length,
              itemBuilder:
                  (context, index) => _ImageItem(
                    image: images[index],
                    onPressed: () => _handleDeleteImage(images[index], index),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // 설명 쓰는 부분
  Widget _buildDescriptionSection() {
    final String toFriend = context.tr(
      "manito_post_screen.to_friend",
      namedArgs: {"nickname": widget.manitoAccept.creatorProfile.displayName},
    );
    final String todoMission = context.tr("manito_post_screen.todo_mission");
    final String hintText =
        '$toFriend\n[${widget.manitoAccept.content}]\n$todoMission';

    return Padding(
      padding: EdgeInsets.fromLTRB(width * 0.02, 0, width * 0.02, width * 0.02),
      child: TextField(
        controller: _descController,
        minLines: 3,
        maxLines: null,
        maxLength: 999,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(counterText: '', hintText: hintText),
        onChanged: (_) => _handleDescription(_descController.text),
      ),
    );
  }

  // 경고 문구
  Widget _buildWarningMessage() {
    return Padding(
      padding: EdgeInsets.fromLTRB(width * 0.03, 0, width * 0.03, width * 0.02),
      child:
          Text(
            "manito_post_screen.warning_message",
            style: Theme.of(context).textTheme.labelMedium,
          ).tr(),
    );
  }

  // 바텀 버튼
  Widget _buildBottomButton(ManitoPostState state) {
    return BottomAppBar(
      child: Container(
        // margin: EdgeInsets.all(width * 0.03),
        margin: EdgeInsets.all(0),
        child: ElevatedButton(
          onPressed: () => _handleBottomButton(state),
          child:
              state.status == ManitoPostStatus.saving ||
                      state.status == ManitoPostStatus.posting
                  ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                  : Text(
                    state.status == ManitoPostStatus.saved
                        ? context.tr("manito_post_screen.btn_complete_mission")
                        : context.tr("manito_post_screen.btn_safe_draft"),
                    style: TextStyle(
                      color: kOffBlack,
                      fontSize: TextTheme.of(context).titleLarge!.fontSize,
                    ),
                  ),
        ),
      ),
    );
  }
}

// 이미지 추가 버튼
class _AddImageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddImageButton({required this.onPressed});

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

// 선택한 이미지 작은 사이즈
class _ImageItem extends StatelessWidget {
  final dynamic image;
  final VoidCallback onPressed;
  const _ImageItem({required this.image, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [_buildImageContainer(width), _buildDeleteButton(width)],
    );
  }

  Widget _buildImageContainer(double width) {
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
              : Image(
                image: CachedNetworkImageProvider(image),
                fit: BoxFit.cover,
              ),
    );
  }

  // 선택한 이미지 삭제 버튼
  Widget _buildDeleteButton(double width) {
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
          onPressed: onPressed,
        ),
      ),
    );
  }
}
