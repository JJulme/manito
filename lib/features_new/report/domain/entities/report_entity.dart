enum ReportType { violence, pornography, other }

class ReportState {
  final ReportType? selectedReportType;

  const ReportState({this.selectedReportType});

  ReportState copyWith({ReportType? selectedReportType}) {
    return ReportState(
      selectedReportType: selectedReportType ?? this.selectedReportType,
    );
  }
}
