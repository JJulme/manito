import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/util/app_logger.dart';
import '../data/chat_repository.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/chat_room_model.dart';

/// 1. 전체 채팅방 목록 프로바이더 (실시간 갱신 포함)
final chatRoomsProvider = FutureProvider.autoDispose<List<ChatRoomModel>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  final supabase = ref.watch(supabaseProvider);

  // 실시간 변경 구독 (새 메시지 도착, 멤버 변경 시 목록 자동 갱신)
  final channel = supabase.channel('public:chat_rooms_global')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_messages',
        callback: (_) {
          AppLogger.i('Realtime chat_messages update -> invalidating chatRoomsProvider', tag: 'CHAT');
          ref.invalidateSelf();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_members',
        callback: (_) {
          AppLogger.i('Realtime chat_members update -> invalidating chatRoomsProvider', tag: 'CHAT');
          ref.invalidateSelf();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_rooms',
        callback: (_) {
          ref.invalidateSelf();
        },
      );

  channel.subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
  });

  return repo.getChatRooms();
});

/// 2. 전체 안 읽은 채팅 메시지 총합 프로바이더 (바텀 네비 뱃지용)
final totalUnreadChatCountProvider = Provider.autoDispose<int>((ref) {
  final roomsAsync = ref.watch(chatRoomsProvider);
  return roomsAsync.when(
    data: (rooms) => rooms.fold<int>(0, (sum, room) => sum + room.unreadCount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 3. 특정 채팅방 상세 정보 프로바이더
final chatRoomDetailsProvider = FutureProvider.autoDispose.family<ChatRoomModel?, String>((ref, roomId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getChatRoom(roomId);
});

/// 4. 특정 채팅방의 실시간 메시지 스트림 및 '1' 미읽음 실시간 반영 노티파이어
final chatMessagesProvider = StateNotifierProvider.autoDispose.family<ChatMessagesNotifier, AsyncValue<List<ChatMessageModel>>, String>((ref, roomId) {
  final repo = ref.watch(chatRepositoryProvider);
  final supabase = ref.watch(supabaseProvider);
  return ChatMessagesNotifier(repo, supabase, roomId);
});

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessageModel>>> {
  final ChatRepository _repo;
  final SupabaseClient _supabase;
  final String roomId;
  RealtimeChannel? _channel;

  ChatMessagesNotifier(this._repo, this._supabase, this.roomId) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final initialMessages = await _repo.getMessages(roomId);
      if (!mounted) return;
      state = AsyncValue.data(initialMessages);

      // 내가 방에 들어왔으므로 읽음 처리
      await _repo.markChatRoomAsRead(roomId);
      if (!mounted) return;

      _subscribeRealtime();
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  void _subscribeRealtime() {
    if (!mounted) return;
    _channel = _supabase.channel('chat_room:$roomId')
        // A. 새 메시지 수신 (INSERT)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) async {
            if (!mounted) return;
            AppLogger.i('New message arrived in room $roomId: ${payload.newRecord['id']}', tag: 'CHAT');
            // 메시지 발송자 프로필 및 미읽음 계산을 위해 재동기화 또는 즉시 반영
            await _refreshMessages();
            if (!mounted) return;
            // 화면을 보고 있으므로 즉시 읽음 처리
            await _repo.markChatRoomAsRead(roomId);
          },
        )
        // B. 상대방이 읽었을 때 (UPDATE chat_members.last_read_at) -> '1' 실시간 사라짐!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) async {
            if (!mounted) return;
            AppLogger.i('Member last_read_at updated in room $roomId -> recalculating unread counts', tag: 'CHAT');
            await _refreshMessages();
          },
        );

    _channel?.subscribe();
  }

  Future<void> _refreshMessages() async {
    try {
      final updated = await _repo.getMessages(roomId);
      if (!mounted) return;
      state = AsyncValue.data(updated);
    } catch (e) {
      AppLogger.w('Failed to refresh messages: $e', tag: 'CHAT');
    }
  }

  /// 로컬에 낙관적(Optimistic) 즉시 추가 후 서버 전송
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _repo.sendMessage(
        roomId: roomId,
        content: text.trim(),
        type: ChatMessageType.text,
      );
    } catch (e) {
      AppLogger.e('Failed to send text message: $e', tag: 'CHAT');
      rethrow;
    }
  }

  /// 내 사진 이모티콘 전송
  Future<void> sendEmoticonMessage(String emoticonId) async {
    try {
      await _repo.sendMessage(
        roomId: roomId,
        emoticonId: emoticonId,
        type: ChatMessageType.emoticon,
      );
    } catch (e) {
      AppLogger.e('Failed to send emoticon: $e', tag: 'CHAT');
      rethrow;
    }
  }

  /// 사진 묶어 전송
  Future<void> sendImagesMessage(List<File> imageFiles) async {
    if (imageFiles.isEmpty) return;
    try {
      final urls = await _repo.uploadChatImages(imageFiles);
      if (urls.isNotEmpty) {
        await _repo.sendMessage(
          roomId: roomId,
          imageUrls: urls,
          type: ChatMessageType.image,
        );
      }
    } catch (e) {
      AppLogger.e('Failed to send image messages: $e', tag: 'CHAT');
      rethrow;
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
