class AutoReply {
  final String reply;
  late String replyImageUrl;

  AutoReply({
    required this.reply,
    required this.replyImageUrl,
  });

  factory AutoReply.fromJson(dynamic json) {
    // 비어 있다면
    if (json is List && json.isEmpty) {
      return AutoReply(
        reply: '미션을 성공 못해서 미안해요..ㅠㅠ',
        replyImageUrl: '',
      );
    }
    // 들어있다면
    else {
      return AutoReply(
        reply: json[0]['reply'],
        replyImageUrl: json[0]['reply_image_url'] ?? '',
      );
    }
  }
}
