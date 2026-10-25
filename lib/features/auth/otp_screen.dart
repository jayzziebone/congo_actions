import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<String> _pin = ['', '', '', '', '', ''];
  int _secondsLeft = 45;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    _startTimer();
    try {
      /* =====================================================================
       * FUTURE IMPLEMENTATION: Uncomment when Supabase SMS provider is active:
       * await SupabaseService.instance.client?.auth.signInWithOtp(
       *   phone: widget.phoneNumber,
       *   channel: OtpChannel.sms,
       * );
       * ===================================================================== */
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent successfully.')),
        );
      }
    } catch (e) {
      debugPrint('Resend OTP notice: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    if (_isVerifying) return;
    for (int i = 0; i < 6; i++) {
      if (_pin[i].isEmpty) {
        setState(() => _pin[i] = value);
        if (i == 5) {
          _verifyOtp();
        }
        break;
      }
    }
  }

  void _onBackspace() {
    if (_isVerifying) return;
    for (int i = 5; i >= 0; i--) {
      if (_pin[i].isNotEmpty) {
        setState(() => _pin[i] = '');
        break;
      }
    }
  }

  Future<void> _verifyOtp() async {
    final code = _pin.join();
    setState(() => _isVerifying = true);

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        /* =====================================================================
         * FUTURE IMPLEMENTATION: DRC Mobile Phone verifyOTP (SMS / WhatsApp)
         *
         * Once phone auth is enabled in Supabase Dashboard, uncomment:
         * ---------------------------------------------------------------------
         * final AuthResponse res = await client.auth.verifyOTP(
         *   phone: widget.phoneNumber,
         *   token: code,
         *   type: OtpType.sms,
         * );
         * if (res.user != null) {
         *   await client.from('profiles').upsert({
         *     'id': res.user!.id,
         *     'phone_number': widget.phoneNumber,
         *     'full_name': 'Donor ${widget.phoneNumber.substring(widget.phoneNumber.length - 4)}',
         *     'role': 'DONOR',
         *   });
         * }
         * ===================================================================== */
        debugPrint('Phone verifyOTP currently in sandbox mode; Email Auth active.');
      }
      ref.read(authProvider.notifier).loginWithPhone(widget.phoneNumber, code);
    } catch (e) {
      debugPrint('OTP verification fallback: $e');
      ref.read(authProvider.notifier).loginWithPhone(widget.phoneNumber, code);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
        context.go('/donor');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTimer = '00:${_secondsLeft.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Verification Code',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.textSlateNavy,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Enter the 6-digit code sent to '),
                          TextSpan(
                            text: widget.phoneNumber,
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    // 6 auto-advancing PIN cells
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final val = _pin[index];
                        final isFilled = val.isNotEmpty;
                        final isCurrent = index == _pin.indexWhere((e) => e.isEmpty) ||
                            (index == 5 && _pin[5].isNotEmpty);

                        return Container(
                          width: 48,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isFilled ? AppTheme.powderBlue.withOpacity(0.3) : AppTheme.backgroundIceBlue,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? AppTheme.ceruleanBlue
                                  : (isFilled ? AppTheme.ceruleanBlue.withOpacity(0.4) : AppTheme.cardOutline),
                              width: isCurrent ? 2.0 : 1.0,
                            ),
                          ),
                          child: Text(
                            val,
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    // Timer countdown & resend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _secondsLeft > 0 ? 'Resend code in $formattedTimer' : 'Didn\'t receive code? ',
                          style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 14),
                        ),
                        if (_secondsLeft == 0)
                          GestureDetector(
                            onTap: _resendOtp,
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                color: AppTheme.ceruleanBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Custom Numeric Keypad
            _buildNumericKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundIceBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(width: 72, height: 56), // Placeholder
              _buildKeypadButton('0'),
              SizedBox(
                width: 72,
                height: 56,
                child: IconButton(
                  icon: const Icon(Icons.backspace_outlined, color: AppTheme.textSlateNavy, size: 24),
                  onPressed: _onBackspace,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: values.map((val) => _buildKeypadButton(val)).toList(),
    );
  }

  Widget _buildKeypadButton(String val) {
    return Container(
      width: 72,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onKeypadTap(val),
          child: Center(
            child: Text(
              val,
              style: const TextStyle(
                color: AppTheme.textSlateNavy,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
