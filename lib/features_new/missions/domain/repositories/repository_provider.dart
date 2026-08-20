import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features_new/missions/data/repositories/missions_repository_impl.dart';
import 'package:manito/features_new/missions/domain/repositories/missions_repository.dart';

final missionsRepositoryProvider = Provider<MissionsRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return MissionsRepositoryImpl(supabase);
});
