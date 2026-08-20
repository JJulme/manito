import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features_new/posts/data/repositories/posts_repository_impl.dart';
import 'package:manito/features_new/posts/domain/repositories/posts_repository.dart';

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return PostsRepositoryImpl(supabase);
});
