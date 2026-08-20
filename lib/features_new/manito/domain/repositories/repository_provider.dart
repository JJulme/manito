import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features_new/manito/data/repositories/manito_repository_impl.dart';
import 'package:manito/features_new/manito/domain/repositories/manito_repository.dart';

final manitoRepositoryProvider = Provider<ManitoRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ManitoRepositoryImpl(supabase);
});
