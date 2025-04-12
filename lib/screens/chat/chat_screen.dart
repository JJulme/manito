import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/models/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});

  final _chatController = Get.put(ChatController());

  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // double di = sqrt(pow(MediaQuery.of(context).size.width, 2) +
    //     pow(MediaQuery.of(context).size.height, 2));
    double di = sqrt(pow(Get.width, 2) + pow(Get.height, 2));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _chatController.friendNickname,
            style: Get.textTheme.headlineMedium,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 채팅창
              Expanded(
                child: Obx(
                  () {
                    return ListView.builder(
                      itemCount: _chatController.chattings.length,
                      itemBuilder: (context, index) {
                        final message = _chatController.chattings[index];
                        return ListTile(
                          title: Text(message.content),
                          subtitle: Text(message.senderId),
                        );
                      },
                    );
                  },
                ),
              ),
              // 하단 채팅 입력창
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(0.01 * di),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _textController,
                          keyboardType: TextInputType.text,
                          maxLines: null,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.all(0),
                        icon: Icon(Icons.send_rounded),
                        onPressed: () {
                          _chatController.sendMessage(_textController.text);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatController extends GetxController {
  final _supabase = Supabase.instance.client;
  late String friendId;
  late String friendNickname;
  late String? friendProfileImage;
  var chattings = <Message>[].obs;
  late final RealtimeChannel channel;

  @override
  void onInit() async {
    super.onInit();
    friendId = Get.arguments[0];
    friendNickname = Get.arguments[1];
    friendProfileImage = Get.arguments[2];
    await fetchMessages();
  }

  void initChannel() {
    _supabase
        .channel('public:chat_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            debugPrint(payload.toString());
          },
        )
        .subscribe();
  }

  /// 채팅 내용 가져오기
  Future<void> fetchMessages() async {
    String userId = _supabase.auth.currentUser!.id;
    try {
      final data = await _supabase
          .from('chat_messages')
          .select()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .or('sender_id.eq.$friendId,receiver_id.eq.$friendId')
          .order('created_at', ascending: true);
      chattings.value = data.map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchMessages Error: $e');
    }
  }

  /// 채팅 보내기
  Future<void> sendMessage(String message) async {
    try {
      await _supabase.from('chat_messages').insert({
        'sender_id': _supabase.auth.currentUser!.id,
        'receiver_id': friendId,
        'content': message,
      });
    } catch (e) {
      debugPrint('sendMessage Error: $e');
    }
  }
}
