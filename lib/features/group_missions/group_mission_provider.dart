import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/group_missions/group_mission_service.dart';

// ========== Service Provider ==========
final groupMissionService = Provider<GroupMissionService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return GroupMissionService(supabase);
});

// ========== Notifier Provider ==========

// ========== Notifier ==========
// class GroupMissionListNotifier extends AsyncNotifier
