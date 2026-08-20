abstract class GroupMissionsRepository {
  Future<void> fetchMyGroupMission();
  Future<String> createGroupRoom({
    required String title,
    required String contentType,
    required String limitTime,
  });
}
