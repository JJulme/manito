import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features_new/report/domain/entities/report_entity.dart';
import 'package:manito/features_new/report/domain/repositories/repository_provider.dart';

final reportProvider =
    AsyncNotifierProvider.autoDispose<ReportNotifier, ReportState>(
      ReportNotifier.new,
    );

class ReportNotifier extends AutoDisposeAsyncNotifier<ReportState> {
  @override
  ReportState build() {
    return const ReportState();
  }

  void selectReportType(ReportType type) {
    final currentState = state.valueOrNull ?? const ReportState();
    state = AsyncValue.data(currentState.copyWith(selectedReportType: type));
  }

  Future<String> submitReport({String? postId}) async {
    final currentState = state.valueOrNull;
    if (currentState?.selectedReportType == null) return 'no_type';

    state = const AsyncValue.loading();
    final repository = ref.read(reportRepositoryProvider);
    final type = currentState!.selectedReportType!;
    final reason = switch (type) {
      ReportType.violence => "폭력성",
      ReportType.pornography => "음란물",
      ReportType.other => "기타",
    };

    String result = '';
    state = await AsyncValue.guard(() async {
      result =
          postId != null
              ? await repository.reportPost(postId, reason)
              : await repository.reportUser(reason);

      return ReportState(selectedReportType: type);
    });
    return result;
  }
}
