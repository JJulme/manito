import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/badge/badge_provider.dart';
import 'package:manito/features/missions/mission.dart';
import 'package:manito/features/missions/mission_provider.dart';
import 'package:manito/features/posts/post_provider.dart';
import 'package:manito/share/constants.dart';
import 'package:manito/share/custom_badge.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/widgets/tab_container.dart';
import 'package:manito/core/constants.dart';
import 'package:manito/core/custom_icons.dart';
import 'package:manito/widgets/custom_slide.dart';
import 'package:manito/widgets/timer.dart';
import 'package:manito/widgets/profile_image_view.dart';

class MissionTab extends ConsumerStatefulWidget {
  const MissionTab({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MissionTabState();
}

class _MissionTabState extends ConsumerState<MissionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(missionListProvider.notifier).fetchMyMissions();
    });
  }

  // 추측화면으로 이동
  void _toGuessScreen(MyMission mission) async {
    final result = await context.push('/mission_guess', extra: mission);
    if (result == true) {
      // 뱃지 초기화, 미션 리스트 새로고침, 포스트 새로고침
      await Future.wait([
        ref
            .read(badgeProvider.notifier)
            .resetBadgeCount('mission_guess', typeId: mission.id),
        ref.read(missionListProvider.notifier).fetchMyMissions(),
        ref.read(postsProvider.notifier).fetchPosts(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final double width = MediaQuery.of(context).size.width;
    final state = ref.watch(missionListProvider);
    final notifier = ref.read(missionListProvider.notifier);
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (state.allMissions.isEmpty) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () => notifier.fetchMyMissions(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: width,
              child: Center(child: Text('미션을 만들어 보세요!')),
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(
          width,
          state,
          notifier,
        ),
      );
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchMyMissions(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: width * 0.03),
              _buildCompleteMissionList(width, state.completeMyMissions),
              _buildAcceptMissionList(width, state.acceptMyMissions),
              _buildPendingMissionList(width, state.pendingMyMissions),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(width, state, notifier),
    );
  }

  // 미션 생성 버튼
  Widget _buildFloatingActionButton(
    double width,
    MyMissionState state,
    MissionListNotifier notifier,
  ) {
    return FloatingActionButton(
      elevation: 2,
      shape: const CircleBorder(),
      backgroundColor: kYellow,
      child: SvgPicture.asset(
        'assets/icons/star_add2.svg',
        width: width * 0.075,
        colorFilter: ColorFilter.mode(Colors.grey.shade900, BlendMode.srcIn),
      ),
      onPressed: () async {
        if (state.allMissions.length >= 3) {
          customToast(width: width, msg: '미션은 최대 3개까지 생성 가능합니다.');
        } else {
          final result = await context.push('/mission_create');
          if (result == true) notifier.fetchMyMissions();
        }
      },
    );
  }

  // 완료 미션 리스트
  Widget _buildCompleteMissionList(double width, List<MyMission> missions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: missions.length,
      itemBuilder:
          (context, index) => _buildCompleteMissionItem(width, missions[index]),
    );
  }

  // 진행중 미션 리스트
  Widget _buildAcceptMissionList(double width, List<MyMission> missions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: missions.length,
      itemBuilder:
          (context, index) => _buildAcceptMissionItem(width, missions[index]),
    );
  }

  // 대기중 미션 리스트
  Widget _buildPendingMissionList(double width, List<MyMission> missions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: missions.length,
      itemBuilder:
          (context, index) => _buildPendingMissionItem(width, missions[index]),
    );
  }

  // 완료 미션 아이템
  Widget _buildCompleteMissionItem(double width, MyMission mission) {
    final badgeState = ref.watch(badgeProvider).valueOrNull;
    return Stack(
      children: [
        TabContainer(
          child: InkWell(
            onTap: () => _toGuessScreen(mission),
            child: Row(
              children: [
                Icon(Icons.check_circle_sharp, color: Colors.green),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    '마니또 미션 완료!',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: width * 0.03,
          right: width * 0.06,
          child: customBadgeIconWithLabel(
            badgeState!.getBadgeCountByTypeId('mission_guess', mission.id),
          ),
        ),
      ],
    );
  }

  // 대기중 미션 아이템
  Widget _buildPendingMissionItem(double width, MyMission mission) {
    return CustomSlide(
      mainWidget: TabContainer(
        child: Row(
          children: [
            Icon(Icons.help_sharp, size: width * 0.07, color: Colors.amber),
            SizedBox(width: width * 0.02),
            Text('수락 대기중 미션', style: Theme.of(context).textTheme.titleSmall),
            Spacer(),
            Icon(CustomIcons.hourglass, size: width * 0.055),
            SizedBox(width: width * 0.01),
            TimerWidget(
              targetDateTime: mission.acceptDeadline!,
              fontSize: width * 0.07,
              onTimerComplete:
                  () =>
                      ref.read(missionListProvider.notifier).fetchMyMissions(),
            ),
          ],
        ),
      ),
      subWidget: TabContainer(
        child: Row(
          children: [
            Icon(
              iconMap[mission.contentType],
              size: width * 0.07,
              color: Colors.grey.shade800,
            ),
            SizedBox(width: width * 0.03),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: mission.friendProfiles.length,
              separatorBuilder:
                  (context, index) => SizedBox(width: width * 0.02),
              itemBuilder: (context, index) {
                final profile = mission.friendProfiles[index];
                return Tooltip(
                  showDuration: const Duration(days: 1),
                  triggerMode: TooltipTriggerMode.tap,
                  message: profile.displayName,
                  child: ProfileImageView(
                    size: width * 0.135,
                    profileImageUrl: profile.profileImageUrl!,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 진행중 미션 아이템
  Widget _buildAcceptMissionItem(double width, MyMission mission) {
    final badgeState = ref.watch(badgeProvider).valueOrNull;
    return CustomSlide(
      onTap:
          () => ref
              .read(badgeProvider.notifier)
              .resetBadgeCount('mission_accept', typeId: mission.id),
      mainWidget: Stack(
        children: [
          TabContainer(
            child: Row(
              children: [
                Icon(
                  Icons.error_sharp,
                  size: width * 0.07,
                  color: Colors.deepOrange,
                ),
                SizedBox(width: width * 0.02),
                Text('진행중 미션', style: Theme.of(context).textTheme.titleSmall),
                Spacer(),
                Icon(CustomIcons.hourglass, size: width * 0.055),
                SizedBox(width: width * 0.01),
                TimerWidget(
                  targetDateTime: mission.deadline,
                  fontSize: width * 0.07,
                  onTimerComplete:
                      () =>
                          ref
                              .read(missionListProvider.notifier)
                              .fetchMyMissions(),
                ),
              ],
            ),
          ),
          Positioned(
            top: width * 0.03,
            right: width * 0.06,
            child: customBadgeIconWithLabel(
              badgeState!.getBadgeCountByTypeId('mission_accept', mission.id),
            ),
          ),
        ],
      ),

      subWidget: TabContainer(
        child: Row(
          children: [
            Icon(
              iconMap[mission.contentType],
              size: width * 0.07,
              color: Colors.grey.shade800,
            ),
            SizedBox(width: width * 0.03),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: mission.friendProfiles.length,
              separatorBuilder:
                  (context, index) => SizedBox(width: width * 0.02),
              itemBuilder: (context, index) {
                final profile = mission.friendProfiles[index];
                return Tooltip(
                  showDuration: const Duration(days: 1),
                  triggerMode: TooltipTriggerMode.tap,
                  message: profile.displayName,
                  child: ProfileImageView(
                    size: width * 0.135,
                    profileImageUrl: profile.profileImageUrl!,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
