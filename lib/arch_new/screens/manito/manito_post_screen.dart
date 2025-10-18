import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/arch_new/features/manito/manito.dart';
import 'package:manito/arch_new/features/manito/manito_provider.dart';
import 'package:manito/arch_new/share/sub_appbar.dart';
import 'package:manito/arch_new/widgets/image_slider.dart';
import 'package:manito/widgets/common/custom_toast.dart';
import 'package:manito/widgets/mission/timer.dart';
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

  void _handleDescription(String description) {
    final notifier = ref.read(manitoPostProvider(widget.manitoAccept).notifier);
    notifier.updateDescription(description);
  }

  // 버튼 동작
  void _handleBottomButton(double width, ManitoPostState state) async {
    // 저장중, 미션 종료중
    if (state.isSaving || state.isPosting) {
      null;
    }
    // 미션 종료 가능할 때
    else if (state.canPost) {
      final notifier = ref.read(
        manitoPostProvider(widget.manitoAccept).notifier,
      );
      await notifier.completePost();
    }
    // 설명 글자수가 5글자 보다 많을 때 저장 가능
    else if (_descController.text.length >= 5) {
      final notifier = ref.read(
        manitoPostProvider(widget.manitoAccept).notifier,
      );
      await notifier.savePost();
    }
    // 글자 수 부족
    else {
      customToast(width: width, msg: '정성부족');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final state = ref.watch(manitoPostProvider(widget.manitoAccept));
    final notifier = ref.read(manitoPostProvider(widget.manitoAccept).notifier);

    // 설명 동기화
    if (state.description != _descController.text &&
        !_descController.selection.isValid) {
      _descController.text = state.description;
    }

    ref.listen(manitoPostProvider(widget.manitoAccept), (previous, next) {
      if (next.status == ManitoPostStatus.posted) {
        context.pop(true);
        ref
            .read(manitoListProvider.notifier)
            .refreshAll(context.locale.languageCode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("manito_post_screen.complete_success").tr()),
        );
      } else if (previous?.status == ManitoPostStatus.saving &&
          next.status == ManitoPostStatus.saved) {
        customToast(width: width, msg: '저장성공');
      } else if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${next.error}')));
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(
          width: width,
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
        body: _buildBody(width, state, notifier),
        bottomNavigationBar: _buildBottomButton(width, state),
      ),
    );
  }

  Widget _buildBody(
    double width,
    ManitoPostState state,
    ManitoPostNotifier notifier,
  ) {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildImageSection(width, state, notifier),
                _buildDescriptionSection(width),
                _buildWarningMessage(width),
              ],
            ),
          ),
          if (state.isSaving || state.isPosting)
            ModalBarrier(
              dismissible: false,
              color: Colors.black.withAlpha((0.5 * 255).round()),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    double width,
    ManitoPostState state,
    ManitoPostNotifier notifier,
  ) {
    // 서버에 저장된 이미지가 있는 경우
    if (state.existingImageUrls.isNotEmpty) {
      return _buildImageContent(width, state.existingImageUrls, notifier);
    }
    // 앨범에서 선택된 이미지가 있는 경우
    else if (state.selectedImages.isNotEmpty) {
      return _buildImageContent(width, state.selectedImages, notifier);
    }
    // 이미지가 없는 경우
    else {
      return _buildEmptyImageContent(width, context);
    }
  }

  // 이미지가 있을 때
  Widget _buildImageContent(
    double width,
    List<dynamic> images,
    ManitoPostNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _ImageRow(images: images, addPressed: () {}, delPressed: () {}),
        _buildImageRow(width, images, notifier),
        SizedBox(height: width * 0.01),
        ImageSlider(images: images, width: width),
        SizedBox(height: width * 0.01),
      ],
    );
  }

  // 이미지가 없을 때
  Widget _buildEmptyImageContent(double width, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddImageButton(onPressed: _toAlbumScreen),
        Container(
          width: width - (width * 0.04),
          height: width - (width * 0.04),
          margin: EdgeInsets.all(width * 0.02),
          color: Colors.grey[200],
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
  Widget _buildImageRow(
    double width,
    List<dynamic> images,
    ManitoPostNotifier notifier,
  ) {
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
  Widget _buildDescriptionSection(double width) {
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
  Widget _buildWarningMessage(double width) {
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
  Widget _buildBottomButton(double width, ManitoPostState state) {
    return BottomAppBar(
      child: Container(
        margin: EdgeInsets.all(width * 0.03),
        child: ElevatedButton(
          onPressed: () => _handleBottomButton(width, state),
          child:
              state.isSaving || state.isPosting
                  ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                  : Text(
                    state.canPost
                        ? context.tr("manito_post_screen.btn_complete_mission")
                        : context.tr("manito_post_screen.btn_safe_draft"),
                    style: Theme.of(context).textTheme.titleLarge,
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
    final double width = MediaQuery.of(context).size.width;
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
    final double width = MediaQuery.of(context).size.width;
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
