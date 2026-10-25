import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/data_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class NgoWithdrawalScreen extends ConsumerStatefulWidget {
  const NgoWithdrawalScreen({super.key});

  @override
  ConsumerState<NgoWithdrawalScreen> createState() => _NgoWithdrawalScreenState();
}

class _NgoWithdrawalScreenState extends ConsumerState<NgoWithdrawalScreen> {
  String _destinationType = 'BANK_RIB'; // 'BANK_RIB' or 'MOBILE_MONEY'
  String _amountInput = '2500'; // Default $2,500
  bool _isSubmitting = false;

  void _onKeypadTap(String val) {
    if (_amountInput.length < 7) {
      setState(() => _amountInput += val);
    }
  }

  void _onBackspace() {
    if (_amountInput.isNotEmpty) {
      setState(() => _amountInput = _amountInput.substring(0, _amountInput.length - 1));
    }
  }

  void _showBiometricPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfacePureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppTheme.powderBlue,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.fingerprint_rounded, size: 40, color: AppTheme.ceruleanBlue),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Biometric Authentication',
                style: TextStyle(
                  color: AppTheme.textSlateNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Confirm FaceID or Fingerprint to sign and authorize withdrawal from Fondation Panzi treasury.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
              ),
              const SizedBox(height: 24),
              PillButton(
                label: 'Authenticate with FaceID / Biometrics',
                icon: const Icon(Icons.fingerprint, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.pop(context);
                  _executeWithdrawal();
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.roseText)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeWithdrawal() async {
    setState(() => _isSubmitting = true);
    final currency = ref.read(currencyProvider);
    final amountInt = int.tryParse(_amountInput) ?? 1000;
    final amountUsdCents = amountInt * 100;
    final amountCdf = amountInt * 2800;

    await SupabaseService.instance.requestPayout(
      ngoId: 'ngo-panzi',
      ngoName: 'Fondation Panzi',
      amountUsdCents: amountUsdCents,
      amountCdf: amountCdf,
      currency: currency.code,
      destinationType: _destinationType,
      destinationDetails: _destinationType == 'BANK_RIB'
          ? 'Rawbank DRC - RIB: 05100-0101-09876543210-90'
          : 'Vodacom Corporate Till: PANZI-MERCHANT-01',
      biometricVerified: true,
    );

    refreshAllData(ref);

    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppTheme.mintGreen, size: 28),
              SizedBox(width: 10),
              Text('Payout Requested', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            'Your payout request for ${currency.symbol} $_amountInput has been securely posted with biometric authorization. Platform treasury will wire funds within 2-4 hours.',
            style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/ngo');
              },
              child: const Text('Return to Dashboard'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final isUsd = currency == AppCurrency.usd;

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('Withdraw Funds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/ngo');
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    // Payout Destination Selector
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
                            child: _buildDestTab('Bank RIB (Rawbank)', 'BANK_RIB', Icons.account_balance_rounded),
                          ),
                          Expanded(
                            child: _buildDestTab('Corporate Till', 'MOBILE_MONEY', Icons.phone_android_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Enter Withdrawal Amount (${isUsd ? 'USD' : 'CDF'})',
                      style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          isUsd ? '\$' : 'FC',
                          style: const TextStyle(
                            color: AppTheme.ceruleanBlue,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _amountInput.isEmpty ? '0' : _amountInput,
                          style: const TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Max Cleared Balance: \$12,980 USD (36,344,000 FC)',
                      style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            // Custom Numeric Keypad
            _buildKeypad(),
            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: PillButton(
                label: 'Authorize Payout via Biometrics',
                icon: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 20),
                isLoading: _isSubmitting,
                onPressed: _showBiometricPrompt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestTab(String label, String id, IconData icon) {
    final isSelected = _destinationType == id;
    return GestureDetector(
      onTap: () => setState(() => _destinationType = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.ceruleanBlue : AppTheme.textMutedGray),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textSlateNavy : AppTheme.textMutedGray,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: AppTheme.backgroundIceBlue,
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 8),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 8),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(width: 72, height: 50),
              _buildBtn('0'),
              SizedBox(
                width: 72,
                height: 50,
                child: IconButton(
                  icon: const Icon(Icons.backspace_outlined, color: AppTheme.textSlateNavy, size: 22),
                  onPressed: _onBackspace,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((i) => _buildBtn(i)).toList(),
    );
  }

  Widget _buildBtn(String val) {
    return Container(
      width: 72,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onKeypadTap(val),
        child: Center(
          child: Text(
            val,
            style: const TextStyle(
              color: AppTheme.textSlateNavy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
