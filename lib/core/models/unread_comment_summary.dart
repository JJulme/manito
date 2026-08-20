class UnreadCommentSummary {
  final int total;
  final Map<String, int> roomCounts;
  final Map<int, int> recordCounts;

  const UnreadCommentSummary({
    this.total = 0,
    this.roomCounts = const {},
    this.recordCounts = const {},
  });

  factory UnreadCommentSummary.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] as num?)?.toInt() ?? 0;

    final roomMap = <String, int>{};
    if (json['rooms'] is Map) {
      (json['rooms'] as Map).forEach((k, v) {
        roomMap[k.toString()] = (v as num).toInt();
      });
    }

    final recordMap = <int, int>{};
    if (json['records'] is Map) {
      (json['records'] as Map).forEach((k, v) {
        final rId = int.tryParse(k.toString());
        if (rId != null) {
          recordMap[rId] = (v as num).toInt();
        }
      });
    }

    return UnreadCommentSummary(
      total: total,
      roomCounts: roomMap,
      recordCounts: recordMap,
    );
  }
}
