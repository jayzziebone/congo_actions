import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/donation_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class UssdWaitingScreen extends ConsumerStatefulWidget {
  const UssdWaitingScreen({super.key});

  @override
  ConsumerState<UssdWaitingScreen> createState() => _UssdWaitingScreenState();
}

class _UssdWaitingScreenState extends ConsumerState<UssdWaitingScreen> {
  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        // After 4 seconds, simulate incoming aggregator webhook confirmation!
        if (_secondsRemaining == 56) {
          _simulateSuccessfulPayment();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _simulateSuccessfulPayment() async {
    _timer?.cancel();
    final currency = ref.read(currencyProvider);
    final donation = await ref.read(donationFlowProvider.notifier).finalizeDonation(currency.code);
    if (mounted && donation != null) {
      context.go('/donor/success');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final donationFlow = ref.watch(donationFlowProvider);
    final operatorName = donationFlow.selectedPaymentMethod.displayName;
    final progress = _secondsRemaining / 60.0;

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('Authorizing Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // 60-Second Animated Circular Progress Indicator
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: AppTheme.backgroundIceBlue,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.ceruleanBlue),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_iphone_rounded, size: 40, color: AppTheme.ceruleanBlue),
                          const SizedBox(height: 6),
                          Text(
                            '$_secondsRemaining s',
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Time remaining',
                            style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Clear instructions
              Text(
                'Check Your Phone Screen',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textSlateNavy,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Column(
                  children: [
                    Text(
                      'A secure $operatorName USSD prompt has been pushed to:',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      donationFlow.donorPhoneNumber,
                      style: const TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please unlock your device and enter your secret PIN to authorize this transfer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              // Actions
              PillButton(
                label: 'Confirm PIN Entered (Instant Check)',
                onPressed: _simulateSuccessfulPayment,
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _startCountdown,
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.ceruleanBlue),
                    label: const Text(
                      'Resend USSD Prompt',
                      style: TextStyle(color: AppTheme.ceruleanBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.roseText, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
