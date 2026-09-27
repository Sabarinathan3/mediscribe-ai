import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/theme/app_theme.dart';
import '../models/medicine_model.dart';
import '../services/tts_service.dart';

class MedicineDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> medicineData;
  final List<String> otherMedicines;

  const MedicineDetailsScreen({
    super.key,
    required this.medicineData,
    this.otherMedicines = const [],
  });

  @override
  ConsumerState<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends ConsumerState<MedicineDetailsScreen> {
  late MedicineModel _medicine;
  bool _showVoiceSettings = false;
  final Map<String, bool> _expandedInteractions = {};

  @override
  void initState() {
    super.initState();
    _medicine = MedicineModel.fromJson(widget.medicineData);
    _computeLocalInteractions();
  }

  // Locally computes interactions using the backend rules catalog for demo/testing robustness
  void _computeLocalInteractions() {
    if (_medicine.interactions.isNotEmpty) return;

    final String currentMed = _medicine.name.toLowerCase().trim();
    final List<DrugInteractionModel> detectedInteractions = [];

    // Offline catalogs for high reliability
    final List<Map<String, dynamic>> interactionCatalog = [
      {
        "pair": {"aspirin", "warfarin"},
        "severity": "critical",
        "desc": "Co-administration of aspirin and warfarin significantly increases risk of major gastrointestinal and systemic bleeding."
      },
      {
        "pair": {"ibuprofen", "warfarin"},
        "severity": "critical",
        "desc": "Concomitant use of NSAIDs like ibuprofen with warfarin may lead to severe mucosal bleeding and gastric ulcers."
      },
      {
        "pair": {"aspirin", "ibuprofen"},
        "severity": "moderate",
        "desc": "Ibuprofen can interfere with the antiplatelet effect of low-dose aspirin, reducing its cardioprotective benefits."
      },
      {
        "pair": {"sildenafil", "nitroglycerin"},
        "severity": "critical",
        "desc": "Sildenafil co-prescribed with organic nitrates (nitroglycerin) causes severe, synergistic peripheral vasodilation and acute hypotension."
      },
      {
        "pair": {"lisinopril", "potassium"},
        "severity": "moderate",
        "desc": "Lisinopril impairs potassium excretion. Concomitant potassium supplements may lead to severe hyperkalemia."
      },
      {
        "pair": {"simvastatin", "amlodipine"},
        "severity": "moderate",
        "desc": "Amlodipine increases systemic exposure to simvastatin, increasing the risk of rhabdomyolysis and myopathy."
      },
      {
        "pair": {"omeprazole", "clopidogrel"},
        "severity": "moderate",
        "desc": "Omeprazole decreases the active metabolite of clopidogrel, potentially lowering its efficacy in preventing blood clots."
      }
    ];

    for (var other in widget.otherMedicines) {
      final String otherMed = other.toLowerCase().trim();
      if (currentMed == otherMed) continue;

      for (var entry in interactionCatalog) {
        final Set<String> pair = entry["pair"] as Set<String>;
        if (pair.contains(currentMed) && pair.contains(otherMed)) {
          detectedInteractions.add(DrugInteractionModel(
            sourceDrug: _medicine.name,
            targetDrug: other,
            severity: entry["severity"],
            descriptionEn: entry["desc"],
            descriptionEs: entry["desc"],
          ));
        }
      }
    }

    if (detectedInteractions.isNotEmpty) {
      setState(() {
        _medicine = MedicineModel(
          id: _medicine.id,
          name: _medicine.name,
          dosage: _medicine.dosage,
          frequency: _medicine.frequency,
          duration: _medicine.duration,
          instruction: _medicine.instruction,
          translatedInstruction: _medicine.translatedInstruction,
          audioBase64: _medicine.audioBase64,
          interactions: detectedInteractions,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ttsState = ref.watch(ttsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Error State Handling if medicine details are empty or broken
    if (_medicine.name.isEmpty) {
      return _buildErrorState();
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium Transparent Custom AppBar
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: Text(
                _medicine.name,
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF090D16)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                ref.read(ttsNotifierProvider.notifier).stop();
                context.pop();
              },
            ),
          ),

          // 2. Main Content Body
          SliverPadding(
            padding: AppSpacing.edgeInsetsAll16,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Medicine Hero info card
                _buildHeroCard(isDark),
                AppSpacing.vGap24,

                // Core details cards grid
                _buildDetailsGrid(isDark),
                AppSpacing.vGap24,

                // Voice explanation controller
                _buildVoiceExplanationCard(ttsState, isDark),
                AppSpacing.vGap24,

                // Drug interactions listing
                _buildInteractionsCard(isDark),
                const SizedBox(height: 48), // Padding bottom
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Premium Hero Header card
  Widget _buildHeroCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: isDark ? AppTheme.premiumShadowDark : AppTheme.premiumShadowLight,
      ),
      padding: AppSpacing.edgeInsetsAll24,
      child: Row(
        children: [
          Container(
            padding: AppSpacing.edgeInsetsAll16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medication_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          AppSpacing.hGap16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MEDICATION DETAILS',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
                AppSpacing.vGap4,
                Text(
                  _medicine.name,
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                AppSpacing.vGap8,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: AppSpacing.borderRadiusRound,
                  ),
                  child: Text(
                    'Active Prescription Item',
                    style: AppTypography.labelMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Details Grid: Dosage, Frequency, Duration, Instructions
  Widget _buildDetailsGrid(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailGridItem(
                icon: Icons.scale_rounded,
                title: 'Dosage',
                value: _medicine.dosage.isNotEmpty ? _medicine.dosage : 'Not Specified',
                isDark: isDark,
              ),
            ),
            AppSpacing.hGap12,
            Expanded(
              child: _buildDetailGridItem(
                icon: Icons.event_repeat_rounded,
                title: 'Frequency',
                value: _medicine.frequency.isNotEmpty ? _medicine.frequency : 'As Directed',
                isDark: isDark,
              ),
            ),
          ],
        ),
        AppSpacing.vGap12,
        Row(
          children: [
            Expanded(
              child: _buildDetailGridItem(
                icon: Icons.calendar_today_rounded,
                title: 'Duration',
                value: _medicine.duration.isNotEmpty ? _medicine.duration : 'As Directed',
                isDark: isDark,
              ),
            ),
            AppSpacing.hGap12,
            Expanded(
              child: _buildDetailGridItem(
                icon: Icons.info_outline_rounded,
                title: 'Instructions',
                value: _medicine.instruction.isNotEmpty ? _medicine.instruction : 'None Specified',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailGridItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: AppSpacing.edgeInsetsAll16,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark ? AppTheme.premiumShadowDark : AppTheme.premiumShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryTeal, size: 20),
              AppSpacing.hGap8,
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          AppSpacing.vGap12,
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Voice Explanation Card
  Widget _buildVoiceExplanationCard(TtsState ttsState, bool isDark) {
    final bool isPlaying = ttsState.playState == TtsPlayState.playing;
    final String speechText = _medicine.translatedInstruction ?? _medicine.instruction;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark ? AppTheme.premiumShadowDark : AppTheme.premiumShadowLight,
      ),
      padding: AppSpacing.edgeInsetsAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.spatial_audio_off_rounded, color: AppColors.primaryTeal, size: 24),
                  AppSpacing.hGap12,
                  Text(
                    'Voice Explanation',
                    style: AppTypography.titleLarge.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _showVoiceSettings ? Icons.tune_rounded : Icons.tune_rounded,
                  color: _showVoiceSettings ? AppColors.primaryTeal : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showVoiceSettings = !_showVoiceSettings;
                  });
                },
              ),
            ],
          ),
          AppSpacing.vGap16,

          // Pulsing visual wave container
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            alignment: Alignment.center,
            child: PulsingVoiceWave(isPlaying: isPlaying),
          ),
          AppSpacing.vGap16,

          // Voice explanation text content
          Text(
            speechText.isNotEmpty ? speechText : 'No instructions voice text available.',
            style: AppTypography.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGap24,

          // Play/Stop control bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed factor label
              Text(
                'Speed: ${ttsState.speed.toStringAsFixed(1)}x',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? AppColors.textPlaceholderDark : AppColors.textPlaceholderLight,
                ),
              ),
              const Spacer(),
              
              // Core Play/Pause button
              InkWell(
                onTap: () {
                  final notifier = ref.read(ttsNotifierProvider.notifier);
                  if (isPlaying) {
                    notifier.stop();
                  } else {
                    notifier.speak(speechText);
                  }
                },
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3D0F766E),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const Spacer(),

              // Translation Target badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusRound,
                ),
                child: Text(
                  _medicine.translatedInstruction != null ? 'Multilingual TTS' : 'English TTS',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primaryTeal),
                ),
              ),
            ],
          ),

          // Expandable voice customization options
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                AppSpacing.vGap24,
                const Divider(),
                AppSpacing.vGap16,
                Row(
                  children: [
                    const Icon(Icons.speed_rounded, size: 20, color: Colors.grey),
                    AppSpacing.hGap12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Speech Speed',
                            style: AppTypography.labelMedium.copyWith(color: Colors.grey),
                          ),
                          Slider(
                            value: ttsState.speed,
                            min: 0.3,
                            max: 1.0,
                            divisions: 7,
                            activeColor: AppColors.primaryTeal,
                            onChanged: (val) {
                              ref.read(ttsNotifierProvider.notifier).setSpeed(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGap8,
                Row(
                  children: [
                    const Icon(Icons.volume_up_rounded, size: 20, color: Colors.grey),
                    AppSpacing.hGap12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volume Level',
                            style: AppTypography.labelMedium.copyWith(color: Colors.grey),
                          ),
                          Slider(
                            value: ttsState.volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            activeColor: AppColors.primaryTeal,
                            onChanged: (val) {
                              ref.read(ttsNotifierProvider.notifier).setVolume(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            crossFadeState: _showVoiceSettings ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // Drug Interactions Card
  Widget _buildInteractionsCard(bool isDark) {
    final List<DrugInteractionModel> interactions = _medicine.interactions;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark ? AppTheme.premiumShadowDark : AppTheme.premiumShadowLight,
      ),
      padding: AppSpacing.edgeInsetsAll16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.report_problem_rounded, color: AppColors.primaryTeal, size: 24),
              AppSpacing.hGap12,
              Text(
                'Drug Interactions',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          AppSpacing.vGap16,

          if (interactions.isEmpty)
            // Premium Safe State indicator
            Container(
              padding: AppSpacing.edgeInsetsAll16,
              decoration: BoxDecoration(
                color: AppColors.successLight.withValues(alpha: 0.15),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                  AppSpacing.hGap12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Known Interactions',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.vGap4,
                        Text(
                          'No interaction risks detected with other medicines in this prescription.',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: interactions.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final interaction = interactions[index];
                final bool isCritical = interaction.severity.toLowerCase() == 'critical';
                final Color tagColor = isCritical ? AppColors.danger : AppColors.warning;
                final Color tagBg = isCritical ? AppColors.dangerLight : AppColors.warningLight;
                final bool isExpanded = _expandedInteractions[interaction.targetDrug] ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: AppSpacing.borderRadiusRound,
                          ),
                          child: Text(
                            interaction.severity.toUpperCase(),
                            style: AppTypography.labelMedium.copyWith(
                              color: tagColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        AppSpacing.hGap12,
                        Expanded(
                          child: Text(
                            'Interaction with ${interaction.targetDrug}',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _expandedInteractions[interaction.targetDrug] = !isExpanded;
                            });
                          },
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                        child: Text(
                          interaction.descriptionEn,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // Error/Empty State screen layout
  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: AppSpacing.edgeInsetsAll24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: AppColors.danger,
              ),
              AppSpacing.vGap24,
              Text(
                'Invalid Medicine Details',
                style: AppTypography.titleLarge,
              ),
              AppSpacing.vGap8,
              Text(
                'The system could not load the specification data for this item.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGap32,
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Custom Pulsing voice wave painting
// ==========================================
class PulsingVoiceWave extends StatefulWidget {
  final bool isPlaying;
  const PulsingVoiceWave({super.key, required this.isPlaying});

  @override
  State<PulsingVoiceWave> createState() => _PulsingVoiceWaveState();
}

class _PulsingVoiceWaveState extends State<PulsingVoiceWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulsingVoiceWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(_controller.value, widget.isPlaying),
          size: const Size(180, 50),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  WavePainter(this.progress, this.isPlaying);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryTeal
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double width = size.width;
    final double height = size.height;
    final double centerY = height / 2;
    final int barCount = 19;
    final double spacing = width / barCount;

    for (int i = 0; i < barCount; i++) {
      double relativeX = i * spacing + spacing / 2;
      double factor;
      if (isPlaying) {
        factor = math.sin((progress * 2 * math.pi) + (i * 0.4));
      } else {
        factor = 0.08;
      }
      double barHeight = (centerY * 0.75) * factor.abs() + 2.5;

      canvas.drawLine(
        Offset(relativeX, centerY - barHeight),
        Offset(relativeX, centerY + barHeight),
        paint..color = AppColors.primaryTeal.withValues(alpha: 0.3 + (factor.abs() * 0.7)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
  }
}
