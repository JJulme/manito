import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features_new/friends/data/repositories/friends_repository_impl.dart';
import 'package:manito/features_new/friends/domain/repositories/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return FriendsRepositoryImpl(supabase);
});
