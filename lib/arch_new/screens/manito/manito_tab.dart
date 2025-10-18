import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/arch_new/features/badge/badge_provider.dart';
import 'package:manito/arch_new/features/manito/manito.dart';
import 'package:manito/arch_new/features/manito/manito_provider.dart';
import 'package:manito/arch_new/features/profiles/profile.dart';
import 'package:manito/arch_new/widgets/tab_container.dart';
import 'package:manito/custom_icons.dart';
import 'package:manito/widgets/mission/custom_slide.dart';
import 'package:manito/widgets/mission/timer.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';

class ManitoTab extends ConsumerStatefulWidget {
  const ManitoTab({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ManitoTabState();
}

class _ManitoTabState extends ConsumerState<ManitoTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(manitoListProvider.notifier)
          .refreshAll(context.locale.languageCode);
    });
  }

  // 마니또 제안 화면 이동
  void _toProposeScreen(ManitoPropose propose) async {
    ref
        .read(badgeProvider.notifier)
        .resetBadgeCount('mission_propose', typeId: propose.missionId!);
    final result = await context.push('/manito_propose', extra: propose);
    if (result == true) {
      if (!mounted) return;
      ref
          .read(manitoListProvider.notifier)
          .refreshAll(context.locale.languageCode);
    }
  }

  // 마니또 포스트 작성 화면 이동
  void _toManitoPostScreen(ManitoAccept manitoAccept) {
    context.push('/manito_post', extra: manitoAccept);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final double width = MediaQuery.of(context).size.width;
    final state = ref.watch(manitoListProvider);
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (state.isEmpty) {
      return Center(child: Text('진행중인 미션이 없습니다.'));
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: width * 0.03),
          _buildProposeList(width, state.proposeList),
          _buildGuessList(width, state.guessList),
          _buildAcceptList(width, state.acceptList),
        ],
      ),
    );
  }

  Widget _buildProposeList(double width, List<ManitoPropose> proposeList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: proposeList.length,
      itemBuilder:
          (context, index) => _buildProposeItem(width, proposeList[index]),
    );
  }

  Widget _buildGuessList(double width, List<ManitoGuess> guessList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: guessList.length,
      itemBuilder: (context, index) => _buildGuessItem(width, guessList[index]),
    );
  }

  Widget _buildAcceptList(double width, List<ManitoAccept> acceptList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: acceptList.length,
      itemBuilder:
          (context, index) => _buildAcceptItem(width, acceptList[index]),
    );
  }

  Widget _buildProposeItem(double width, ManitoPropose manitoPropose) {
    return TabContainer(
      child: InkWell(
        onTap: () => _toProposeScreen(manitoPropose),
        child: Row(
          children: [
            Icon(Icons.error_sharp, size: width * 0.07, color: Colors.amber),
            Text(
              "manito_screen.propose",
              style: Theme.of(context).textTheme.titleSmall,
            ).tr(),
            Spacer(),
            TimerWidget(
              targetDateTime: manitoPropose.acceptDeadline,
              fontSize: width * 0.07,
              onTimerComplete:
                  () => ref
                      .read(manitoListProvider.notifier)
                      .refreshAll(context.locale.languageCode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuessItem(double width, ManitoGuess manitoGuess) {
    final FriendProfile profile = manitoGuess.creatorProfile;
    return TabContainer(
      child: Row(
        children: [
          ProfileImageView(
            size: width * 0.14,
            profileImageUrl: profile.profileImageUrl!,
          ),
          SizedBox(width: width * 0.02),
          Expanded(
            child: Text(
              "${profile.nickname} ${context.tr("manito_screen.guessing_manito")}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptItem(double width, ManitoAccept manitoAccept) {
    return CustomSlide(
      mainWidget: TabContainer(
        child: Row(
          children: [
            Icon(
              Icons.run_circle_sharp,
              size: width * 0.07,
              color: Colors.deepOrange,
            ),
            SizedBox(width: width * 0.02),
            Text('진행중 미션', style: Theme.of(context).textTheme.titleSmall),
            Spacer(),
            Icon(CustomIcons.hourglass, size: width * 0.055),
            SizedBox(width: width * 0.01),
            TimerWidget(
              targetDateTime: manitoAccept.deadline,
              fontSize: width * 0.07,
              onTimerComplete:
                  () => ref
                      .read(manitoListProvider.notifier)
                      .fetchAcceptList(context.locale.languageCode),
            ),
          ],
        ),
      ),
      subWidget: TabContainer(
        child: Row(
          children: [
            Tooltip(
              showDuration: const Duration(days: 1),
              triggerMode: TooltipTriggerMode.tap,
              message: manitoAccept.creatorProfile.displayName,
              child: ProfileImageView(
                size: width * 0.135,
                profileImageUrl: manitoAccept.creatorProfile.profileImageUrl!,
              ),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: AutoSizeText(
                manitoAccept.content,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              onPressed: () => _toManitoPostScreen(manitoAccept),
              icon: Icon(Icons.edit_note_rounded, size: width * 0.1),
            ),
          ],
        ),
      ),
    );
  }
}
