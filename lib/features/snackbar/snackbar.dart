enum SnackBarType { success, error, info, warning }

class SnackBarState {
  final String message;
  final SnackBarType type;

  SnackBarState({required this.message, required this.type});
}
