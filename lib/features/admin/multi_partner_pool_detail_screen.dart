import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/data_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class MultiPartnerPoolDetailScreen extends ConsumerStatefulWidget {
  final String poolId;
  final Campaign? initialPool;

  const MultiPartnerPoolDetailScreen({
    super.key,
    required this.poolId,
    this.initialPool,
  });

  @override
  ConsumerState<MultiPartnerPoolDetailScreen> createState() => _MultiPartnerPoolDetailScreenState();
}

class _MultiPartnerPoolDetailScreenState extends ConsumerState<MultiPartnerPoolDetailScreen> {
  Campaign? _pool;
  bool _isLoading = true;
  bool _isSaving = false;

  // Split percentages mapped by CampaignSplit ID (or ngoId if id empty)
  final Map<String, double> _splitValues = {};

  final List<Color> _partnerColors = [
    AppTheme.ceruleanBlue,
    AppTheme.mintGreen,
    AppTheme.terracottaIcon,
    AppTheme.warmOchre,
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF06B6D4), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _loadPoolData();
  }

  void _loadPoolData() {
    Campaign? found = widget.initialPool;
    if (found == null) {
      final all = SupabaseService.instance.campaigns;
      try {
        found = all.firstWhere((c) => c.id == widget.poolId);
      } catch (_) {
        if (all.isNotEmpty) found = all.firstWhere((c) => c.isPooledFund, orElse: () => all.first);
      }
    }

    if (found != null) {
      _pool = found;
      _splitValues.clear();
      for (final split in found.splits) {
        final key = split.id.isNotEmpty ? split.id : split.ngoId;
        _splitValues[key] = split.percentage;
      }
    }

    setState(() => _isLoading = false);
  }

  double get _totalSum {
    if (_splitValues.isEmpty) return 0.0;
    return _splitValues.values.fold(0.0, (prev, val) => prev + val);
  }

  bool get _isSumValid => (_totalSum.round() == 100);

  void _distributeEvenly() {
    if (_pool == null || _pool!.splits.isEmpty) return;
    final count = _pool!.splits.length;
    final base = (100 / count).floorToDouble();
    double remainder = 100 - (base * count);

    setState(() {
      for (int i = 0; i < _pool!.splits.length; i++) {
        final split = _pool!.splits[i];
        final key = split.id.isNotEmpty ? split.id : split.ngoId;
        double val = base;
        if (remainder > 0) {
          val += 1.0;
          remainder -= 1.0;
        }
        _splitValues[key] = val;
      }
    });
  }

  Future<void> _saveSplits() async {
    if (_pool == null || !_isSumValid) return;

    setState(() => _isSaving = true);
    try {
      final updatedSplits = _pool!.splits.map((s) {
        final key = s.id.isNotEmpty ? s.id : s.ngoId;
        final newPct = _splitValues[key] ?? s.percentage;
        return CampaignSplit(
          id: s.id,
          ngoId: s.ngoId,
          ngoName: s.ngoName,
          percentage: newPct,
        );
      }).toList();

      await SupabaseService.instance.updateSplitPercentages(_pool!.id, updatedSplits);

      if (mounted) {
        ref.read(campaignsProvider.notifier).state = [...SupabaseService.instance.campaigns];
        setState(() {
          _pool = _pool!.copyWith(splits: updatedSplits);
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Multi-partner redistribution split successfully updated & verified!',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.mintGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update splits: $e'),
            backgroundColor: AppTheme.roseText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surfacePureWhite,
        appBar: AppBar(title: const Text('Multi-Partner Pool')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_pool == null) {
      return Scaffold(
        backgroundColor: AppTheme.surfacePureWhite,
        appBar: AppBar(title: const Text('Multi-Partner Pool')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.warmOchre),
              const SizedBox(height: 12),
              const Text('Pool Not Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/admin'),
                child: const Text('Return to SuperAdmin Console'),
              ),
            ],
          ),
        ),
      );
    }

    final pool = _pool!;
    final raisedStr = CurrencyNotifier.formatAmount(
      amountUsdCents: pool.raisedAmountUsdCents,
      amountCdf: pool.raisedAmountCdf,
      activeCurrency: currency,
    );
    final targetStr = CurrencyNotifier.formatAmount(
      amountUsdCents: pool.targetAmountUsdCents,
      amountCdf: pool.targetAmountCdf,
      activeCurrency: currency,
    );
    final progress = currency == AppCurrency.usd ? pool.progressRatioUsd : pool.progressRatioCdf;
    final totalSum = _totalSum;
    final isSumValid = _isSumValid;

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('Multi-Partner Pool Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textSlateNavy),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CurrencyTogglePill(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Hero Pool Header Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.backgroundIceBlue,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.cardOutline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row (Using Wrap to prevent RenderFlex overflow on small viewports)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.pastelMint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.mintGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.hub_rounded, size: 14, color: AppTheme.mintGreen),
                            SizedBox(width: 5),
                            Text(
                              'Active Consortium',
                              style: TextStyle(
                                color: AppTheme.mintGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfacePureWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardOutline),
                        ),
                        child: Text(
                          pool.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.ceruleanBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      PastelBadge.pooled(),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Pool Title
                  Text(
                    pool.title,
                    style: const TextStyle(
                      color: AppTheme.textSlateNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMutedGray),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pool.location,
                          style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Subtitle / Mission summary
                  if (pool.subtitle.isNotEmpty) ...[
                    Text(
                      pool.subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Progress and Volume Breakdown
                  const Divider(color: AppTheme.cardOutline, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pooled Capital', style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            raisedStr,
                            style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Target Goal', style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            targetStr,
                            style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.cardOutline,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.ceruleanBlue),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}% funded',
                        style: const TextStyle(color: AppTheme.ceruleanBlue, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${pool.splits.length} Participating Beneficiaries',
                          style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Campaigns & Partners Inside this Pool
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: AppTheme.textSlateNavy, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Campaigns & Partners in this Pool (${pool.splits.length})',
                    style: const TextStyle(
                      color: AppTheme.textSlateNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Incoming donor contributions to this pool are automatically disbursed into these partner sub-ledgers based on the formula below.',
              style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),

            // Partner Cards List
            ...List.generate(pool.splits.length, (index) {
              final split = pool.splits[index];
              final key = split.id.isNotEmpty ? split.id : split.ngoId;
              final currentPct = _splitValues[key] ?? split.percentage;
              final partnerColor = _partnerColors[index % _partnerColors.length];

              // Calculate calculated monetary share
              final shareUsdCents = (pool.raisedAmountUsdCents * (currentPct / 100)).toInt();
              final shareCdf = (pool.raisedAmountCdf * (currentPct / 100)).toInt();
              final shareStr = CurrencyNotifier.formatAmount(
                amountUsdCents: shareUsdCents,
                amountCdf: shareCdf,
                activeCurrency: currency,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfacePureWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.cardOutline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: partnerColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: partnerColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  split.ngoName,
                                  style: const TextStyle(
                                    color: AppTheme.textSlateNavy,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              PastelBadge.verified(compact: true),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Current Share: ',
                                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                              ),
                              Text(
                                shareStr,
                                style: TextStyle(
                                  color: partnerColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: partnerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: partnerColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${currentPct.toInt()}%',
                        style: TextStyle(
                          color: partnerColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Section: Multi-Partner Pooled Fund Redistribution Sliders
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.backgroundIceBlue,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.cardOutline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Redistribution Formula Sliders',
                          style: TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sum Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSumValid ? AppTheme.pastelMint : AppTheme.pastelRose,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSumValid ? AppTheme.mintGreen.withOpacity(0.4) : AppTheme.roseText.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSumValid ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              size: 14,
                              color: isSumValid ? AppTheme.mintGreen : AppTheme.roseText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSumValid ? 'Sum: 100%' : 'Sum: ${totalSum.round()}%',
                              style: TextStyle(
                                color: isSumValid ? AppTheme.mintGreen : AppTheme.roseText,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Slide to recalibrate redistribution shares. Total sum across all partners must equal exactly 100%.',
                    style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11, height: 1.35),
                  ),
                  const SizedBox(height: 16),

                  // Sliders List
                  ...List.generate(pool.splits.length, (index) {
                    final split = pool.splits[index];
                    final key = split.id.isNotEmpty ? split.id : split.ngoId;
                    final val = _splitValues[key] ?? split.percentage;
                    final partnerColor = _partnerColors[index % _partnerColors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  split.ngoName,
                                  style: const TextStyle(
                                    color: AppTheme.textSlateNavy,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${val.toInt()}%',
                                style: TextStyle(
                                  color: partnerColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: partnerColor,
                              thumbColor: partnerColor,
                              inactiveTrackColor: AppTheme.cardOutline,
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                            ),
                            child: Slider(
                              value: val,
                              min: 5,
                              max: 85,
                              divisions: 16,
                              onChanged: (newVal) {
                                setState(() {
                                  _splitValues[key] = newVal;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 4),

                  // Evenly Distribute Shortcut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.ceruleanBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.balance_rounded, size: 14),
                        label: const Text(
                          'Distribute Evenly',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        onPressed: _distributeEvenly,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSumValid ? AppTheme.ceruleanBlue : AppTheme.textMutedGray,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        elevation: 0,
                      ),
                      onPressed: (_isSaving || !isSumValid) ? null : _saveSplits,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  isSumValid
                                      ? 'Save Redistribution Split Formula'
                                      : 'Adjust Sliders to 100% (${totalSum.round()}%)',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
