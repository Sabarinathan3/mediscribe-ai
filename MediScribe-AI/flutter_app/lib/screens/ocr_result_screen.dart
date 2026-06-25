import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/routes/app_router.dart';
import '../models/medicine_model.dart';
import '../widgets/medicine_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';

class OCRResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> ocrData;
  const OCRResultScreen({super.key, required this.ocrData});

  @override
  ConsumerState<OCRResultScreen> createState() => _OCRResultScreenState();
}

class _OCRResultScreenState extends ConsumerState<OCRResultScreen> {
  List<MedicineModel> _medicines = [];
  List<String> _errors = [];
  Map<String, dynamic> _ocrMeta = {};

  @override
  void initState() {
    super.initState();
    _parseMedicines();
  }

  void _parseMedicines() {
    try {
      _errors = List<String>.from(widget.ocrData['errors'] ?? []);
      _ocrMeta = widget.ocrData['ocr_metadata'] as Map<String, dynamic>? ?? {};

      final rawMeds = widget.ocrData['medications'] as List? ?? [];
      _medicines = rawMeds.map((m) {
        final map = m as Map<String, dynamic>;
        return MedicineModel(
          id: '',
          name: map['medicine'] as String? ?? 'Unknown',
          dosage: map['dosage'] as String? ?? '—',
          frequency: map['frequency'] as String? ?? '—',
          duration: map['duration'] as String? ?? '—',
          instruction: map['instruction'] as String? ?? '',
          translatedInstruction: map['translated_instruction'] as String?,
          audioBase64: map['audio_base64'] as String?,
        );
      }).toList();
    } catch (_) {
      _medicines = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confidence = (_ocrMeta['abbreviation_resolution_confidence'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
            tooltip: 'Share',
          ),
        ],
      ),
      body: _medicines.isEmpty
          ? EmptyStateWidget(
              icon: Icons.find_in_page_rounded,
              title: 'No Medicines Found',
              message: 'The OCR could not extract medicine data from this image. Try a clearer photo.',
              actionLabel: 'Scan Again',
              onAction: () => context.pop(),
            )
          : CustomScrollView(
              slivers: [
                // Header summary card
                SliverToBoxAdapter(
                  child: _buildSummaryCard(isDark, confidence),
                ),

                // Error banner
                if (_errors.isNotEmpty)
                  SliverToBoxAdapter(child: _buildErrorBanner(isDark)),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      AppSpacing.xl,
                      AppSpacing.pageHorizontal,
                      AppSpacing.lg,
                    ),
                    child: SectionHeader(
                      title: '${_medicines.length} Medicine${_medicines.length != 1 ? 's' : ''} Found',
                    ),
                  ),
                ),

                // Medicine cards
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    0,
                    AppSpacing.pageHorizontal,
                    120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => MedicineCard(
                        medicine: _medicines[i],
                        animationIndex: i,
                        onAddReminder: () => _showAddReminderQuickDialog(context, _medicines[i]),
                        onTap: () => context.push(
                          AppRouter.medicineDetails,
                          extra: {
                            'medicineData': {
                              'id': _medicines[i].id,
                              'medicine': _medicines[i].name,
                              'dosage': _medicines[i].dosage,
                              'frequency': _medicines[i].frequency,
                              'duration': _medicines[i].duration,
                              'instruction': _medicines[i].instruction,
                              'translated_instruction': _medicines[i].translatedInstruction,
                              'audio_base64': _medicines[i].audioBase64,
                              'interactions': _medicines[i].interactions
                                  .map((x) => x.toJson())
                                  .toList(),
                            },
                            'otherMedicines':
                                _medicines.map((m) => m.name).toList(),
                          },
                        ),
                      ),
                      childCount: _medicines.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(bool isDark, double confidence) {
    final percent = (confidence * 100).toInt();
    return Container(
      margin: const EdgeInsets.all(AppSpacing.pageHorizontal),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.dashboardHeaderGradient,
        borderRadius: AppSpacing.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Complete',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                AppSpacing.vGap8,
                Text(
                  '${_medicines.length} medicines · $percent% confidence',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                AppSpacing.vGap16,
                // Confidence bar
                ClipRRect(
                  borderRadius: AppSpacing.borderRadiusRound,
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      confidence > 0.7 ? AppColors.success : AppColors.warning,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGap20,
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$percent%',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.1, end: 0, duration: 450.ms);
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.danger, size: 18),
          AppSpacing.hGap8,
          Expanded(
            child: Text(
              _errors.first,
              style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  void _showAddReminderQuickDialog(BuildContext ctx, MedicineModel med) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Add Reminder for ${med.name}'),
        content: Text(
          'Go to the Reminders tab to schedule a notification for ${med.name} (${med.dosage}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.go(AppRouter.reminders);
            },
            child: const Text('Go to Reminders'),
          ),
        ],
      ),
    );
  }
}
