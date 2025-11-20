enum SnackBarType { success, error, info, warning }

class SnackBarState {
  final String message;
  final SnackBarType type;
  final int id;

  SnackBarState(this.message, this.type, this.id);
}
