import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/core/custom_icons.dart';
import 'package:manito/features/missions/mission.dart';
import 'package:manito/features/missions/mission_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/common_dialog.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/friend_grid_list.dart';

class MissionCreateScreen extends ConsumerStatefulWidget {
  const MissionCreateScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MissionCreateScreenState();
}

class _MissionCreateScreenState extends ConsumerState<MissionCreateScreen> {
  // 토글 버튼
  int _selectedType = 0;
  int _selectedPeriod = 0;

  // 미선 생성 다이얼로그
  void _showMissionCreationDialog(
    MissionCreateState state,
    MissionCreateNotifier notifier,
  ) async {
    if (state.confirmedFriends.length < 2) {
      customToast(msg: '친구를 2명 이상 선택해 주세요.');
    } else {
      final result = await DialogHelper.showConfirmDialog(
        context,
        title: context.tr("mission_create_screen.dialog_title"),
        message: context.tr("mission_create_screen.dialog_message"),
      );
      if (result == true) {
        await notifier.createMission(_selectedType, _selectedPeriod);
        if (!mounted) return;
        context.pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionCreateProvider);
    final notifier = ref.read(missionCreateProvider.notifier);
    return Scaffold(
      appBar: SubAppbar(
        title: Text('미션 만들기'),
        actions: [_appbarActions(state, notifier)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('타입'),
              _buildTypeToggle(),
              Divider(),
              _buildSectionTitle('기간'),
              _buildPeriodToggle(),
              Divider(),
              _buildSectionTitle('친구'),
              _buildSelectedFriends(state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  // 미션 생성 버튼
  Widget _appbarActions(
    MissionCreateState state,
    MissionCreateNotifier notifier,
  ) {
    return TextButton(
      child: Text('완료', style: TextTheme.of(context).bodyMedium),
      onPressed: () => _showMissionCreationDialog(state, notifier),
    );
  }

  // 타이틀 위젯
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.all(width * 0.05),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  // 타입 토글 버튼
  Widget _buildTypeToggle() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: ToggleButtons(
        fillColor: Colors.yellowAccent[300],
        selectedColor: Colors.yellowAccent[900],
        selectedBorderColor: Colors.yellowAccent[900],
        borderRadius: BorderRadius.circular(width * 0.01),
        constraints: BoxConstraints(
          minHeight: width * 0.25,
          minWidth: (width - width * 0.1) / 3,
        ),
        isSelected: [
          _selectedType == 0,
          _selectedType == 1,
          _selectedType == 2,
        ],
        onPressed: (index) => setState(() => _selectedType = index),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sunny),
              Text("일상", textAlign: TextAlign.center),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded),
              Text("학교", textAlign: TextAlign.center),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work),
              Text("직장", textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }

  // 기간 토글 버튼
  Widget _buildPeriodToggle() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: ToggleButtons(
        fillColor: Colors.yellowAccent[300],
        selectedColor: Colors.yellowAccent[900],
        selectedBorderColor: Colors.yellowAccent[900],
        borderRadius: BorderRadius.circular(width * 0.01),
        constraints: BoxConstraints(
          minHeight: width * 0.25,
          minWidth: (width - width * 0.1) / 2,
        ),
        isSelected: [_selectedPeriod == 0, _selectedPeriod == 1],
        onPressed: (index) => setState(() => _selectedPeriod = index),
        children: [
          Text(
            "mission_create_screen.toggle_btn_day",
            textAlign: TextAlign.center,
          ).tr(),
          Text(
            "mission_create_screen.toggle_btn_week",
            textAlign: TextAlign.center,
          ).tr(),
        ],
      ),
    );
  }

  // 친구 선택, 친구 목록
  Widget _buildSelectedFriends(
    MissionCreateState state,
    MissionCreateNotifier notifier,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: InkWell(
        onTap: () {
          notifier.updateSelectedFriends();
          context.push('/mission_friends_search');
        },
        child:
            state.confirmedFriends.isEmpty
                ? Container(
                  width: double.infinity,
                  height: width * 0.25,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(width * 0.013),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CustomIcons.user_plus,
                        size: width * 0.05,
                        color: Colors.grey.shade800,
                      ),
                      SizedBox(width: width * 0.04),
                      Text(
                        "mission_create_screen.empty_select_friends",
                        style: Theme.of(context).textTheme.bodySmall,
                      ).tr(),
                    ],
                  ),
                )
                : FriendGridList(friends: state.confirmedFriends),
      ),
    );
  }
}
