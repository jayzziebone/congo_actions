import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/data_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class DonorSubscriptionsScreen extends ConsumerWidget {
  const DonorSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final subscriptions = ref.watch(subscriptionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('My Pledges & Subscriptions'),
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Explanatory banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundIceBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardOutline),
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat_rounded, color: AppTheme.ceruleanBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Sustaining Monthly Change',
                          style: TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Card plans bill automatically. Mobile Money pledges trigger a 1-tap USSD prompt each month.',
                          style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Active Subscriptions & Pledges',
              style: TextStyle(
                color: AppTheme.textSlateNavy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (subscriptions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No active subscriptions found.', style: TextStyle(color: AppTheme.textMutedGray)),
                ),
              ),
            ...subscriptions.map((sub) => _buildSubscriptionCard(context, ref, sub, currency)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
    AppCurrency currency,
  ) {
    final isMobileMoney = sub.paymentRail == 'MOBILE_MONEY_PLEDGE';
    final amountStr = CurrencyNotifier.formatAmount(
      amountUsdCents: sub.amountUsdCents,
      amountCdf: sub.amountCdf,
      activeCurrency: currency,
    );
    final dateStr = DateFormat('dd MMM yyyy').format(sub.nextBillingDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: sub.actionNeededToday ? AppTheme.pastelRose.withOpacity(0.3) : AppTheme.backgroundIceBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: sub.actionNeededToday ? AppTheme.pastelRose : AppTheme.cardOutline,
          width: sub.actionNeededToday ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amountStr,
                style: const TextStyle(
                  color: AppTheme.textSlateNavy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (sub.actionNeededToday)
                PastelBadge.urgent()
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sub.status == 'ACTIVE' ? AppTheme.pastelMint : AppTheme.powderBlue,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    sub.status,
                    style: TextStyle(
                      color: sub.status == 'ACTIVE' ? AppTheme.mintGreen : AppTheme.textSlateNavy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub.campaignTitle,
            style: const TextStyle(
              color: AppTheme.textSlateNavy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isMobileMoney ? Icons.phone_android_rounded : Icons.credit_card_rounded,
                size: 14,
                color: AppTheme.textMutedGray,
              ),
              const SizedBox(width: 4),
              Text(
                isMobileMoney ? 'Mobile Money Pledge (${sub.phoneNumber})' : 'International Card Auto-Debit',
                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.cardOutline, height: 1),
          const SizedBox(height: 12),
          // Action row
          if (sub.actionNeededToday) ...[
            const Text(
              'Your monthly pledge renewal is due today. Tap below to prompt your phone with the USSD PIN authorization.',
              style: TextStyle(color: AppTheme.roseText, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: '1-Tap Authorize Renewal via USSD',
              height: 46,
              icon: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
              onPressed: () async {
                await SupabaseService.instance.renewMobileMoneyPledge(sub.id);
                refreshAllData(ref);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('USSD Push sent to phone! Monthly pledge renewed successfully.')),
                );
              },
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Renewal: $dateStr',
                  style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        if (sub.status == 'ACTIVE') {
                          await SupabaseService.instance.pauseSubscription(sub.id);
                        } else {
                          await SupabaseService.instance.resumeSubscription(sub.id);
                        }
                        refreshAllData(ref);
                      },
                      child: Text(
                        sub.status == 'ACTIVE' ? 'Pause' : 'Resume',
                        style: const TextStyle(color: AppTheme.ceruleanBlue, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
