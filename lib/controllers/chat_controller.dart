import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/models/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatController extends GetxController {
  final isLoading = false.obs;
  final _supabase = Supabase.instance.client;
  late String postId;
  RealtimeChannel? _channel;
  var messages = <Message>[].obs;
  final messageTextController = TextEditingController();

  /// 초기화
  @override
  void onInit() {
    super.onInit();
    postId = Get.arguments;
    fetchExistingMessages();
    subscribToMessages();
  }

  /// 종료
  @override
  void onClose() {
    _channel?.unsubscribe();
    messageTextController.dispose();
    super.onClose();
  }

  /// 이전 채팅 목록 가져오기
  Future<void> fetchExistingMessages() async {
    isLoading.value = true;
    try {
      final data = await _supabase
          .from('chat_messages')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: false);
      messages.value = data.map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      debugPrint('_loadInitialMessages Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 채널 실시간 구독
  void subscribToMessages() {
    _channel =
        _supabase
            .channel('chat_messages:$postId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'chat_messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'post_id',
                value: postId,
              ),
              callback: _messageEventHandler,
            )
            .subscribe();
    debugPrint('채널 실시간 구독: $postId');
  }

  /// 채널 이벤트 핸들러
  void _messageEventHandler(payload) {
    debugPrint('Real-time event received: ${payload.toString()}');
    if (payload.eventType == PostgresChangeEvent.insert) {
      final newMessage = payload.newRecord;
      messages.insert(
        0,
        Message(
          id: newMessage['id'],
          postId: newMessage['post_id'],
          senderId: newMessage['sender_id'],
          content: newMessage['content'],
          createdAt: DateTime.parse(newMessage['created_at']),
        ),
      );
      debugPrint('새 채팅: ${newMessage['content']}');
    }
    // 수정 시
    else if (payload.eventType == PostgresChangeEvent.update) {
      // final updatedMessage = payload.newRecord;
      debugPrint('채팅 수정');
    }
    // 삭제 시
    else if (payload.eventType == PostgresChangeEvent.delete) {
      debugPrint('채팅 삭제');
    }
  }

  /// 댓글 공백 입력 방지
  void sendMessage() async {
    // 공백 이외의 입력값이 있다면
    if (messageTextController.text.trim().isNotEmpty) {
      // 전송
      try {
        final data = {
          "post_id": postId,
          "sender_id": _supabase.auth.currentUser!.id,
          "content": messageTextController.text,
        };
        await _supabase.from('chat_messages').insert(data);
        // 입력창 클리어
        messageTextController.clear();
      } catch (e) {
        debugPrint('sendMessage Error: $e');
      }
    }
  }
}
