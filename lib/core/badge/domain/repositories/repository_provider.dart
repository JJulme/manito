import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/badge/data/repositories/badge_repository_impl.dart';
import 'package:manito/core/badge/domain/repositories/badge_repository.dart';

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return BadgeRepositoryImpl(supabase);
});
