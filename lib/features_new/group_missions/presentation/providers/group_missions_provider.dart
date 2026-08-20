import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features_new/group_missions/domain/entities/group_mission_entity.dart';
import 'package:manito/features_new/group_missions/domain/repositories/repository_provider.dart';

final groupMissionsProvider =
    AsyncNotifierProvider<GroupMissionsNotifier, List<GroupMissionEntity>>(
      GroupMissionsNotifier.new,
    );

class GroupMissionsNotifier extends AsyncNotifier<List<GroupMissionEntity>> {
  @override
  Future<List<GroupMissionEntity>> build() async {
    final repository = ref.read(groupMissionsRepositoryProvider);
    await repository.fetchMyGroupMission();
    return const [];
  }
}
