import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/badge/badge_provider.dart';
import 'package:manito/features/manito/manito.dart';
import 'package:manito/features/manito/manito_provider.dart';
import 'package:manito/features/profiles/profile.dart';
import 'package:manito/features/theme/theme.dart';
import 'package:manito/main.dart';
import 'package:manito/share/custom_badge.dart';
import 'package:manito/widgets/tab_container.dart';
import 'package:manito/core/custom_icons.dart';
import 'package:manito/widgets/custom_slide.dart';
import 'package:manito/widgets/timer.dart';
import 'package:manito/widgets/profile_image_view.dart';

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
        .resetBadgeCount('mission_propose', typeId: propose.id);
    final result = await context.push('/manito_propose', extra: propose);
    // 수락했을 경우 새로고침
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
    final state = ref.watch(manitoListProvider);
    final notifier = ref.read(manitoListProvider.notifier);

    return state.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => RefreshIndicator(
            onRefresh: () => notifier.refreshAll(context.locale.languageCode),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: width,
                child: Center(child: Text('데이터를 가져오는데 오류가 발생했습니다.')),
              ),
            ),
          ),
      data: (data) {
        if (data.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => notifier.refreshAll(context.locale.languageCode),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: width,
                child: const Center(child: Text('진행중인 미션이 없습니다.')),
              ),
            ),
          );
        } else {
          return RefreshIndicator(
            onRefresh: () => notifier.refreshAll(context.locale.languageCode),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: width * 0.03),
                  _buildProposeList(data.proposeList),
                  _buildGuessList(data.guessList),
                  _buildAcceptList(data.acceptList),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // 제안 리스트
  Widget _buildProposeList(List<ManitoPropose> proposeList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: proposeList.length,
      itemBuilder: (context, index) => _buildProposeItem(proposeList[index]),
    );
  }

  // 추측 리스트
  Widget _buildGuessList(List<ManitoGuess> guessList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: guessList.length,
      itemBuilder: (context, index) => _buildGuessItem(guessList[index]),
    );
  }

  // 수락 리스트
  Widget _buildAcceptList(List<ManitoAccept> acceptList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: acceptList.length,
      itemBuilder: (context, index) => _buildAcceptItem(acceptList[index]),
    );
  }

  // 제안온 미션 아이템
  Widget _buildProposeItem(ManitoPropose manitoPropose) {
    final badgeState = ref.watch(badgeProvider).valueOrNull;
    return Stack(
      children: [
        TabContainer(
          child: InkWell(
            onTap: () => _toProposeScreen(manitoPropose),
            child: Row(
              children: [
                Icon(Icons.error_sharp, size: width * 0.07, color: kYellow),
                Text(
                  "manito_screen.propose",
                  style: Theme.of(context).textTheme.titleMedium,
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
        ),
        Positioned(
          top: width * 0.03,
          right: width * 0.06,
          child: customBadgeIconWithLabel(
            badgeState!.getBadgeCountByTypeId(
              'mission_propose',
              manitoPropose.id,
            ),
          ),
        ),
      ],
    );
  }

  // 미션 추측중인 아이템
  Widget _buildGuessItem(ManitoGuess manitoGuess) {
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
              "${profile.displayName} ${context.tr("manito_screen.guessing_manito")}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  // 수락한 미션 아이템
  Widget _buildAcceptItem(ManitoAccept manitoAccept) {
    return CustomSlide(
      mainWidget: TabContainer(
        child: Row(
          children: [
            Icon(
              Icons.run_circle_sharp,
              size: width * 0.07,
              color: kDeepOrange,
            ),
            SizedBox(width: width * 0.02),
            Text('진행중 미션', style: Theme.of(context).textTheme.titleMedium),
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
                style: Theme.of(context).textTheme.titleMedium,
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
