import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_button.dart';


import '../services/image_picker_service.dart';
import '../services/camera_service.dart';
import '../services/upload_provider.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/routes/app_router.dart';
import 'onboarding_screen.dart'; // Import BackgroundPatternPainter for visual consistency

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
  bool _isFlashOn = false;

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

  Future<void> _pickPDFDocument() async {
    // Simulated PDF Picker selection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload PDF Document'),
        content: const Text('Simulating medical PDF import. Selecting "prescription_scan_july.pdf" from files...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Optimistically simulate a picked document by choosing a mock file
              // To hook it cleanly with the upload provider:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected "prescription_scan_july.pdf". Processing...'),
                  backgroundColor: Color(0xFF6C63FF),
                ),
              );
            },
            child: const Text('Import', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFlashOn ? 'Camera flash enabled' : 'Camera flash disabled'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<UploadState>(uploadProvider, (_, next) {
      if (next is OCRSuccess) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(uploadProvider.notifier).clearSelection();
          context.push(AppRouter.ocrReview, extra: next.responseData);
        });
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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Scan Prescription',
          style: TextStyle(fontFamily: AppTypography.fontFamily, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (uploadState is! UploadProgress && uploadState is! ProcessingOCR)
            IconButton(
              icon: Icon(_isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
              onPressed: _toggleFlash,
              color: _isFlashOn ? Colors.amber : (isDark ? Colors.white : Colors.black87),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative background pattern
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: BackgroundPatternPainter(),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Info Banner
                  _buildInfoBanner(isDark).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 16),

                  // 2. Main Upload Scanner Frame Area
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: 350.ms,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _buildUploadArea(uploadState, isDark),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Action Row or Scanner Tips
                  AnimatedSwitcher(
                    duration: 300.ms,
                    child: uploadState is ImageSelected
                        ? _buildActionRow(uploadState, isDark)
                        : _buildScanningTipsList(isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navIndicatorDark : AppColors.navIndicatorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: isDark ? AppColors.primaryPurpleLight : AppColors.primaryPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Upload a clear photo of your prescription. The AI will extract medication, dosage, and schedules.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.primaryPurpleLight : AppColors.primaryPurple,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
      final progress = state is UploadProgress ? state.percentage : 0.95;
      final label = state is UploadProgress ? 'Uploading to Server...' : 'Reading Handwriting & Analyzing...';
      return _buildProgressView(progress, label, isDark);
    } else {
      return _buildIdlePicker(isDark);
    }
  }

  Widget _buildIdlePicker(bool isDark) {
    return Stack(
      key: const ValueKey('idle'),
      alignment: Alignment.center,
      children: [
        // Scanner auto-detection box frame container
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceCardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Central Pulsing Upload Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  size: 40,
                  color: Color(0xFF6C63FF),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.06, duration: 1500.ms, curve: Curves.easeInOut),

              const SizedBox(height: 20),

              const Text(
                'Scan Prescription',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 6),
              const Text(
                'PDF, JPG, PNG — max 5MB',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),

              const SizedBox(height: 32),

              // Action Buttons Row (Camera / Gallery / PDF)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _sourceButton(
                      Icons.camera_alt_rounded,
                      'Camera',
                      const Color(0xFF6C63FF),
                      _captureFromCamera,
                      isDark,
                    ),
                    _sourceButton(
                      Icons.photo_library_rounded,
                      'Gallery',
                      const Color(0xFF0284C7),
                      _pickFromGallery,
                      isDark,
                    ),
                    _sourceButton(
                      Icons.picture_as_pdf_rounded,
                      'PDF File',
                      const Color(0xFFD97706),
                      _pickPDFDocument,
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Auto-detection corner frames overlay paint
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ScannerFramePainter(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sourceButton(
      IconData icon, String label, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
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
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(file.path), fit: BoxFit.cover),
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
                  stops: const [0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: const Color(0xFF10B981), size: 22),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), duration: 350.ms);
  }

  Widget _buildProgressView(double progress, String label, bool isDark) {
    return Container(
      key: const ValueKey('progress'),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5.5,
                  backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analyzing handwriting and drug data. Please hold...',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(UploadState state, bool isDark) {
    final selectedState = state as ImageSelected;
    return Row(
      key: const ValueKey('actions'),
      children: [
        Expanded(
          child: AppButton.outline(
            label: 'Cancel',
            onPressed: () => ref.read(uploadProvider.notifier).clearSelection(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => ref
                .read(uploadProvider.notifier)
                .uploadAndProcessPrescription(selectedState.file),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.35),
              elevation: 4,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: const Text('Analyze Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningTipsList(bool isDark) {
    final tips = [
      {'icon': Icons.lightbulb_outline_rounded, 'text': 'Avoid shadows and harsh direct reflections.'},
      {'icon': Icons.crop_free_rounded, 'text': 'Keep the prescription paper flat and aligned.'},
      {'icon': Icons.text_fields_rounded, 'text': 'Ensure the doctor’s handwriting is fully legible.'},
    ];

    return Column(
      key: const ValueKey('tips'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scanning Guidelines',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 10),
        Column(
          children: List.generate(
            tips.length,
            (idx) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceCardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(tips[idx]['icon'] as IconData, color: const Color(0xFF6C63FF), size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tips[idx]['text'] as String,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// Custom Painter for Auto-detection corner frames
// ==========================================
class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double lineLength = 24.0;
    const double padding = 16.0;

    // Top-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, padding + lineLength)
        ..lineTo(padding, padding)
        ..lineTo(padding + lineLength, padding),
      paint,
    );

    // Top-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - lineLength, padding)
        ..lineTo(size.width - padding, padding)
        ..lineTo(size.width - padding, padding + lineLength),
      paint,
    );

    // Bottom-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, size.height - padding - lineLength)
        ..lineTo(padding, size.height - padding)
        ..lineTo(padding + lineLength, size.height - padding),
      paint,
    );

    // Bottom-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - lineLength, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding - lineLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
