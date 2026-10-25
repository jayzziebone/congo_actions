import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/donation_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class DonationSetupScreen extends ConsumerStatefulWidget {
  const DonationSetupScreen({super.key});

  @override
  ConsumerState<DonationSetupScreen> createState() => _DonationSetupScreenState();
}

class _DonationSetupScreenState extends ConsumerState<DonationSetupScreen> {
  final List<int> _usdQuickPills = [500, 1000, 2500, 5000, 10000]; // cents: $5, $10, $25, $50, $100
  final List<int> _cdfQuickPills = [14000, 28000, 70000, 140000, 280000]; // FC: 14k, 28k, 70k, 140k, 280k

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final donationFlow = ref.watch(donationFlowProvider);
    final isUsd = currency == AppCurrency.usd;
    final campaign = donationFlow.selectedCampaign;

    final displayAmount = isUsd
        ? CurrencyNotifier.formatAmount(
            amountUsdCents: donationFlow.selectedAmountUsdCents,
            amountCdf: donationFlow.selectedAmountCdf,
            activeCurrency: currency,
          )
        : CurrencyNotifier.formatAmount(
            amountUsdCents: donationFlow.selectedAmountUsdCents,
            amountCdf: donationFlow.selectedAmountCdf,
            activeCurrency: currency,
          );

    final feeAmount = isUsd
        ? CurrencyNotifier.formatAmount(
            amountUsdCents: donationFlow.feeUsdCents,
            amountCdf: donationFlow.feeCdf,
            activeCurrency: currency,
          )
        : CurrencyNotifier.formatAmount(
            amountUsdCents: donationFlow.feeUsdCents,
            amountCdf: donationFlow.feeCdf,
            activeCurrency: currency,
          );

    final totalAmount = isUsd
        ? CurrencyNotifier.formatAmount(
            amountUsdCents: donationFlow.totalChargedUsdCents,
            amountCdf: donationFlow.totalChargedCdf,
            activeCurrency: currency,
          )
        : CurrencyNotifier.formatAmount(
            amountUsdCents: donationFlow.totalChargedUsdCents,
            amountCdf: donationFlow.totalChargedCdf,
            activeCurrency: currency,
          );

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('Donation Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CurrencyTogglePill(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cause summary card
              if (campaign != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundIceBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardOutline),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          campaign.imageUrl,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              campaign.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textSlateNavy,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              campaign.isPooledFund ? 'Pooled Cause Fund' : (campaign.ngoName ?? 'Direct NGO'),
                              style: const TextStyle(
                                color: AppTheme.textMutedGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Frequency Switch: One-Time vs Monthly Subscription
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFrequencyTab(
                        label: 'One-Time Donation',
                        isSelected: !donationFlow.isMonthlySubscription,
                        onTap: () => ref.read(donationFlowProvider.notifier).setFrequency(false),
                      ),
                    ),
                    Expanded(
                      child: _buildFrequencyTab(
                        label: 'Monthly Pledge',
                        isSelected: donationFlow.isMonthlySubscription,
                        badge: 'Recurring',
                        onTap: () => ref.read(donationFlowProvider.notifier).setFrequency(true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Big Amount Display
              Center(
                child: Column(
                  children: [
                    Text(
                      'Select Donation Amount',
                      style: TextStyle(
                        color: AppTheme.textMutedGray,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayAmount,
                      style: const TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Quick-Select Amount Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: isUsd
                    ? _usdQuickPills.map((cents) {
                        final isSelected = donationFlow.selectedAmountUsdCents == cents;
                        return _buildAmountPill(
                          label: '\$${cents ~/ 100}',
                          isSelected: isSelected,
                          onTap: () => ref.read(donationFlowProvider.notifier).setAmountUsdCents(cents),
                        );
                      }).toList()
                    : _cdfQuickPills.map((cdf) {
                        final isSelected = donationFlow.selectedAmountCdf == cdf;
                        return _buildAmountPill(
                          label: '${cdf ~/ 1000}k',
                          isSelected: isSelected,
                          onTap: () => ref.read(donationFlowProvider.notifier).setAmountCdf(cdf),
                        );
                      }).toList(),
              ),
              const SizedBox(height: 32),
              // Fee Coverage Toggle: "Add fee so 100% goes to the cause"
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.pastelMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppTheme.mintGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cover 3.5% Gateway Fee',
                            style: TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add $feeAmount so 100% of your donation reaches the field in Congo.',
                            style: const TextStyle(
                              color: AppTheme.textMutedGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: donationFlow.coverFees,
                      activeColor: AppTheme.ceruleanBlue,
                      onChanged: (val) => ref.read(donationFlowProvider.notifier).toggleCoverFees(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Anonymity Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.powderBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.visibility_off_outlined, color: AppTheme.ceruleanBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Donate Anonymously',
                            style: TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Hide your name from public donor lists and community feeds.',
                            style: TextStyle(
                              color: AppTheme.textMutedGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: donationFlow.isAnonymous,
                      activeColor: AppTheme.ceruleanBlue,
                      onChanged: (val) => ref.read(donationFlowProvider.notifier).toggleAnonymous(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Total calculation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Payment:',
                    style: TextStyle(
                      color: AppTheme.textSlateNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    totalAmount,
                    style: const TextStyle(
                      color: AppTheme.ceruleanBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
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
            label: 'Continue to Payment Method',
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            onPressed: () => context.push('/donor/checkout'),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyTab({
    required String label,
    required bool isSelected,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textSlateNavy : AppTheme.textMutedGray,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.pastelApricot,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppTheme.terracottaIcon,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ceruleanBlue : AppTheme.backgroundIceBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.ceruleanBlue : AppTheme.cardOutline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSlateNavy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
