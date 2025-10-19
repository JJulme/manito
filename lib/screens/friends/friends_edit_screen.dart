import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features/friends/friends.dart';
import 'package:manito/features/friends/friends_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/share/sub_appbar.dart';

class FriendsEditScreen extends ConsumerStatefulWidget {
  final FriendProfile? friendProfile;
  const FriendsEditScreen({super.key, required this.friendProfile});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FriendsEditScreenState();
}

class _FriendsEditScreenState extends ConsumerState<FriendsEditScreen> {
  /// 이름 텍스트 필드 폼키
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.friendProfile!.friendNickname != null) {
      _nameController.text = widget.friendProfile!.friendNickname!;
    } else {
      _nameController.text = widget.friendProfile!.nickname;
    }
  }

  /// 이름 입력 검증 함수
  String? _validateNickname(String? value) {
    // 값이 비어있는지 확인
    if (value == null || value.trim().isEmpty) {
      return context.tr("friends_modify_screen.validator");
    }
    return null;
  }

  Future<void> _updateFriendName(double width, String friendId) async {
    if (_formKey.currentState!.validate()) {
      final friendName = _nameController.text.trim();
      final result = await ref
          .read(friendEditProvider.notifier)
          .updateFriendName(friendId, friendName);

      if (result) {
        await ref.read(friendProfilesProvider.notifier).fetchFriendList();
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        customToast(width: width, msg: '오류 발생');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final state = ref.watch(friendEditProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(
          width: width,
          title:
              Text(
                "friends_modify_screen.title",
                style: Theme.of(context).textTheme.titleMedium,
              ).tr(),
          actions: [_buildUpdateBtn(width, state)],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: width * 0.02),
                  _buildNameInputSection(width),
                  _buildCurrentName(width),
                ],
              ),
              if (state.isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  IconButton _buildUpdateBtn(double width, FriendEditState state) {
    if (state.isLoading) {
      return IconButton(
        onPressed: null,
        icon: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      );
    }
    return IconButton(
      icon: Icon(Icons.check, color: Colors.green, size: width * 0.08),
      onPressed: () => _updateFriendName(width, widget.friendProfile!.id),
    );
  }

  // 친구 이름 수정 텍스트 폼필드
  Widget _buildNameInputSection(double width) {
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
  Widget _buildCurrentName(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Text(
        '${context.tr("friends_modify_screen.friend_set_name")} : ${widget.friendProfile!.nickname}',
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
