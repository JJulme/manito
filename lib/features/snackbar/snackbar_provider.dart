import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features/snackbar/snackbar.dart';

// ========== Provider ==========
final snackBarProvider =
    StateNotifierProvider<SnackBarNotifier, SnackBarState?>(
      (ref) => SnackBarNotifier(),
    );

// ========== notifier ==========
class SnackBarNotifier extends StateNotifier<SnackBarState?> {
  SnackBarNotifier() : super(null);

  void show(String message, {SnackBarType type = SnackBarType.info}) {
    state = SnackBarState(message: message, type: type);
  }

  void clear() {
    state = null;
  }
}
