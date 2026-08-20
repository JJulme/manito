import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/theme/data/repositories/theme_repository_impl.dart';
import 'package:manito/core/theme/domain/repositories/theme_repository.dart';

final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  return ThemeRepositoryImpl();
});
