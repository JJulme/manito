import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features/report/report.dart';
import 'package:manito/features/report/report_provider.dart';
import 'package:manito/main.dart';

class ReportBottomsheet extends ConsumerWidget {
  final String userId;
  final String reportIdType;
  final String? postId;

  const ReportBottomsheet({
    super.key,
    required this.userId,
    required this.reportIdType,
    this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportNotifierProvider);
    final notifier = ref.read(reportNotifierProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "report_bottomsheet.bottom_sheet_title",
              style: Theme.of(context).textTheme.bodySmall,
            ).tr(),
            Text(
              "report_bottomsheet.bottom_sheet_body",
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ).tr(),
            SizedBox(height: width * 0.04),

            ...ReportType.values.map((type) {
              return RadioListTile<ReportType>(
                title:
                    Text(
                      'report_bottomsheet.${type.name}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ).tr(),
                value: type,
                groupValue: state.selectedReportType,
                onChanged: (value) {
                  if (value != null) notifier.selectReportType(value);
                },
              );
            }),
            SizedBox(height: width * 0.04),
            SizedBox(
              height: width * 0.14,
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    state.selectedReportType == null || state.isLoading
                        ? null
                        : () async {
                          final navigator = Navigator.of(context);
                          final result = await notifier.submitReport(
                            userId: userId,
                            postId: reportIdType == 'post' ? postId : null,
                          );
                          await showDialog(
                            context: context,
                            builder: (context) {
                              String title = '';
                              String message = '';
                              if (result == 'success') {
                                title = tr(
                                  "report_bottomsheet.dialog_title_success",
                                );
                                message = tr(
                                  "report_bottomsheet.dialog_message_success",
                                );
                              } else if (result == 'duplicate') {
                                title = tr(
                                  "report_bottomsheet.dialog_title_duplicate",
                                );
                                message = tr(
                                  "report_bottomsheet.dialog_message_duplicate",
                                );
                              } else {
                                title = tr(
                                  "report_bottomsheet.dialog_title_fail",
                                );
                                message = tr(
                                  "report_bottomsheet.dialog_message_fail",
                                );
                              }
                              return AlertDialog(
                                title: Text(title),
                                content: Text(message),
                                actions: [
                                  TextButton(
                                    onPressed: () => navigator.pop(),
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                          navigator.pop();
                        },
                child:
                    state.isLoading
                        ? const CircularProgressIndicator()
                        : const Text("신고하기"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
