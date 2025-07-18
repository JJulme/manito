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
            Text("신고 사유를 선택해주세요", style: Get.textTheme.bodySmall),
            Text(
              "신고 사유에 맞지 않는 신고일 경우,\n해당 신고는 처리되지 않습니다.",
              style: Get.textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: width * 0.04),
            // 폭력성
            RadioListTile<ReportType>(
              title: Text("폭력성"),
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
              title: Text("음란물"),
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
              title: Text("기타"),
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
                child: Text("신고하기"),
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
      "신고가 접수되었습니다.",
      "신고가 정상적으로 접수되었습니다. 검토까지는 최대 24시간이 소요될 수 있습니다.",
    );
  } else if (result == 'duplicate') {
    return kDefaultDialog(
      "중복 신고",
      "이미 동일한 내용으로 신고하셨습니다. 현재 검토 대기 중이므로 추가 신고는 불가합니다.",
    );
  } else {
    return kDefaultDialog(
      "신고 실패",
      "알 수 없는 오류로 인해 신고 처리에 실패했습니다.\n잠시 후 다시 시도해 주시거나,\n문제가 지속될 경우 고객센터로 문의 바랍니다.",
    );
  }
}
