import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/state/auth_state.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/donation_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class DonationSuccessScreen extends ConsumerWidget {
  const DonationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationFlow = ref.watch(donationFlowProvider);
    final currency = ref.watch(currencyProvider);
    final authState = ref.watch(authProvider);
    final donation = donationFlow.completedDonation;

    final formattedAmount = donation != null
        ? CurrencyNotifier.formatAmount(
            amountUsdCents: donation.amountUsdCents,
            amountCdf: donation.amountCdf,
            activeCurrency: currency,
          )
        : '\$25.00';

    final feeAmount = donation != null
        ? CurrencyNotifier.formatAmount(
            amountUsdCents: donation.feeCoveredUsdCents,
            amountCdf: donation.feeCoveredCdf,
            activeCurrency: currency,
          )
        : '\$0.88';

    final receiptNo = donation?.receiptNumber ?? 'RCP-2026-948102';
    final txRef = donation?.paymentReference ?? 'CA-TX-98412-MPESA';
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(donation?.createdAt ?? DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Success Checkmark with Soft Glow
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.pastelMint,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.mintGreen.withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, color: AppTheme.mintGreen, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Matondo Mingi! Thank You!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textSlateNavy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your gift has been debited and posted to the double-entry accounting ledger.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
              ),
              const SizedBox(height: 28),
              // Payment Breakdown Ticket Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  'Official Receipt',
                                  style: TextStyle(
                                    color: AppTheme.textSlateNavy,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              PastelBadge.verified(compact: true),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            formattedAmount,
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paid via ${donationFlow.selectedPaymentMethod.displayName}',
                            style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Ticket serrated divider line
                    Row(
                      children: List.generate(
                        25,
                        (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 1,
                            color: AppTheme.cardOutline,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildReceiptRow('Donor', authState.user?.fullName ?? 'Kind Supporter'),
                          const SizedBox(height: 10),
                          _buildReceiptRow(
                            'Cause / Pool',
                            donationFlow.selectedCampaign?.title ?? 'Eastern DRC Relief Pool',
                          ),
                          const SizedBox(height: 10),
                          _buildReceiptRow('Receipt #', receiptNo),
                          const SizedBox(height: 10),
                          _buildReceiptRow('Ledger Tx Ref', txRef),
                          const SizedBox(height: 10),
                          _buildReceiptRow('Gateway Fee Covered', feeAmount),
                          const SizedBox(height: 10),
                          _buildReceiptRow('Date & Time', dateStr),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Actions: Download PDF Receipt & Share on WhatsApp
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Receipt $receiptNo downloaded to device storage')),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, color: AppTheme.textSlateNavy, size: 20),
                      label: const Text(
                        'PDF Receipt',
                        style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening WhatsApp to share donation card...')),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PillButton(
                label: 'Return to Home',
                isSecondary: true,
                onPressed: () => context.go('/donor'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSlateNavy,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
