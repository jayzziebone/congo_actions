import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/donation_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class PaymentCheckoutScreen extends ConsumerStatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  ConsumerState<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends ConsumerState<PaymentCheckoutScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '+243810001234');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final donationFlow = ref.watch(donationFlowProvider);
    final isUsd = currency == AppCurrency.usd;

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
        title: const Text('Payment Method'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total to Pay',
                          style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalAmount,
                          style: const TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: donationFlow.isMonthlySubscription ? AppTheme.pastelApricot : AppTheme.powderBlue,
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      ),
                      child: Text(
                        donationFlow.isMonthlySubscription ? 'Monthly Pledge' : 'One-Time Gift',
                        style: TextStyle(
                          color: donationFlow.isMonthlySubscription ? AppTheme.terracottaIcon : AppTheme.ceruleanBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // DRC Domestic Mobile Money Section
              Row(
                children: const [
                  Text(
                    'DRC Mobile Money Rails',
                    style: TextStyle(
                      color: AppTheme.textSlateNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('🇨🇩', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Instant USSD push prompt will appear on your phone screen to enter PIN.',
                style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Mobile Money 2x2 Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMobileMoneyOption(
                    method: PaymentMethod.mpesa,
                    title: 'Vodacom M-Pesa',
                    badge: '*1122#',
                    accentColor: const Color(0xFFE60000),
                    selectedMethod: donationFlow.selectedPaymentMethod,
                  ),
                  _buildMobileMoneyOption(
                    method: PaymentMethod.orangeMoney,
                    title: 'Orange Money',
                    badge: '*144#',
                    accentColor: const Color(0xFFFF7900),
                    selectedMethod: donationFlow.selectedPaymentMethod,
                  ),
                  _buildMobileMoneyOption(
                    method: PaymentMethod.airtelMoney,
                    title: 'Airtel Money',
                    badge: '*501#',
                    accentColor: const Color(0xFFE40000),
                    selectedMethod: donationFlow.selectedPaymentMethod,
                  ),
                  _buildMobileMoneyOption(
                    method: PaymentMethod.afrimoney,
                    title: 'Africell Afrimoney',
                    badge: '*111#',
                    accentColor: const Color(0xFF8A2BE2),
                    selectedMethod: donationFlow.selectedPaymentMethod,
                  ),
                ],
              ),
              if (donationFlow.selectedPaymentMethod.isMobileMoney) ...[
                const SizedBox(height: 18),
                Text(
                  'Confirm Phone Number for USSD Push:',
                  style: TextStyle(
                    color: AppTheme.textSlateNavy,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_android_rounded, color: AppTheme.ceruleanBlue),
                    hintText: '+243 81 000 1234',
                  ),
                  onChanged: (val) => ref.read(donationFlowProvider.notifier).setPhoneNumber(val),
                ),
              ],
              const SizedBox(height: 32),
              // Diaspora & International Card Section
              Row(
                children: const [
                  Text(
                    'International Diaspora Rails',
                    style: TextStyle(
                      color: AppTheme.textSlateNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('🌍', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Processed via compliant secure browser session (Apple Guideline 3.2.1(vi)).',
                style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildCardOption(
                method: PaymentMethod.cardStripe,
                title: 'Visa / Mastercard / Apple Pay',
                subtitle: 'Stripe International Card Rails',
                icon: Icons.credit_card_rounded,
                selectedMethod: donationFlow.selectedPaymentMethod,
              ),
              const SizedBox(height: 12),
              _buildCardOption(
                method: PaymentMethod.cardFlutterwave,
                title: 'Pan-African & Global Debit/Credit',
                subtitle: 'Flutterwave Multi-Currency Gateway',
                icon: Icons.language_rounded,
                selectedMethod: donationFlow.selectedPaymentMethod,
              ),
              const SizedBox(height: 28),
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
            label: donationFlow.selectedPaymentMethod.isMobileMoney
                ? 'Send USSD Prompt to Phone'
                : 'Authorize Card Payment',
            icon: Icon(
              donationFlow.selectedPaymentMethod.isMobileMoney
                  ? Icons.touch_app_rounded
                  : Icons.lock_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              if (donationFlow.selectedPaymentMethod.isMobileMoney) {
                ref.read(donationFlowProvider.notifier).resetUssdTimer();
                context.push('/donor/ussd-waiting');
              } else {
                // For cards: simulate successful web checkout or direct success
                context.push('/donor/ussd-waiting');
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMoneyOption({
    required PaymentMethod method,
    required String title,
    required String badge,
    required Color accentColor,
    required PaymentMethod selectedMethod,
  }) {
    final isSelected = selectedMethod == method;

    return GestureDetector(
      onTap: () => ref.read(donationFlowProvider.notifier).setPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.powderBlue.withOpacity(0.5) : AppTheme.backgroundIceBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.ceruleanBlue : AppTheme.cardOutline,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppTheme.ceruleanBlue, size: 18)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMutedGray),
                    ),
                  ),
              ],
            ),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textSlateNavy,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOption({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required PaymentMethod selectedMethod,
  }) {
    final isSelected = selectedMethod == method;

    return GestureDetector(
      onTap: () => ref.read(donationFlowProvider.notifier).setPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.powderBlue.withOpacity(0.5) : AppTheme.backgroundIceBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.ceruleanBlue : AppTheme.cardOutline,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.textSlateNavy, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textSlateNavy,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.ceruleanBlue, size: 20),
          ],
        ),
      ),
    );
  }
}
