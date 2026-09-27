import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';
import '../core/routes/app_router.dart';
import '../services/api_service.dart';
import '../services/prescription_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'onboarding_screen.dart'; // Import BackgroundPatternPainter for visual branding consistency

class PrescriptionResultScreen extends ConsumerStatefulWidget {
  const PrescriptionResultScreen({super.key});

  @override
  ConsumerState<PrescriptionResultScreen> createState() => _PrescriptionResultScreenState();
}

class _PrescriptionResultScreenState extends ConsumerState<PrescriptionResultScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {
      _searchQuery = val.trim().toLowerCase();
    });
  }

  Future<void> _deletePrescription(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to permanently delete this health record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.deletePrescription(id);
        ref.invalidate(prescriptionsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescription record deleted successfully.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete record: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareRecord(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Prescription Record';
    final shareText = 'MediScribeAI Prescription PDF: https://mediscribe.ai/shared/rx/${data['id']}';
    await Clipboard.setData(ClipboardData(text: shareText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied shareable link for "$title" to clipboard!'),
          backgroundColor: const Color(0xFF6C63FF),
        ),
      );
    }
  }

  void _downloadPDF(Map<String, dynamic> data) {
    // Shows a premium mock PDF downloading progress micro-interaction
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _DownloadProgressDialog(
          title: data['title'] as String? ?? 'Prescription PDF',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prescriptionsAsync = ref.watch(prescriptionsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background layout pattern
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: BackgroundPatternPainter(),
              ),
            ),
          ),

          SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: const Text(
                    'Health Records',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => ref.invalidate(prescriptionsProvider),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: _buildSearchBar(isDark),
                  ),
                ),
              ],
              body: RefreshIndicator(
                color: const Color(0xFF6C63FF),
                onRefresh: () async => ref.invalidate(prescriptionsProvider),
                child: prescriptionsAsync.when(
                  loading: () => _buildLoadingState(),
                  error: (err, _) => _buildErrorState(err.toString()),
                  data: (prescriptions) {
                    final filteredList = prescriptions.where((item) {
                      if (_searchQuery.isEmpty) return true;
                      final title = (item['title'] as String? ?? '').toLowerCase();
                      final doctor = (item['doctor_name'] as String? ?? '').toLowerCase();
                      final hosp = (item['hospital_name'] as String? ?? '').toLowerCase();
                      return title.contains(_searchQuery) ||
                          doctor.contains(_searchQuery) ||
                          hosp.contains(_searchQuery);
                    }).toList();

                    if (prescriptions.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.description_rounded,
                        title: 'No Prescriptions Scanned',
                        message:
                            'Scan a prescription using OCR to get started. Your interpreted records will automatically appear here.',
                        actionLabel: 'Scan Now',
                        onAction: () => context.push(AppRouter.scan),
                      );
                    }

                    if (filteredList.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 56, color: Color(0xFF6C63FF)),
                              const SizedBox(height: 16),
                              const Text(
                                "No Records Found",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "We couldn't find any prescriptions matching '$_searchQuery'. Try checking spelling.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      itemCount: filteredList.length,
                      itemBuilder: (ctx, i) {
                        final item = filteredList[i];
                        final isFirst = i == 0;
                        final isLast = i == filteredList.length - 1;
                        return _buildTimelineItem(item, isDark, i, isFirst, isLast);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'scan_fab',
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRouter.scan),
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan Prescription', style: TextStyle(fontWeight: FontWeight.bold)),
      )
          .animate()
          .fadeIn(delay: 200.ms)
          .slideY(begin: 0.3, end: 0, delay: 200.ms),
    );
  }

  // ==========================================
  // Layout Components
  // ==========================================

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          icon: const Icon(Icons.search_rounded, color: Color(0xFF6C63FF)),
          hintText: 'Search by title, doctor, or hospital...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          hintStyle: TextStyle(
            color: isDark ? AppColors.textPlaceholderDark : AppColors.textPlaceholderLight,
            fontSize: 14,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF6B7280), size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> data, bool isDark, int idx, bool isFirst, bool isLast) {
    final title = data['title'] as String? ?? 'Prescription Record #${idx + 1}';
    final doctor = data['doctor_name'] as String? ?? 'Unknown Practitioner';
    final hospital = data['hospital_name'] as String? ?? 'General Health Clinic';
    final date = data['prescribed_date'] as String? ?? 'No date';
    final medicines = data['medicines'] as List? ?? [];
    final status = data['status'] as String? ?? 'active';

    final isActive = status == 'active';
    final statusColor = isActive ? const Color(0xFF10B981) : const Color(0xFF6B7280);
    final statusBg = isActive ? const Color(0xFF10B981).withValues(alpha: 0.08) : const Color(0xFFEEF2F6);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Indicator Column
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Connecting vertical line
                Positioned(
                  top: isFirst ? 24 : 0,
                  bottom: isLast ? 24 : 0,
                  child: Container(
                    width: 2.5,
                    color: const Color(0xFFEEF0FD),
                  ),
                ),
                // Circular dot marker
                Positioned(
                  top: 20,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6C63FF),
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Main timeline details card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceCardDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '$doctor · $hospital',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(
                              'Prescribed: $date',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Extracted list summary
                  if (medicines.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXTRACTED DRUGS (${medicines.length})',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9CA3AF),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: List.generate(
                              medicines.length,
                              (mIdx) {
                                final med = medicines[mIdx];
                                final name = med is Map ? (med['medicine_name'] ?? 'Med') : med.toString();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF0FD),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(),

                  // Bottom Actions bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _shareRecord(data),
                          icon: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF6C63FF)),
                          label: const Text('Share', style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF))),
                        ),
                        TextButton.icon(
                          onPressed: () => _downloadPDF(data),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFF6C63FF)),
                          label: const Text('PDF', style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF))),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _deletePrescription(data['id'] as String),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SkeletonBox(width: double.infinity, height: 120, borderRadius: AppSpacing.borderRadiusLg),
            const SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 120, borderRadius: AppSpacing.borderRadiusLg),
            const SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 120, borderRadius: AppSpacing.borderRadiusLg),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            const Text(
              'Failed to load health records',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(prescriptionsProvider),
              icon: const Icon(Icons.refresh_rounded),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Downloading progress dialog widget
// ==========================================
class _DownloadProgressDialog extends StatefulWidget {
  final String title;

  const _DownloadProgressDialog({required this.title});

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  int _progress = 0;
  late final Stream<int> _downloadStream;

  @override
  void initState() {
    super.initState();
    // Simulate downloading progress
    _downloadStream = Stream<int>.periodic(
      const Duration(milliseconds: 150),
      (count) => (count + 1) * 10,
    ).take(11);

    _downloadStream.listen(
      (p) {
        if (mounted) {
          setState(() {
            _progress = p > 100 ? 100 : p;
          });
          if (_progress == 100) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloaded "${widget.title}" successfully!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Downloading Record'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Generating PDF printout for "${widget.title}"...'),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _progress / 100,
            backgroundColor: const Color(0xFFEEF0FD),
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_progress%',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }
}
