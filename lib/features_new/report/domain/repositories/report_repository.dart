abstract class ReportRepository {
  Future<String> reportUser(String reportType);
  Future<String> reportPost(String postId, String reportType);
}
