import 'package:flutter_riverpod/flutter_riverpod.dart';

final errorProvider = StateNotifierProvider<ErrorNotifier, String?>(
  (ref) => ErrorNotifier(),
);

class ErrorNotifier extends StateNotifier<String?> {
  ErrorNotifier() : super(null);

  void setError(String message) {
    state = message;
  }

  void clearError() {
    state = null;
  }
}
