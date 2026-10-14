import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manito/core/notifications/models/app_notification.dart';
import 'package:manito/core/notifications/notification_sender.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/util/app_logger.dart';
import 'models/chat_member_model.dart';
import 'models/chat_message_model.dart';
import 'models/chat_room_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final notificationSender = ref.watch(notificationSenderProvider);
  return ChatRepository(supabase, notificationSender);
});

class ChatRepository {
  final SupabaseClient _supabase;
  final NotificationSender _notificationSender;

  ChatRepository(this._supabase, this._notificationSender);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// 1. 내가 속한 활성 채팅방 목록 조회 (마지막 메시지 및 미읽음 수 포함)
  Future<List<ChatRoomModel>> getChatRooms() async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      AppLogger.i('Fetching chat rooms for user: $uid', tag: 'CHAT');

      // 1) 내가 속한 활성 room_id 목록 조회
      final myMemberships = await _supabase
          .from('chat_members')
          .select('room_id, last_read_at')
          .eq('user_id', uid)
          .eq('is_active', true);

      if ((myMemberships as List).isEmpty) {
        return [];
      }

      final roomIds = myMemberships.map((m) => m['room_id'] as String).toList();
      final Map<String, DateTime> myLastReadMap = {
        for (var m in myMemberships)
          m['room_id'] as String: m['last_read_at'] != null
              ? (DateTime.tryParse(m['last_read_at'].toString())?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0))
              : DateTime.fromMillisecondsSinceEpoch(0),
      };

      // 2) 채팅방 상세 정보 및 전체 멤버 목록 조회 (users 조인)
      final roomsData = await _supabase
          .from('chat_rooms')
          .select('''
            id,
            type,
            title,
            created_by,
            created_at,
            updated_at,
            chat_members (
              room_id,
              user_id,
              joined_at,
              last_read_at,
              is_active,
              custom_title,
              users (
                user_id,
                unique_code,
                name,
                profile_image_url,
                status_message
              )
            )
          ''')
          .inFilter('id', roomIds)
          .order('updated_at', ascending: false);

      List<ChatRoomModel> resultRooms = [];

      for (final r in roomsData as List) {
        final roomId = r['id'] as String;
        final myLastRead = myLastReadMap[roomId] ?? DateTime.fromMillisecondsSinceEpoch(0);

        // 멤버 파싱
        final membersList = (r['chat_members'] as List? ?? [])
            .map((m) => ChatMemberModel.fromJson(m as Map<String, dynamic>))
            .where((m) => m.isActive)
            .toList();

        // 3) 각 방의 마지막 메시지 조회
        final lastMsgData = await _supabase
            .from('chat_messages')
            .select('''
              id,
              room_id,
              sender_id,
              type,
              content,
              image_urls,
              emoticon_id,
              created_at,
              users (
                user_id,
                name,
                profile_image_url
              )
            ''')
            .eq('room_id', roomId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        ChatMessageModel? lastMessage;
        if (lastMsgData != null) {
          lastMessage = ChatMessageModel.fromJson(lastMsgData);
        }

        // 4) 대화 내역이 없는 빈 방은 채팅 목록에 노출하지 않음
        if (lastMessage == null) {
          continue;
        }

        // 5) 내가 안 읽은 메시지 수 계산
        final unreadCountRes = await _supabase
            .from('chat_messages')
            .select('id')
            .eq('room_id', roomId)
            .neq('sender_id', uid)
            .gt('created_at', myLastRead.toUtc().toIso8601String());

        final unreadCount = (unreadCountRes as List).length;

        resultRooms.add(
          ChatRoomModel.fromJson(
            r as Map<String, dynamic>,
            members: membersList,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
          ),
        );
      }

      return resultRooms;
    } catch (e, s) {
      AppLogger.e('Failed to fetch chat rooms: $e', tag: 'CHAT', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 2. 단일 채팅방 정보 조회
  Future<ChatRoomModel?> getChatRoom(String roomId) async {
    try {
      final roomData = await _supabase
          .from('chat_rooms')
          .select('''
            id,
            type,
            title,
            created_by,
            created_at,
            updated_at,
            chat_members (
              room_id,
              user_id,
              joined_at,
              last_read_at,
              is_active,
              custom_title,
              users (
                user_id,
                unique_code,
                name,
                profile_image_url,
                status_message
              )
            )
          ''')
          .eq('id', roomId)
          .maybeSingle();

      if (roomData == null) return null;

      final membersList = (roomData['chat_members'] as List? ?? [])
          .map((m) => ChatMemberModel.fromJson(m as Map<String, dynamic>))
          .where((m) => m.isActive)
          .toList();

      return ChatRoomModel.fromJson(roomData, members: membersList);
    } catch (e, s) {
      AppLogger.e('Failed to fetch chat room $roomId: $e', tag: 'CHAT', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 3. 특정 채팅방의 메시지 내역 조회 (미읽음 '1' 카운트 계산 포함)
  Future<List<ChatMessageModel>> getMessages(String roomId, {int limit = 50}) async {
    try {
      // 멤버 정보 조회 (각 멤버의 last_read_at 기준 '1' 계산)
      final membersData = await _supabase
          .from('chat_members')
          .select('user_id, last_read_at, is_active')
          .eq('room_id', roomId)
          .eq('is_active', true);

      final members = (membersData as List).map((m) => ChatMemberModel.fromJson(m as Map<String, dynamic>)).toList();

      // 메시지 목록 조회 (최신순 50개)
      final messagesData = await _supabase
          .from('chat_messages')
          .select('''
            id,
            room_id,
            sender_id,
            type,
            content,
            image_urls,
            emoticon_id,
            created_at,
            users (
              user_id,
              name,
              profile_image_url
            )
          ''')
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(limit);

      List<ChatMessageModel> result = [];

      for (final msg in messagesData as List) {
        final msgModel = ChatMessageModel.fromJson(msg as Map<String, dynamic>);
        
        // 안 읽은 사람 수 계산: (작성자 제외, 해당 메시지 생성 시각보다 last_read_at이 이전인 멤버 수)
        int unread = 0;
        if (msgModel.senderId != null) {
          unread = members.where((m) => 
            m.userId != msgModel.senderId && 
            m.lastReadAt.isBefore(msgModel.createdAt)
          ).length;
        }

        result.add(msgModel.copyWith(unreadCount: unread));
      }

      // 오름차순(과거 -> 최신) 정렬하여 반환
      return result.reversed.toList();
    } catch (e, s) {
      AppLogger.e('Failed to fetch messages for room $roomId: $e', tag: 'CHAT', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 4. 메시지 전송 (텍스트, 사진, 이모티콘) & FCM 푸시 발송
  Future<ChatMessageModel> sendMessage({
    required String roomId,
    String? content,
    List<String> imageUrls = const [],
    String? emoticonId,
    ChatMessageType type = ChatMessageType.text,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    try {
      final insertData = {
        'room_id': roomId,
        'sender_id': uid,
        'type': type.value,
        'content': content,
        'image_urls': imageUrls,
        'emoticon_id': emoticonId,
      };

      final msgData = await _supabase
          .from('chat_messages')
          .insert(insertData)
          .select('''
            id,
            room_id,
            sender_id,
            type,
            content,
            image_urls,
            emoticon_id,
            created_at,
            users (
              user_id,
              name,
              profile_image_url
            )
          ''')
          .single();

      final sentMessage = ChatMessageModel.fromJson(msgData);

      // 내가 방금 보냈으므로 내 last_read_at을 즉시 갱신
      await markChatRoomAsRead(roomId);

      // 다른 멤버들에게 백그라운드 푸시 알림 비동기 전송
      _sendPushNotificationToOtherMembers(roomId, sentMessage);

      return sentMessage;
    } catch (e, s) {
      AppLogger.e('Failed to send message: $e', tag: 'CHAT', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 5. 채팅 이미지 압축 및 Supabase Storage 업로드
  Future<List<String>> uploadChatImages(List<File> files) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');

    List<String> uploadedUrls = [];

    for (final file in files) {
      try {
        final tempDir = await getTemporaryDirectory();
        final targetPath = '${tempDir.path}/chat_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 80,
          minWidth: 1200,
          minHeight: 1200,
        );

        final uploadFile = File(compressedFile?.path ?? file.path);
        final fileName = '$uid/${DateTime.now().millisecondsSinceEpoch}_${uploadFile.path.split('/').last}';

        await _supabase.storage.from('chat-images').upload(
          fileName,
          uploadFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

        final publicUrl = _supabase.storage.from('chat-images').getPublicUrl(fileName);
        uploadedUrls.add(publicUrl);
      } catch (e) {
        AppLogger.e('Failed to upload chat image: $e', tag: 'CHAT');
      }
    }

    return uploadedUrls;
  }

  /// 6. 채팅방 읽음 처리 (last_read_at 갱신)
  Future<void> markChatRoomAsRead(String roomId) async {
    try {
      await _supabase.rpc('mark_chat_room_as_read', params: {'p_room_id': roomId});
    } catch (e) {
      AppLogger.w('Failed to mark chat room as read: $e', tag: 'CHAT');
    }
  }

  /// 7. 1:1 대화방 개설 또는 기존 방 가져오기
  Future<String> getOrCreateDirectRoom(String otherUserId) async {
    try {
      final res = await _supabase.rpc('get_or_create_direct_chat_room', params: {
        'p_other_user_id': otherUserId,
      });
      return res.toString();
    } catch (e, s) {
      AppLogger.e('Failed to get or create direct chat room: $e', tag: 'CHAT', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 8. 그룹 대화방 개설
  Future<String> createGroupRoom(String? title, List<String> memberUserIds) async {
    try {
      final res = await _supabase.rpc('create_group_chat_room', params: {
        'p_title': title,
        'p_member_user_ids': memberUserIds,
      });
      return res.toString();
    } catch (e, s) {
      AppLogger.e('Failed to create group chat room: $e', tag: 'CHAT', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 9. 채팅방 나가기
  Future<void> leaveRoom(String roomId) async {
    try {
      await _supabase.rpc('leave_chat_room', params: {'p_room_id': roomId});
    } catch (e, s) {
      AppLogger.e('Failed to leave chat room: $e', tag: 'CHAT', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 푸시 알림 발송 헬퍼
  Future<void> _sendPushNotificationToOtherMembers(String roomId, ChatMessageModel message) async {
    try {
      final room = await getChatRoom(roomId);
      if (room == null) return;

      // 발신자 실제 프로필 정보(이름, 사진) 조회
      String senderName = '친구';
      String? senderProfileUrl;
      if (currentUserId != null) {
        final senderData = await _supabase
            .from('users')
            .select('name, profile_image_url')
            .eq('user_id', currentUserId!)
            .maybeSingle();
        if (senderData != null) {
          senderName = senderData['name'] as String? ?? '친구';
          senderProfileUrl = senderData['profile_image_url'] as String?;
        }
      }

      final targetUserIds = room.members
          .where((m) => m.userId != currentUserId && m.isActive)
          .map((m) => m.userId)
          .toList();

      if (targetUserIds.isEmpty) return;

      String notifBody = '';
      switch (message.type) {
        case ChatMessageType.text:
          notifBody = message.content ?? '';
          break;
        case ChatMessageType.image:
          notifBody = '📷 사진을 보냈습니다.';
          break;
        case ChatMessageType.emoticon:
          notifBody = '🥰 이모티콘을 보냈습니다.';
          break;
        case ChatMessageType.system:
          return;
      }

      String notifTitle = senderName;
      if (room.type == ChatRoomType.group) {
        final groupTitle = room.title ?? '그룹 대화방';
        notifTitle = '$groupTitle ($senderName)';
      }

      await _notificationSender.sendToUsers(
        targetUserIds: targetUserIds,
        type: NotificationType.chatMessage,
        title: notifTitle,
        body: notifBody,
        roomId: roomId,
        senderId: currentUserId,
        senderName: senderName,
        imageUrl: senderProfileUrl,
      );
    } catch (e) {
      AppLogger.w('Failed to dispatch push notification for chat: $e', tag: 'CHAT');
    }
  }
}
