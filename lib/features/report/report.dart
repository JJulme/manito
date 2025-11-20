enum ReportType { violence, pornography, other }

class ReportState {
  final ReportType? selectedReportType;
  ReportState({this.selectedReportType});

  ReportState copyWith({ReportType? selectedReportType}) {
    return ReportState(
      selectedReportType: selectedReportType ?? this.selectedReportType,
    );
  }
}
