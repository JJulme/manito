import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/main.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/manito_dog.png',
          width: 0.65 * width,
          height: 0.65 * width,
        ),
      ),
    );
  }
}
