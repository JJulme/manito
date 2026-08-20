abstract class MissionsRepository {
  Future<List<Map<String, dynamic>>> fetchMyMissionsData();
  Future<void> createSingleMission({
    required List<String> friendIds,
    required String contentType,
    required DateTime acceptDeadline,
    required DateTime deadline,
  });
  Future<void> createGroupMission({
    required List<String> friendIds,
    required String contentType,
    required DateTime deadline,
  });
  Future<String> createGroupRoom({
    required String title,
    required String contentType,
    required String limitTime,
  });
  Future<void> updateMissionGuess(String missionId, String text);
}
