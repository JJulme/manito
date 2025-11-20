import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/features/report/report.dart';
import 'package:manito/features/report/report_service.dart';

// ========== Provider ==========
final reportServiceProvider = Provider<ReportService>((ref) {
  final supabase = ref.read(supabaseProvider);
  return ReportService(supabase);
});

// final reportNotifierProvider =
//     StateNotifierProvider<ReportNotifier, ReportState>((ref) {
//       final service = ref.watch(reportServiceProvider);
//       return ReportNotifier(service);
//     });

final reportProvider =
    AsyncNotifierProvider.autoDispose<ReportNotifier, ReportState>(
      ReportNotifier.new,
    );

// ========== Notifier ==========
// class ReportNotifier extends StateNotifier<ReportState> {
//   final ReportService _reportService;

//   ReportNotifier(this._reportService) : super(ReportState());

//   void selectReportType(ReportType type) {
//     state = state.copyWith(selectedReportType: type);
//   }

//   Future<String> submitReport({required String userId, String? postId}) async {
//     if (state.selectedReportType == null) return 'no_type';
//     state = state.copyWith(isLoading: true);

//     late String result;
//     final type = state.selectedReportType!;

//     String reason = switch (type) {
//       ReportType.violence => "폭력성",
//       ReportType.pornography => "음란물",
//       ReportType.other => "기타",
//     };
//     try {
//       if (postId != null) {
//         result = await _reportService.reportPost(postId, reason);
//       } else {
//         result = await _reportService.reportUser(reason);
//       }
//     } catch (e) {
//       debugPrint('ReportNotifier.submitReport Error: $e');
//     } finally {
//       state = state.copyWith(isLoading: false);
//     }
//     return result;
//   }
// }

class ReportNotifier extends AutoDisposeAsyncNotifier<ReportState> {
  @override
  ReportState build() {
    return ReportState();
  }

  void selectReportType(ReportType type) {
    final currentState = state.valueOrNull ?? ReportState();
    state = AsyncValue.data(currentState.copyWith(selectedReportType: type));
  }

  // 신고 제출
  Future<String> submitReport({String? postId}) async {
    final currentState = state.valueOrNull;
    state = const AsyncValue.loading();
    final service = ref.read(reportServiceProvider);
    final type = currentState!.selectedReportType!;
    final reason = switch (type) {
      ReportType.violence => "폭력성",
      ReportType.pornography => "음란물",
      ReportType.other => "기타",
    };
    String result = '';
    state = await AsyncValue.guard(() async {
      // ✅ API 호출
      result =
          postId != null
              ? await service.reportPost(postId, reason)
              : await service.reportUser(reason);

      return ReportState(selectedReportType: type);
    });
    return result;
  }
}
