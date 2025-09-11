import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_workers/utils/debouncer.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/controllers/mission_controller.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/common/custom_snackbar.dart';
import 'package:manito/widgets/common/custom_toast.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class MissionFriendsSearchScreen extends StatefulWidget {
  const MissionFriendsSearchScreen({super.key});

  @override
  State<MissionFriendsSearchScreen> createState() =>
      _MissionFriendsSearchState();
}

class _MissionFriendsSearchState extends State<MissionFriendsSearchScreen> {
  late final MissionCreateController _controller;
  late final FriendsController _friendsController;

  // 친구 검색 키
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    _controller = Get.find<MissionCreateController>();
    _friendsController = Get.find<FriendsController>();
  }

  // 검색 삭제
  void _clearText() {
    _searchController.clear();
    setState(() {
      searchText = '';
    });
  }

  // 친구 2명 이상 선택 완료 버튼
  void _onDone() {
    if (_controller.selectedFriends.length < 2) {
      customToast(msg: '2명 이상의 친구를 선택해 주세요.');
    } else {
      _controller.confirmSelection();
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(width),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: width * 0.05),
                _SelectedFriendsList(
                  controller: _controller,
                  screenWidth: width,
                ),
                _AllFriendsList(
                  controller: _controller,
                  friendsController: _friendsController,
                  searchText: searchText,
                  screenWidth: width,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar(double screenWidth) {
    return AppBar(
      centerTitle: false,
      titleSpacing: screenWidth * 0.02,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: Get.back,
      ),
      title: Text("친구 선택", style: Get.textTheme.headlineMedium),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: screenWidth * 0.02),
          child: TextButton(
            onPressed: _onDone,
            child: Text("완료", style: Get.textTheme.bodyMedium),
          ),
        ),
      ],
      bottom: _buildSearchForm(screenWidth),
    );
  }

  // 검색창
  PreferredSize _buildSearchForm(double screenWidth) {
    return PreferredSize(
      preferredSize: Size.fromHeight(screenWidth * 0.15),
      child: Container(
        height: screenWidth * 0.15,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenWidth * 0.012,
        ),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              labelStyle: Get.textTheme.bodySmall,
              hintText: "검색",
              prefixIcon: Icon(Icons.search_rounded, size: screenWidth * 0.06),
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.cancel_rounded, size: screenWidth * 0.06),
                onPressed: _clearText,
              ),
            ),
            onChanged: (value) {
              _debouncer.call(() {
                setState(() {
                  searchText = value;
                });
              });
            },
          ),
        ),
      ),
    );
  }
}

// 선택한 친구 리스트
class _SelectedFriendsList extends StatelessWidget {
  final MissionCreateController controller;
  final double screenWidth;

  const _SelectedFriendsList({
    required this.controller,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenWidth * 0.25,
      alignment: Alignment.centerLeft,
      child: Obx(() {
        if (controller.selectedFriends.isEmpty) {
          return Center(child: Text("친구를 선택해 주세요."));
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          separatorBuilder: (_, __) => const SizedBox.shrink(),
          itemCount: controller.selectedFriends.length,
          itemBuilder: (context, index) {
            final friend = controller.selectedFriends[index];
            return _SelectedFriendItem(
              friend: friend,
              onTap: () => controller.toggleSelection(friend),
              screenWidth: screenWidth,
            );
          },
        );
      }),
    );
  }
}

// 선택한 친구 아이템
class _SelectedFriendItem extends StatelessWidget {
  final FriendProfile friend; // Replace with proper type
  final VoidCallback onTap;
  final double screenWidth;

  const _SelectedFriendItem({
    required this.friend,
    required this.onTap,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                child: profileImageOrDefault(
                  friend.profileImageUrl!,
                  screenWidth * 0.16,
                ),
              ),
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.remove_circle_rounded, color: kGrey),
              ),
            ],
          ),
          Text(friend.nickname),
        ],
      ),
    );
  }
}

// 전체 친구 리스트
class _AllFriendsList extends StatelessWidget {
  final MissionCreateController controller;
  final FriendsController friendsController;
  final String searchText;
  final double screenWidth;

  const _AllFriendsList({
    required this.controller,
    required this.friendsController,
    required this.searchText,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List friendList = friendsController.friendList;
      final List filterdList =
          searchText.isEmpty
              ? friendList
              : friendList.where((friend) {
                final friendName = friend.nickname?.toLowerCase() ?? '';
                final query = searchText.toLowerCase();
                return friendName.contains(query);
              }).toList();

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filterdList.length,
        itemBuilder: (context, index) {
          final friend = filterdList[index];
          return _FriendListItem(
            friend: friend,
            controller: controller,
            screenWidth: screenWidth,
          );
        },
      );
    });
  }
}

// 친구 리스트 아이템
class _FriendListItem extends StatelessWidget {
  final FriendProfile friend; // Replace with proper type
  final MissionCreateController controller;
  final double screenWidth;

  const _FriendListItem({
    required this.friend,
    required this.controller,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenWidth * 0.01,
        ),
        title: _FriendInfo(friend: friend, screenWidth: screenWidth),
        visualDensity: const VisualDensity(vertical: 4),
        trailing: _FriendCheckbox(
          isSelected: controller.isSelected(friend),
          onChanged: (_) => controller.toggleSelection(friend),
          screenWidth: screenWidth,
        ),
        onTap: () => controller.toggleSelection(friend),
      );
    });
  }
}

// 친구 프로필 이미지, 이름, 상태메시지
class _FriendInfo extends StatelessWidget {
  final FriendProfile friend; // Replace with proper type
  final double screenWidth;

  const _FriendInfo({required this.friend, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        profileImageOrDefault(friend.profileImageUrl, screenWidth * 0.16),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(friend.nickname, style: Get.textTheme.bodyMedium),
              Text(
                friend.statusMessage ?? '',
                style: Get.textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 체크박스
class _FriendCheckbox extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final double screenWidth;

  const _FriendCheckbox({
    required this.isSelected,
    required this.onChanged,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: screenWidth * 0.0028,
      child: Checkbox(
        checkColor: Colors.black,
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.yellowAccent[700]!;
          }
          return Colors.white;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        value: isSelected,
        onChanged: onChanged,
      ),
    );
  }
}
