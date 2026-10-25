import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/data_providers.dart';
import '../../core/state/donation_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class PooledFundScreen extends ConsumerStatefulWidget {
  const PooledFundScreen({super.key});

  @override
  ConsumerState<PooledFundScreen> createState() => _PooledFundScreenState();
}

class _PooledFundScreenState extends ConsumerState<PooledFundScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final campaigns = ref.watch(campaignsProvider);
    final pooledCampaign = campaigns.firstWhere(
      (c) => c.isPooledFund,
      orElse: () => campaigns.first,
    );

    final totalRaisedStr = CurrencyNotifier.formatAmount(
      amountUsdCents: pooledCampaign.raisedAmountUsdCents,
      amountCdf: pooledCampaign.raisedAmountCdf,
      activeCurrency: currency,
    );

    final colors = [
      AppTheme.ceruleanBlue,
      AppTheme.terracottaIcon,
      AppTheme.warmOchre,
    ];

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('Pooled Redistribution Fund'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/donor');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Text(
                'Eastern DRC Emergency & Health Relief Pool',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textSlateNavy,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Donations to this pool are mathematically divided and disbursed across 3 vetted organizations according to audited need ratios.',
                style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              // Interactive Donut Chart Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 4,
                              centerSpaceRadius: 60,
                              sections: List.generate(pooledCampaign.splits.length, (i) {
                                final isTouched = i == _touchedIndex;
                                final fontSize = isTouched ? 16.0 : 13.0;
                                final radius = isTouched ? 34.0 : 28.0;
                                final split = pooledCampaign.splits[i];
                                return PieChartSectionData(
                                  color: colors[i % colors.length],
                                  value: split.percentage,
                                  title: '${split.percentage.toInt()}%',
                                  radius: radius,
                                  titleStyle: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                );
                              }),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totalRaisedStr,
                                style: const TextStyle(
                                  color: AppTheme.textSlateNavy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const Text(
                                'Pooled Capital',
                                style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Automated Ledger Allocation Formula',
                      style: TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Participating NGOs List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Beneficiary NGOs in this Pool',
                    style: TextStyle(
                      color: AppTheme.textSlateNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '3 Organizations',
                    style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(pooledCampaign.splits.length, (index) {
                final split = pooledCampaign.splits[index];
                final color = colors[index % colors.length];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundIceBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardOutline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${split.percentage.toInt()}%',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              split.ngoName,
                              style: const TextStyle(
                                color: AppTheme.textSlateNavy,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              index == 0
                                  ? 'Maternal care, surgical triage & gynecological oncology'
                                  : (index == 1
                                      ? 'Solar deep wells & anti-cholera water sanitation'
                                      : 'Orphan nutrition, clothing & primary education'),
                              style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppTheme.surfacePureWhite,
          border: Border(top: BorderSide(color: AppTheme.cardOutline, width: 1)),
        ),
        child: SafeArea(
          child: PillButton(
            label: 'Contribute to this Pooled Fund',
            icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            onPressed: () {
              ref.read(donationFlowProvider.notifier).setCampaign(pooledCampaign);
              context.push('/donor/donate');
            },
          ),
        ),
      ),
    );
  }
}
