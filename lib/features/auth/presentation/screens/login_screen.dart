import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/widget/manito_logo.dart';
import 'package:manito/core/widget/manito_mascot.dart';
import 'package:manito/features_new/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final PageController _pageController = PageController();
  bool _isLoading = false;

  final List<_OnboardingItem> _slides = const [
    _OnboardingItem(
      mascot: ManitoMascotType.phone,
      title: '미션을 만들고\n나만의 마니또를 만들어 보세요!',
    ),
    _OnboardingItem(
      mascot: ManitoMascotType.sunglass,
      title: '마니또가 되어서\n친구를 몰래 도와주세요!',
    ),
    _OnboardingItem(
      mascot: ManitoMascotType.thinking,
      title: '나를 도와준 마니또가\n누구인지 추측해 보세요!',
    ),
    _OnboardingItem(
      mascot: ManitoMascotType.selfie,
      title: '친구를 어떻게\n도와주었는지 기록해 보세요!',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구글 로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).loginWithApple();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('애플 로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Top Brand Header
                      const ManitoLogo(
                        fontSize: 40,
                        showBadge: false,
                      ),
                      const SizedBox(height: 8),

                      // Mascot Carousel (Responsive with Flexible sizing)
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          itemBuilder: (ctx, idx) {
                            final slide = _slides[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    flex: 3,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
                                        maxHeight: 220,
                                        minWidth: 100,
                                        minHeight: 100,
                                      ),
                                      child: ManitoMascot(
                                        type: slide.mascot,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Flexible(
                                    flex: 2,
                                    child: Text(
                                      slide.title,
                                      style: AppTypography.headlineLg.copyWith(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Smooth Page Indicator
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _slides.length,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: AppColors.textPrimary,
                          dotColor: AppColors.border,
                          dotHeight: 7,
                          dotWidth: 7,
                          expansionFactor: 3,
                          spacing: 5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Social Auth Buttons Area
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Kakao Login Button
                            _buildSocialButton(
                              label: '카카오로 시작하기',
                              iconAsset: 'assets/images/circle_kakao.png',
                              bgColor: const Color(0xFFFEE500),
                              textColor: const Color(0xFF191919),
                              onTap: () => context.push('/kakao_login'),
                            ),
                            const SizedBox(height: 10),

                            // Google Login Button
                            _buildSocialButton(
                              label: 'Google 계정으로 계속',
                              iconAsset: 'assets/images/circle_google.png',
                              bgColor: Colors.white,
                              textColor: AppColors.textPrimary,
                              borderSide: const BorderSide(color: AppColors.border, width: 1.2),
                              onTap: _handleGoogleLogin,
                            ),

                            // Apple Login Button (iOS only)
                            if (Platform.isIOS) ...[
                              const SizedBox(height: 10),
                              _buildSocialButton(
                                label: 'Apple로 로그인',
                                iconAsset: 'assets/images/circle_apple.png',
                                bgColor: Colors.black,
                                textColor: Colors.white,
                                onTap: _handleAppleLogin,
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String iconAsset,
    required Color bgColor,
    required Color textColor,
    BorderSide? borderSide,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
          boxShadow: AppColors.cardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconAsset, width: 24, height: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final ManitoMascotType mascot;
  final String title;

  const _OnboardingItem({
    required this.mascot,
    required this.title,
  });
}
