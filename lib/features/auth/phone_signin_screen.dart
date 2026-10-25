import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class PhoneSignInScreen extends ConsumerStatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  ConsumerState<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends ConsumerState<PhoneSignInScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '810001234');
  String _channel = 'WhatsApp'; // 'WhatsApp' or 'SMS'
  final String _countryCode = '+243';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    final fullNumber = '$_countryCode$rawPhone';
    setState(() => _isLoading = true);

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        /* =====================================================================
         * FUTURE IMPLEMENTATION: DRC Mobile Phone Authentication (SMS / WhatsApp)
         *
         * Once an SMS gateway (Twilio, Vonage, or local Congolese aggregator) is
         * provisioned in Supabase Dashboard (Auth > Providers > Phone), uncomment:
         * ---------------------------------------------------------------------
         * await client.auth.signInWithOtp(
         *   phone: fullNumber,
         *   channel: _channel == 'WhatsApp' ? OtpChannel.whatsapp : OtpChannel.sms,
         * );
         * ===================================================================== */
        debugPrint('Phone Auth currently in sandbox mode; Email Auth active.');
      }
    } catch (e) {
      debugPrint('Supabase signInWithOtp notice: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        context.push('/auth/otp', extra: fullNumber);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your phone number',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textSlateNavy,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We will send a 6-digit confirmation code to verify your mobile identity for donations and updates.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMutedGray,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 32),
              // Phone input container with DRC flag
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('🇨🇩', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            _countryCode,
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppTheme.textMutedGray, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          color: AppTheme.textSlateNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: false,
                          hintText: '81 000 1234',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Receive verification code via:',
                style: TextStyle(
                  color: AppTheme.textSlateNavy,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // Radio/Pill selector: WhatsApp vs SMS
              Row(
                children: [
                  Expanded(
                    child: _buildChannelPill(
                      channel: 'WhatsApp',
                      icon: Icons.chat_bubble_rounded,
                      iconColor: const Color(0xFF25D366),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildChannelPill(
                      channel: 'SMS',
                      icon: Icons.sms_rounded,
                      iconColor: AppTheme.ceruleanBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              PillButton(
                label: 'Continue',
                isLoading: _isLoading,
                onPressed: _handleContinue,
              ),
              const SizedBox(height: 32),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppTheme.cardOutline)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'or continue with',
                      style: TextStyle(color: AppTheme.textLightPlaceholder, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.cardOutline)),
                ],
              ),
              const SizedBox(height: 24),
              // Social Auth Buttons (Apple & Google)
              Row(
                children: [
                  Expanded(
                    child: _buildSocialButton(
                      label: 'Apple',
                      icon: Icons.apple,
                      onPressed: () {
                        ref.read(authProvider.notifier).loginWithPhone('+243810001234', '000000', fullName: 'Apple Donor');
                        context.go('/donor');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSocialButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata_rounded,
                      onPressed: () {
                        ref.read(authProvider.notifier).loginWithPhone('+243810001234', '000000', fullName: 'Google Donor');
                        context.go('/donor');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelPill({
    required String channel,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _channel == channel;

    return GestureDetector(
      onTap: () => setState(() => _channel = channel),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.powderBlue.withOpacity(0.5) : AppTheme.backgroundIceBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.ceruleanBlue : AppTheme.cardOutline,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              channel,
              style: TextStyle(
                color: isSelected ? AppTheme.textSlateNavy : AppTheme.textMutedGray,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.cardOutline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppTheme.textSlateNavy),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSlateNavy,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
