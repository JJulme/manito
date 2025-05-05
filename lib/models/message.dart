class Message {
  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.postId,
  });
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String postId;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      postId: json['post_id'],
    );
  }
}
