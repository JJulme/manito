/// 자동 응답 모델
///
/// 마니또가 미션 기한까지 아무것도 작성하지 못했을 때 자동으로 제공되는 응답 메시지를 나타냅니다.
/// 이 모델은 서버로부터 오는 JSON 데이터가 항상 리스트 형태일 때 사용됩니다.
class AutoReply {
  /// 자동 응답 메시지 내용. 이 필드는 필수입니다.
  final String reply;

  /// (현재는 구현하지 않았음)
  /// 자동 응답과 함께 표시될 이미지 URL.
  /// 이미지가 없는 경우 빈 문자열(`''`)이 될 수 있습니다. 이 필드는 필수입니다.
  late String replyImageUrl;

  /// 새로운 [AutoReply] 인스턴스를 생성합니다.
  ///
  /// [reply], [replyImageUrl]은 필수 필드입니다.
  AutoReply({required this.reply, required this.replyImageUrl});

  /// JSON 리스트로부터 [AutoReply] 인스턴스를 생성하는 팩토리 생성자.
  ///
  /// [jsonList]: 서버로부터 받은 JSON 데이터 리스트.
  ///             이 리스트가 비어있지 않다면, 첫 번째 항목(인덱스 0)이 실제 자동 응답 데이터를 포함한다고 가정합니다.
  ///
  /// 만약 리스트가 비어 있을 경우, 특정 기본 메시지와 빈 이미지 URL을 가진
  /// [AutoReply] 인스턴스를 반환합니다.
  factory AutoReply.fromJson(List<dynamic> json) {
    // 비어 있다면
    if (json.isEmpty) {
      return AutoReply(reply: '미션을 성공 못해서 미안해요..ㅠㅠ', replyImageUrl: '');
    }
    // 들어있다면
    else {
      return AutoReply(
        reply: json[0]['reply'] as String,
        replyImageUrl: json[0]['reply_image_url'] ?? '',
      );
    }
  }
}
