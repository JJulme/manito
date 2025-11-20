import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features/snackbar/snackbar.dart';

// ========== Provider ==========
// final snackBarProvider =
//     StateNotifierProvider<SnackBarNotifier, SnackBarState?>(
//       (ref) => SnackBarNotifier(),
//     );

final snackBarProvider = NotifierProvider<SnackBarNotofier, SnackBarState?>(
  SnackBarNotofier.new,
);

// ========== notifier ==========
// class SnackBarNotifier extends StateNotifier<SnackBarState?> {
//   SnackBarNotifier() : super(null);

//   void show(String message, {SnackBarType type = SnackBarType.info}) {
//     state = SnackBarState(message: message, type: type);
//   }

//   void clear() {
//     state = null;
//   }
// }

class SnackBarNotofier extends Notifier<SnackBarState?> {
  int _nextId = 0;

  @override
  SnackBarState? build() => null;

  void show(String message, {SnackBarType type = SnackBarType.info}) {
    state = SnackBarState(message, type, _nextId++);
  }

  void clear() {
    state = null;
  }
}
