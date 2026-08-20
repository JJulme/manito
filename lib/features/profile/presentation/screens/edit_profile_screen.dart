import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manito/core/models/models.dart';
import 'package:manito/core/providers.dart';
import 'package:manito/core/theme/app_colors.dart';
import 'package:manito/core/theme/app_typography.dart';
import 'package:manito/core/util/app_logger.dart';
import 'package:manito/core/widget/manito_mascot.dart';
import 'package:manito/features/profile/presentation/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final bool isFirstSetup;

  const EditProfileScreen({super.key, this.isFirstSetup = false});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _statusController = TextEditingController();
  final _manitoReplyController = TextEditingController();
  final _guessReplyController = TextEditingController();

  String? _selectedImageUrl;
  bool _isUploadingImage = false;

  String? _manitoImageUrl;
  bool _isUploadingManitoImage = false;

  String? _guessImageUrl;
  bool _isUploadingGuessImage = false;

  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    _manitoReplyController.dispose();
    _guessReplyController.dispose();
    super.dispose();
  }

  void _initFromUser(UserModel? user) {
    if (!_isInitialized && user != null) {
      _nameController.text = user.name;
      _statusController.text = user.statusMessage ?? '';
      _manitoReplyController.text = user.manitoAutoReplyText ?? '';
      _guessReplyController.text = user.guessAutoReplyText ?? '';
      _selectedImageUrl = user.profileImageUrl;
      _manitoImageUrl = user.manitoAutoReplyImg;
      _guessImageUrl = user.guessAutoReplyImg;
      _isInitialized = true;
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('로그인이 필요합니다.');

      final file = File(picked.path);
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profiles/$fileName';

      await Supabase.instance.client.storage.from('records').upload(path, file);
      final publicUrl = Supabase.instance.client.storage
          .from('records')
          .getPublicUrl(path);

      setState(() {
        _selectedImageUrl = publicUrl;
        _isUploadingImage = false;
      });
    } catch (e, s) {
      setState(() => _isUploadingImage = false);
      AppLogger.e(
        'Profile image upload failed: $e',
        tag: 'PROFILE',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('사진 업로드 실패: $e')));
      }
    }
  }

  Future<void> _pickAutoReplyImage({required bool isManito}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        if (isManito) {
          _isUploadingManitoImage = true;
        } else {
          _isUploadingGuessImage = true;
        }
      });

      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw Exception('로그인이 필요합니다.');

      final file = File(picked.path);
      final prefix = isManito ? 'manito_reply' : 'guess_reply';
      final fileName =
          '${prefix}_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'auto_replies/$fileName';

      await Supabase.instance.client.storage.from('records').upload(path, file);
      final publicUrl = Supabase.instance.client.storage
          .from('records')
          .getPublicUrl(path);

      setState(() {
        if (isManito) {
          _manitoImageUrl = publicUrl;
          _isUploadingManitoImage = false;
        } else {
          _guessImageUrl = publicUrl;
          _isUploadingGuessImage = false;
        }
      });
    } catch (e, s) {
      setState(() {
        if (isManito) {
          _isUploadingManitoImage = false;
        } else {
          _isUploadingGuessImage = false;
        }
      });
      AppLogger.e(
        'Auto-reply image upload failed: $e',
        tag: 'PROFILE',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('사진 업로드 실패: $e')));
      }
    }
  }

  Future<void> _handleSave() async {
    final image = _selectedImageUrl?.trim() ?? '';
    final name = _nameController.text.trim();
    final status = _statusController.text.trim();
    final manitoReply = _manitoReplyController.text.trim();
    final guessReply = _guessReplyController.text.trim();

    // Validation: 5가지 항목 모두 필수 체크
    if (image.isEmpty) {
      _showWarning('프로필 사진을 등록해 주세요.');
      return;
    }
    if (name.length < 2 || name.length > 12) {
      _showWarning('이름은 2~12자 사이로 입력해 주세요.');
      return;
    }
    if (status.isEmpty) {
      _showWarning('상태메시지를 입력해 주세요.');
      return;
    }
    if (manitoReply.isEmpty) {
      _showWarning('마니또 자동응답 문구를 입력해 주세요.');
      return;
    }
    if (guessReply.isEmpty) {
      _showWarning('추측 자동응답 문구를 입력해 주세요.');
      return;
    }

    final success = await ref
        .read(profileFormProvider.notifier)
        .saveProfile(
          name: name,
          profileImageUrl: image,
          statusMessage: status,
          manitoAutoReplyText: manitoReply,
          manitoAutoReplyImg: _manitoImageUrl,
          guessAutoReplyText: guessReply,
          guessAutoReplyImg: _guessImageUrl,
        );

    if (success && mounted) {
      ref.invalidate(currentUserProfileProvider);
      try {
        await ref.read(currentUserProfileProvider.future);
      } catch (_) {}

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/bottom_nav2');
        }
      }
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.statusRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// 블로그/피드 카드 스타일의 자동응답 에디터 위젯
  Widget _buildBlogStyleAutoReplyCard({
    required String title,
    required String description,
    required IconData icon,
    required TextEditingController textController,
    required String? imageUrl,
    required bool isUploading,
    required bool isManito,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.titleSm),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: AppTypography.bodySm),
          const SizedBox(height: 16),

          // 1. Full-Width Blog Image Slot
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: imageUrl.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              placeholder: (_, __) => Container(color: AppColors.surface),
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
                            )
                          : Image.asset(imageUrl, width: double.infinity, fit: BoxFit.fitWidth),
                    ),
                  ),
                ),
                // Top-right action buttons
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _pickAutoReplyImage(isManito: isManito),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.photo_camera_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '사진 변경',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isManito) {
                              _manitoImageUrl = null;
                            } else {
                              _guessImageUrl = null;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.statusRed.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else ...[
            // Empty Full-Width Upload Slot
            InkWell(
              onTap:
                  isUploading
                      ? null
                      : () => _pickAutoReplyImage(isManito: isManito),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child:
                    isUploading
                        ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 8),
                              Text('사진 업로드 중...', style: AppTypography.bodySm),
                            ],
                          ),
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 24,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '사진 추가하기 (선택, 최대 1장)',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 2. Blog Text Body (Under the image)
          TextFormField(
            controller: textController,
            maxLength: 100,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hintText,
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.surfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final formState = ref.watch(profileFormProvider);
    final isComplete = userAsync.value?.isProfileComplete ?? false;
    final isMandatorySetup = widget.isFirstSetup || !isComplete;

    userAsync.whenData((u) => _initFromUser(u));

    return PopScope(
      canPop: !isMandatorySetup,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isMandatorySetup ? '프로필 등록' : '프로필 수정'),
          automaticallyImplyLeading: !isMandatorySetup,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: [
                    // First setup onboarding banner
                    if (isMandatorySetup) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: const [
                            ManitoMascot.sunglass(width: 48, height: 48),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('프로필 등록', style: AppTypography.titleSm),
                                  SizedBox(height: 4),
                                  Text(
                                    '원활한 서비스 이용을 위해 5가지 필수 정보를 모두 입력해주세요.',
                                    style: AppTypography.bodySm,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 1. Profile Avatar Picker (Tap to open gallery)
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickImageFromGallery,
                            child: Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceLow,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 2,
                                ),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: ClipOval(
                                child:
                                    _isUploadingImage
                                        ? const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                          ),
                                        )
                                        : _selectedImageUrl != null &&
                                            _selectedImageUrl!.isNotEmpty
                                        ? (_selectedImageUrl!.startsWith('http')
                                            ? CachedNetworkImage(
                                              imageUrl: _selectedImageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(color: AppColors.surface),
                                              errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, size: 54, color: AppColors.textDisabled),
                                            )
                                            : Image.asset(
                                              _selectedImageUrl!,
                                              fit: BoxFit.cover,
                                            ))
                                        : const Icon(
                                          Icons.person_rounded,
                                          size: 54,
                                          color: AppColors.textDisabled,
                                        ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImageFromGallery,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Name
                    const Text('이름 *', style: AppTypography.titleSm),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      maxLength: 12,
                      decoration: const InputDecoration(
                        hintText: '이름을 입력하세요 (2~12자)',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Status Message
                    const Text('상태 메시지 *', style: AppTypography.titleSm),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _statusController,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        hintText: '상태 메시지를 입력하세요 (최대 30자)',
                        prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 4. Manito Auto-Reply (Blog-style Card)
                    _buildBlogStyleAutoReplyCard(
                      title: '마니또 자동응답 *',
                      description:
                          '마감 시간까지 마니또 미션을 입력하지 못했을 때 자동으로 게시되는 게시물입니다.',
                      icon: Icons.lock_clock_outlined,
                      textController: _manitoReplyController,
                      imageUrl: _manitoImageUrl,
                      isUploading: _isUploadingManitoImage,
                      isManito: true,
                      hintText: '마감 시 자동으로 게시될 마니또 메시지를 작성해주세요...',
                    ),
                    const SizedBox(height: 20),

                    // 5. Guess Auto-Reply (Blog-style Card)
                    _buildBlogStyleAutoReplyCard(
                      title: '추측 자동응답 *',
                      description:
                          '마감 시간까지 마니또 추측을 입력하지 못했을 때 자동으로 게시되는 게시물입니다.',
                      icon: Icons.psychology_outlined,
                      textController: _guessReplyController,
                      imageUrl: _guessImageUrl,
                      isUploading: _isUploadingGuessImage,
                      isManito: false,
                      hintText: '마감 시 자동으로 게시될 추측 메시지를 작성해주세요...',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // Bottom Save Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: formState.isSaving ? null : _handleSave,
                    child:
                        formState.isSaving
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(isMandatorySetup ? '등록 완료 및 시작하기' : '저장하기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
