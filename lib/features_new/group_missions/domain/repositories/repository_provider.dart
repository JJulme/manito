import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features_new/group_missions/data/repositories/group_missions_repository_impl.dart';
import 'package:manito/features_new/group_missions/domain/repositories/group_missions_repository.dart';

final groupMissionsRepositoryProvider = Provider<GroupMissionsRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return GroupMissionsRepositoryImpl(supabase);
});
