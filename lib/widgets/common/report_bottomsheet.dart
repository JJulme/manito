import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/constants.dart';

enum ReportType {
  violence, // 폭력성
  pornography, // 음란물
  other, // 기타
}

class ReportBottomsheet extends StatefulWidget {
  const ReportBottomsheet({super.key});

  @override
  State<ReportBottomsheet> createState() => _ReportBottomsheetState();
}

class _ReportBottomsheetState extends State<ReportBottomsheet> {
  ReportType? _selectedReportType; // 현재 선택된 신고 유형을 저장할 변수
  @override
  Widget build(BuildContext context) {
    double width = Get.width;
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("신고 사유를 선택해주세요", style: Get.textTheme.labelLarge),
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
                        : () {
                          Navigator.pop(context, _selectedReportType);
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
Future<void> reportDialog(BuildContext context, ReportType reportType) async {
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
  return kDefaultDialog("신고가 접수되었습니다.", '검토까지는 최대 24시간이\n소요됩니다.');
}
