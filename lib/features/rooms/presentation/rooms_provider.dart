import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/models/models.dart';
import '../data/rooms_repository.dart';

final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return RoomsRepository(supabase);
});

final ongoingRoomsProvider = FutureProvider.autoDispose<List<RoomModel>>((ref) async {
  final repo = ref.watch(roomsRepositoryProvider);
  return repo.fetchOngoingRooms();
});

final receivedRoomInvitationsProvider =
    FutureProvider.autoDispose<List<RoomMemberModel>>((ref) async {
  final repo = ref.watch(roomsRepositoryProvider);
  return repo.fetchReceivedInvitations();
});

final unviewedInviteCountProvider = Provider.autoDispose<int>((ref) {
  final invitesAsync = ref.watch(receivedRoomInvitationsProvider);
  return invitesAsync.maybeWhen(
    data: (list) => list.where((m) => !m.isInviteViewed).length,
    orElse: () => 0,
  );
});

final roomDetailsProvider =
    FutureProvider.autoDispose.family<RoomModel?, String>((ref, roomId) async {
  final repo = ref.watch(roomsRepositoryProvider);
  return repo.getRoom(roomId);
});

final roomRealtimeStreamProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, roomId) {
  final supabase = ref.watch(supabaseProvider);
  return supabase
      .from('rooms')
      .stream(primaryKey: ['room_id'])
      .eq('room_id', roomId);
});

final roomMembersProvider =
    FutureProvider.autoDispose.family<List<RoomMemberModel>, String>((ref, roomId) async {
  final repo = ref.watch(roomsRepositoryProvider);
  return repo.fetchRoomMembers(roomId);
});

final roomMembersRealtimeStreamProvider =
    StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, roomId) {
  final supabase = ref.watch(supabaseProvider);
  return supabase
      .from('room_members')
      .stream(primaryKey: ['room_member_id'])
      .eq('room_id', roomId);
});
