import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';
import 'package:manito/controllers/report_controller.dart';

enum ReportType {
  violence, // 폭력성
  pornography, // 음란물
  other, // 기타
}

class ReportBottomsheet extends StatefulWidget {
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
  State<ReportBottomsheet> createState() => _ReportBottomsheetState();
}

class _ReportBottomsheetState extends State<ReportBottomsheet> {
  late ReportController _controller;

  ReportType? _selectedReportType; // 현재 선택된 신고 유형을 저장할 변수
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ReportController());
  }

  // 신고하기 버튼
  Future<void> _handleReportButton(ReportType reportType) async {
    late String result;
    String reportReason = '';
    switch (reportType) {
      case ReportType.violence:
        reportReason = '폭력성';
        break;
      case ReportType.pornography:
        reportReason = '음란물';
        break;
      case ReportType.other:
        reportReason = '기타';
        break;
    }
    // 로딩창 생성
    Get.dialog(
      barrierDismissible: false,
      PopScope(
        canPop: false,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );

    if (widget.reportIdType == 'user') {
      result = await _controller.reportUser(widget.userId, reportReason);
    } else if (widget.reportIdType == 'post') {
      result = await _controller.reportPost(
        widget.userId,
        widget.postId!,
        reportReason,
      );
    }
    await Future.delayed(Duration(seconds: 2));
    // 로딩 닫기
    Get.back();
    // 바텀 시트 닫기
    Get.back(result: result);
  }

  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "report_bottomsheet.bottom_sheet_title",
              style: Get.textTheme.bodySmall,
            ).tr(),
            Text(
              "report_bottomsheet.bottom_sheet_body",
              style: Get.textTheme.labelLarge,
              textAlign: TextAlign.center,
            ).tr(),
            SizedBox(height: width * 0.04),
            // 폭력성
            RadioListTile<ReportType>(
              title: Text("report_bottomsheet.violence").tr(),
              value: ReportType.violence,
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value;
                });
              },
            ),
            // 음란물
            RadioListTile<ReportType>(
              title: Text("report_bottomsheet.pornography").tr(),
              value: ReportType.pornography,
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value;
                });
              },
            ),
            // 기타
            RadioListTile<ReportType>(
              title: Text("report_bottomsheet.other").tr(),
              value: ReportType.other,
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value;
                });
              },
            ),
            SizedBox(height: width * 0.04),
            SizedBox(
              height: width * 0.14,
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _selectedReportType == null
                        ? null
                        : () async {
                          // 신고 내용 전송
                          await _handleReportButton(_selectedReportType!);
                        },
                child: Text("report_bottomsheet.report_button").tr(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 신고완료 다이얼로그
Future<void> reportDialog(String result) async {
  if (result == 'success') {
    return kDefaultDialog(
      Get.context!.tr("report_bottomsheet.dialog_title_success"),
      Get.context!.tr("report_bottomsheet.dialog_message_success"),
    );
  } else if (result == 'duplicate') {
    return kDefaultDialog(
      Get.context!.tr("report_bottomsheet.dialog_title_duplicate"),
      Get.context!.tr("report_bottomsheet.dialog_message_duplicate"),
    );
  } else {
    return kDefaultDialog(
      Get.context!.tr("report_bottomsheet.dialog_title_fail"),
      Get.context!.tr("report_bottomsheet.dialog_message_fail"),
    );
  }
}
