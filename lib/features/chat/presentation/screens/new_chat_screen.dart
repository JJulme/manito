import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/user_avatar.dart';
import 'package:manito/features/friends/presentation/friends_provider.dart';
import '../../data/chat_repository.dart';
import '../chat_provider.dart';
import 'chat_room_screen.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  final Map<String, UserModel> _selectedUsersMap = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _startChat() async {
    if (_selectedUserIds.isEmpty || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final repo = ref.read(chatRepositoryProvider);
      String roomId;

      if (_selectedUserIds.length == 1) {
        // 1:1 대화방
        final otherId = _selectedUserIds.first;
        roomId = await repo.getOrCreateDirectRoom(otherId);
      } else {
        // 그룹 대화방
        final title = _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null;
        roomId = await repo.createGroupRoom(title, _selectedUserIds.toList());
      }

      ref.invalidate(chatRoomsProvider);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(roomId: roomId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 개설 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(acceptedFriendsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final searchQuery = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('새로운 채팅'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 검색바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowOf(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderOf(context), width: 0.8),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '친구 이름 또는 고유 코드 검색',
                    hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textDisabledOf(context)),
                    prefixIcon: Icon(LucideIcons.search, color: AppColors.textSecondaryOf(context), size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // 2. 그룹 대화방 제목 입력 필드 (2명 이상 선택 시 표시)
            if (_selectedUserIds.length > 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1),
                  ),
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '그룹 대화방 제목 (선택 입력)',
                      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textDisabledOf(context)),
                      prefixIcon: const Icon(LucideIcons.users, color: AppColors.primary, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],

            // 3. 선택된 친구 칩 목록 (가로 스크롤)
            if (_selectedUserIds.isNotEmpty) ...[
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _selectedUserIds.map((uid) {
                    final u = _selectedUsersMap[uid];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        avatar: UserAvatar(imageUrl: u?.profileImageUrl, size: 24),
                        label: Text(u?.name ?? '친구', style: AppTypography.bodySm),
                        deleteIcon: const Icon(LucideIcons.x, size: 14),
                        onDeleted: () {
                          setState(() {
                            _selectedUserIds.remove(uid);
                            _selectedUsersMap.remove(uid);
                          });
                        },
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
            ],

            // 4. 친구 목록
            Expanded(
              child: friendsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Center(child: Text('친구 목록을 불러올 수 없습니다: $err')),
                data: (friendships) {
                  final friends = friendships
                      .map((f) => f.friendProfile)
                      .whereType<UserModel>()
                      .where((u) => u.userId != currentUserId)
                      .where((u) {
                        if (searchQuery.isEmpty) return true;
                        return u.name.toLowerCase().contains(searchQuery) ||
                            u.uniqueCode.toLowerCase().contains(searchQuery);
                      })
                      .toList();

                  if (friends.isEmpty) {
                    return Center(
                      child: Text(
                        searchQuery.isEmpty ? '등록된 친구가 없습니다.' : '검색 결과가 없습니다.',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondaryOf(context)),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: friends.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (ctx, index) {
                      final friend = friends[index];
                      final isSelected = _selectedUserIds.contains(friend.userId);

                      return ListTile(
                        leading: UserAvatar(imageUrl: friend.profileImageUrl, size: 44),
                        title: Text(
                          friend.name,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimaryOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: friend.statusMessage != null && friend.statusMessage!.isNotEmpty
                            ? Text(
                                friend.statusMessage!,
                                style: AppTypography.bodySm.copyWith(color: AppColors.textSecondaryOf(context)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUserIds.add(friend.userId);
                                _selectedUsersMap[friend.userId] = friend;
                              } else {
                                _selectedUserIds.remove(friend.userId);
                                _selectedUsersMap.remove(friend.userId);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(friend.userId);
                              _selectedUsersMap.remove(friend.userId);
                            } else {
                              _selectedUserIds.add(friend.userId);
                              _selectedUsersMap[friend.userId] = friend;
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // 5. 하단 시작 버튼
            if (_selectedUserIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _startChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF1E1E24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isCreating
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            _selectedUserIds.length == 1
                                ? '1:1 대화 시작'
                                : '그룹 대화 시작 (${_selectedUserIds.length}명)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
