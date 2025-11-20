import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get_rx/src/rx_workers/utils/debouncer.dart';
import 'package:manito/features/missions/mission.dart';
import 'package:manito/features/missions/mission_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/core/constants.dart';
import 'package:manito/widgets/profile_image_view.dart';

class MissionFriendsSearchScreen extends ConsumerStatefulWidget {
  const MissionFriendsSearchScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MissionFriendsSearchScreenState();
}

class _MissionFriendsSearchScreenState
    extends ConsumerState<MissionFriendsSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  void _clearText() {
    _searchController.clear();
    setState(() {
      searchText = '';
    });
  }

  void _toggleFriends(FriendProfile friend) {
    ref.read(missionCreateSelectionProvider.notifier).toggleSelection(friend);
  }

  void _onDone(MissionCreateState state) {
    if (state.selectedFriends.length < 2) {
      customToast(msg: '2명 이상의 친구를 선택해 주세요');
    } else {
      ref.read(missionCreateSelectionProvider.notifier).confirmSelection();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(missionCreateSelectionProvider);
    final notifier = ref.read(missionCreateSelectionProvider.notifier);
    final friendsState = ref.watch(friendProfilesProvider).value;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(selectionState),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: width * 0.05),
                _buildSelectedFriendList(selectionState),
                _buildAllFriendList(friendsState!, notifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 앱바
  AppBar _buildAppBar(MissionCreateState state) {
    return AppBar(
      centerTitle: false,
      title: Text('친구 선택', style: Theme.of(context).textTheme.headlineMedium),
      bottom: _buildSearchForm(),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: width * 0.02),
          child: TextButton(
            onPressed: () => _onDone(state),
            child: Text("완료", style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }

  // 검색창
  PreferredSize _buildSearchForm() {
    return PreferredSize(
      preferredSize: Size.fromHeight(width * 0.15),
      child: Container(
        height: width * 0.15,
        padding: EdgeInsets.symmetric(
          vertical: width * 0.012,
          horizontal: width * 0.03,
        ),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              labelStyle: Theme.of(context).textTheme.bodySmall,
              hintText: "검색",
              prefixIcon: Icon(Icons.search_rounded, size: width * 0.06),
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.cancel_rounded, size: width * 0.06),
                onPressed: _clearText,
              ),
            ),
            onChanged: (value) {
              _debouncer.call(() => setState(() => searchText = value));
            },
          ),
        ),
      ),
    );
  }

  // 선택된 친구 리스트
  Widget _buildSelectedFriendList(MissionCreateState state) {
    return Container(
      height: width * 0.25,
      alignment: Alignment.centerLeft,
      child:
          state.selectedFriends.isEmpty
              ? Center(
                child: Text(
                  '친구를 선택해 주세요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.selectedFriends.length,
                itemBuilder: (context, index) {
                  final friend = state.selectedFriends[index];
                  return _selectedFriendItem(
                    friend,
                    // () => notifier.toggleSelection(friend),
                    () => _toggleFriends(friend),
                  );
                },
              ),
    );
  }

  // 선택된 친구 아이템
  Widget _selectedFriendItem(FriendProfile profile, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                child: ProfileImageView(
                  size: width * 0.16,
                  profileImageUrl: profile.profileImageUrl!,
                ),
              ),
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.remove_circle_rounded, color: kGrey),
              ),
            ],
          ),
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 전체 친구 목록
  Widget _buildAllFriendList(
    FriendProfilesState friendStates,
    MissionCreateSelectionNotifier notifier,
  ) {
    // 친구 없을 때
    final List<FriendProfile> friendList = friendStates.friendList;
    if (friendList.isEmpty) {
      return Center(child: Text('친구가 없습니다'));
    }
    // 친구 있을 때
    else {
      final List<FriendProfile> filterdList =
          searchText.isEmpty
              ? friendList
              : friendList.where((friend) {
                final friendName = friend.displayName.toLowerCase();
                final query = searchText.toLowerCase();
                return friendName.contains(query);
              }).toList();
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filterdList.length,
        itemBuilder:
            (context, index) => _friendListItem(filterdList[index], notifier),
      );
    }
  }

  // 친구 리스트 아이템
  Widget _friendListItem(
    FriendProfile profile,
    MissionCreateSelectionNotifier notifier,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        vertical: width * 0.01,
        horizontal: width * 0.05,
      ),
      title: _friendInfo(profile),
      visualDensity: const VisualDensity(vertical: 4),
      trailing: _friendCheckbox(
        notifier.isSelected(profile),
        ((_) => notifier.toggleSelection(profile)),
      ),
      onTap: () => notifier.toggleSelection(profile),
    );
  }

  // 친구 프로필 이미지, 이름, 상태 메시지
  Widget _friendInfo(FriendProfile profile) {
    return Row(
      children: [
        ProfileImageView(
          size: width * 0.16,
          profileImageUrl: profile.profileImageUrl!,
        ),
        SizedBox(width: width * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              profile.statusMessage == ''
                  ? SizedBox.shrink()
                  : Text(
                    profile.statusMessage!,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  // 체크 박스
  Widget _friendCheckbox(bool isSelected, ValueChanged<bool?>? onChanged) {
    return Transform.scale(
      scale: width * 0.0028,
      child: Checkbox(
        checkColor: Colors.black,
        fillColor: WidgetStateColor.resolveWith((state) {
          if (state.contains(WidgetState.selected)) {
            return kYellow;
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
