import 'package:flutter_riverpod/flutter_riverpod.dart';

final errorProvider = NotifierProvider<ErrorNotifier, String?>(
  ErrorNotifier.new,
);

class ErrorNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void setError(String message) {
    state = message;
  }

  void clearError() {
    state = null;
  }
}
