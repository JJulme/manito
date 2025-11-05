import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/manito/manito.dart';
import 'package:manito/features/manito/manito_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/profiles/profile_provider.dart';
import 'package:manito/main.dart';
import 'package:manito/share/common_dialog.dart';
import 'package:manito/share/constants.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/profile_item.dart';
import 'package:manito/core/custom_icons.dart';
import 'package:manito/widgets/timer.dart';

class ManitoProposeScreen extends ConsumerStatefulWidget {
  final ManitoPropose propose;
  const ManitoProposeScreen({super.key, required this.propose});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ManitoProposeScreenState();
}

class _ManitoProposeScreenState extends ConsumerState<ManitoProposeScreen> {
  late final StateNotifierProvider<ManitoProposeNotifier, ManitoProposeState>
  _manitoProposeProvider;
  String? selectedContent;
  @override
  void initState() {
    super.initState();
    _manitoProposeProvider = createManitoProposeProvider(widget.propose);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(_manitoProposeProvider.notifier)
          .getPropose(context.locale.languageCode);
    });
  }

  void _selectedContentButton(String contentId) {
    setState(() => selectedContent = contentId);
  }

  void _showAcceptMissionDialog() async {
    if (selectedContent == null) {
      customToast(msg: '미션을 선택해 주세요.');
      return;
    }
    final result = await DialogHelper.showConfirmDialog(
      context,
      message: '미션 수락?',
    );
    if (result!) {
      ref.read(_manitoProposeProvider.notifier).acceptPropose(selectedContent!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_manitoProposeProvider);
    // final notifier = ref.read(_manitoProposeProvider.notifier);
    final FriendProfile? profile = ref
        .read(friendProfilesProvider.notifier)
        .searchFriendProfile(widget.propose.creatorId);

    ref.listen(_manitoProposeProvider, (previous, next) {
      if (previous!.isLoading == true &&
          previous.propose!.isDetailLoaded == true &&
          next.isLoading == false &&
          next.error == null) {
        context.pop(true);
      }
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: ${next.error}')));
      }
    });

    return Scaffold(
      appBar: SubAppbar(
        title: Text(
          "mission_propose_screen.title",
          style: Theme.of(context).textTheme.headlineMedium,
          overflow: TextOverflow.ellipsis,
        ).tr(namedArgs: {"nickname": profile!.displayName}),
      ),
      body: SafeArea(
        child:
            state.pageLoading
                ? Center(child: CircularProgressIndicator())
                : _buildBody(profile, state),
      ),
    );
  }

  // 바디
  Widget _buildBody(FriendProfile profile, ManitoProposeState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: width * 0.03),
        ProfileItem(
          profileImageUrl: profile.profileImageUrl!,
          name: profile.displayName,
          statusMessage: profile.statusMessage!,
        ),
        SizedBox(height: width * 0.03),
        _buildProposeDetail(state),
        SizedBox(height: width * 0.03),
        Wrap(
          children:
              state.propose!.randomContents!.map((e) {
                return _buildMissionItem(
                  e.content,
                  selectedContent == e.id,
                  () => _selectedContentButton(e.id),
                );
              }).toList(),
        ),
        Spacer(),
        _buildBottomButton(state),
      ],
    );
  }

  // 유형, 기간
  Widget _buildProposeDetail(ManitoProposeState state) {
    final String deadline = DateFormat(
      'yy.MM.dd HH:mm',
    ).format(state.propose!.deadline!);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03),
      child: Column(
        children: [
          Container(
            height: width * 0.15,
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(0.02 * width),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      '유 형',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Icon(iconMap[state.propose!.contentType]),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: width * 0.03),
          Container(
            height: width * 0.15,
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(0.02 * width),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      '기 간',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      '~ $deadline',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 선택할 미션 아이템
  Widget _buildMissionItem(String text, bool isSelected, VoidCallback onTap) {
    final textColor = isSelected ? Colors.black : Colors.grey.shade400;
    final iconColor = isSelected ? Colors.black : Colors.white70;
    final borderColor = isSelected ? Colors.grey : Colors.grey.shade400;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 0.15 * width,
        margin: EdgeInsets.fromLTRB(
          0.03 * width,
          0,
          0.03 * width,
          0.03 * width,
        ),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(0.02 * width),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Icon(
                CustomIcons.check,
                size: 0.07 * width,
                color: iconColor,
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                child: AutoSizeText(
                  text,
                  minFontSize: 10,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 0.05 * width, color: textColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 하단 수락 버튼
  Widget _buildBottomButton(ManitoProposeState state) {
    return Container(
      width: double.infinity,
      height: width * 0.13,
      margin: EdgeInsets.symmetric(
        vertical: width * 0.04,
        horizontal: width * 0.04,
      ),
      child: ElevatedButton(
        // onPressed: state.isLoading ? null : () => _updateMissionGuess(notifier),
        onPressed: () => _showAcceptMissionDialog(),
        child:
            state.isLoading
                ? CircularProgressIndicator()
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "mission_propose_screen.accept_btn",
                      style: Theme.of(context).textTheme.titleMedium,
                    ).tr(),
                    TimerWidget(
                      targetDateTime: state.propose!.acceptDeadline,
                      fontSize: width * 0.07,
                      onTimerComplete: () async {
                        context.pop();
                        customToast(msg: '수락 시간 만료');
                      },
                    ),
                  ],
                ),
      ),
    );
  }
}
