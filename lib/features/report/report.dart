enum ReportType { violence, pornography, other }

class ReportState {
  final ReportType? selectedReportType;
  final bool isLoading;
  ReportState({this.selectedReportType, this.isLoading = false});

  ReportState copyWith({ReportType? selectedReportType, bool? isLoading}) {
    return ReportState(
      selectedReportType: selectedReportType ?? this.selectedReportType,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
