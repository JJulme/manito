import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/widget/sub_appbar.dart';
import 'package:manito/features/theme/theme.dart';
import 'package:manito/features_new/friends/presentation/providers/user_relation_provider.dart';
import 'package:manito/features_new/profile/domain/entities/user_profile_entity.dart';
import 'package:manito/main.dart';

class EditFriendNicknameScreen extends ConsumerStatefulWidget {
  final String userId;
  final UserEntity profile;
  const EditFriendNicknameScreen({
    super.key,
    required this.userId,
    required this.profile,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditFriendNicknameScreenState();
}

class _EditFriendNicknameScreenState
    extends ConsumerState<EditFriendNicknameScreen> {
  /// 이름 텍스트 필드 폼키
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.displayName;
  }

  /// 이름 입력 검증 함수
  String? _validateNickname(String? value) {
    // 값이 비어있는지 확인
    if (value == null || value.trim().isEmpty) {
      return context.tr("friends_modify_screen.validator");
    }
    return null;
  }

  // 이름 수정 업데이트 동작
  Future<void> _handleUpdateNickname() async {
    if (_formKey.currentState!.validate()) {
      final friendName = _nameController.text.trim();
      await ref
          .read(userRelationProvider.notifier)
          .updateNickname(widget.profile.id, friendName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final relationState = ref.watch(userRelationProvider);
    ref.listen(userRelationProvider, (prev, next) {
      if (next.hasValue && (prev!.isLoading == true)) {
        context.pop();
      }
    });
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(
          title:
              Text(
                "friends_modify_screen.title",
                style: Theme.of(context).textTheme.headlineSmall,
              ).tr(),
          actions: [_buildUpdateBtn(relationState)],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameInputSection(),
                  _buildCurrentName(widget.profile.nickname),
                ],
              ),
              if (relationState.isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // 변경 버튼
  IconButton _buildUpdateBtn(AsyncValue<void> state) {
    if (state.isLoading) {
      return IconButton(
        onPressed: null,
        icon: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      );
    }
    return IconButton(
      icon: Icon(Icons.check, color: kSuccess, size: width * 0.07),
      onPressed: _handleUpdateNickname,
    );
  }

  // 친구 이름 수정 텍스트 폼필드
  Widget _buildNameInputSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Form(
        key: _formKey,
        child: TextFormField(
          maxLength: 10,
          validator: _validateNickname,
          controller: _nameController,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n]'))],
          decoration: InputDecoration(
            labelText: context.tr("friends_modify_screen.name"),
          ),
        ),
      ),
    );
  }

  // 친구가 직접 설정한 이름 보여주는 텍스트
  Widget _buildCurrentName(String nickname) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Text(
        '${context.tr("friends_modify_screen.friend_set_name")} : $nickname',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  // 로딩중 입력 방지
  Widget _buildLoadingOverlay() {
    return ModalBarrier(
      dismissible: false,
      color: Colors.black.withAlpha((0.5 * 255).round()),
    );
  }
}
