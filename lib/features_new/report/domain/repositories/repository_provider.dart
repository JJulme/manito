import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features_new/report/data/repositories/report_repository_impl.dart';
import 'package:manito/features_new/report/domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ReportRepositoryImpl(supabase);
});
