import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_picker_service.dart';
import '../services/camera_service.dart';
import '../services/upload_provider.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/routes/app_router.dart';
import '../widgets/app_button.dart';

class UploadPrescriptionScreen extends ConsumerStatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  ConsumerState<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState
    extends ConsumerState<UploadPrescriptionScreen> {
  final ImagePickerService _pickerService = ImagePickerService();
  final CameraService _cameraService = CameraService();

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _pickerService.pickImageFromGallery();
      if (image != null) ref.read(uploadProvider.notifier).selectImage(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? photo = await _cameraService.capturePhoto();
      if (photo != null) ref.read(uploadProvider.notifier).selectImage(photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<UploadState>(uploadProvider, (_, next) {
      if (next is OCRSuccess) {
        ref.read(uploadProvider.notifier).clearSelection();
        context.push(AppRouter.ocrReview, extra: next.responseData);
      } else if (next is UploadError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Prescription'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              _buildInfoBanner(isDark).animate().fadeIn(duration: 400.ms),

              AppSpacing.vGap20,

              // Main Upload Area
              Expanded(
                child: AnimatedSwitcher(
                  duration: 350.ms,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _buildUploadArea(uploadState, isDark),
                ),
              ),

              AppSpacing.vGap20,

              // Action Row
              AnimatedSwitcher(
                duration: 300.ms,
                child: _buildActionRow(uploadState, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navIndicatorDark : AppColors.navIndicatorLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal, size: 18),
          AppSpacing.hGap12,
          Expanded(
            child: Text(
              'Upload a clear photo of your prescription for AI analysis.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea(UploadState state, bool isDark) {
    if (state is ImageSelected) {
      return _buildImagePreview(state.file, isDark);
    } else if (state is UploadProgress || state is ProcessingOCR) {
      final progress =
          state is UploadProgress ? state.percentage : 0.95;
      final label = state is UploadProgress
          ? 'Uploading...'
          : 'AI Analysis Running...';
      return _buildProgressView(progress, label, isDark);
    } else {
      return _buildIdlePicker(isDark);
    }
  }

  Widget _buildIdlePicker(bool isDark) {
    return GestureDetector(
      key: const ValueKey('idle'),
      onTap: _pickFromGallery,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceCardDark : Colors.white,
          borderRadius: AppSpacing.borderRadiusXl,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated dashed upload icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? AppColors.navIndicatorDark : AppColors.navIndicatorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                size: 48,
                color: AppColors.primaryTeal,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.05, duration: 1800.ms, curve: Curves.easeInOut),

            AppSpacing.vGap24,

            Text(
              'Upload Prescription',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            AppSpacing.vGap8,
            Text(
              'JPG, PNG — max 5MB',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),

            AppSpacing.vGap32,

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _sourceButton(
                  Icons.camera_alt_rounded,
                  'Camera',
                  AppColors.primaryTeal,
                  _captureFromCamera,
                  isDark,
                ),
                AppSpacing.hGap16,
                _sourceButton(
                  Icons.photo_library_rounded,
                  'Gallery',
                  AppColors.statCardBlue,
                  _pickFromGallery,
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(
      IconData icon, String label, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.10),
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            AppSpacing.hGap8,
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(XFile file, bool isDark) {
    return ClipRRect(
      key: const ValueKey('preview'),
      borderRadius: AppSpacing.borderRadiusXl,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(file.path), fit: BoxFit.cover),
          // Overlay gradient at bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: Row(
              children: [
                const Icon(Icons.photo_rounded, color: Colors.white, size: 18),
                AppSpacing.hGap8,
                Expanded(
                  child: Text(
                    file.name,
                    style: AppTypography.bodySmall.copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 350.ms,
        );
  }

  Widget _buildProgressView(double progress, String label, bool isDark) {
    return Container(
      key: const ValueKey('progress'),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          AppSpacing.vGap24,
          Text(label, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
          AppSpacing.vGap12,
          Text(
            'Please wait while we process your prescription.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(UploadState state, bool isDark) {
    if (state is ImageSelected) {
      return Row(
        key: const ValueKey('actions'),
        children: [
          Expanded(
            child: AppButton.outline(
              label: 'Cancel',
              onPressed: () => ref.read(uploadProvider.notifier).clearSelection(),
            ),
          ),
          AppSpacing.hGap16,
          Expanded(
            child: AppButton.primary(
              label: 'Analyze',
              onPressed: () => ref
                  .read(uploadProvider.notifier)
                  .uploadAndProcessPrescription(state.file),
              suffixIcon: Icons.auto_awesome_rounded,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink(key: ValueKey('no-actions'));
  }
}
