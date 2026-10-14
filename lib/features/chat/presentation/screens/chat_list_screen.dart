import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/i18n/strings.g.dart';
import '../chat_provider.dart';
import '../widgets/chat_room_card.dart';
import 'chat_room_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NewChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';
    final searchQuery = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.home.tabChat,
          style: AppTypography.headlineMd.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.message_square_plus,
                color: AppColors.primaryDark,
                size: 20,
              ),
            ),
            tooltip: '새로운 채팅',
            onPressed: _openNewChat,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(chatRoomsProvider);
        },
        child: chatRoomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.circle_alert, size: 48, color: AppColors.statusRed),
                const SizedBox(height: 12),
                Text('채팅 목록을 불러올 수 없습니다.', style: AppTypography.bodyMd),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(chatRoomsProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (rooms) {
            final filteredRooms = rooms.where((r) {
              if (searchQuery.isEmpty) return true;
              final title = r.getDisplayTitle(currentUserId).toLowerCase();
              final lastMsg = r.lastMessage?.content?.toLowerCase() ?? '';
              return title.contains(searchQuery) || lastMsg.contains(searchQuery);
            }).toList();

            if (rooms.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.message_circle,
                            size: 40,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '진행 중인 채팅이 없습니다.',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimaryOf(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '친구를 선택해 1:1 또는 그룹 대화를 시작해보세요!',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _openNewChat,
                            icon: const Icon(LucideIcons.plus, size: 22),
                            label: const Text(
                              '새로운 대화 시작하기',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: const Color(0xFF1E1E24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredRooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 82),
              itemBuilder: (ctx, index) {
                final room = filteredRooms[index];
                return ChatRoomCard(
                  room: room,
                  currentUserId: currentUserId,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(roomId: room.id),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
