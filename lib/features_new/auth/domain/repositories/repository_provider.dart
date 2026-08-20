import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features_new/auth/data/repositories/auth_repository_impl.dart';
import 'package:manito/features_new/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthRepositoryImpl(supabase);
});
