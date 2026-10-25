import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

/* ============================================================================
 * FUTURE IMPLEMENTATION: DRC Mobile Phone Authentication (SMS / WhatsApp)
 *
 * When an SMS aggregator/provider (e.g. Twilio, MessageBird, Vonage, or local
 * DRC telco gateway) is provisioned in Supabase Dashboard (Auth > Providers > Phone):
 *
 * 1. Dispatch SMS / WhatsApp OTP:
 *    await client.auth.signInWithOtp(
 *      phone: fullPhoneNumber, // e.g. +243810001234
 *      channel: isWhatsApp ? OtpChannel.whatsapp : OtpChannel.sms,
 *    );
 *
 * 2. Verify 6-digit OTP code on OtpScreen:
 *    await client.auth.verifyOTP(
 *      phone: fullPhoneNumber,
 *      token: pinCode,
 *      type: OtpType.sms,
 *    );
 * ============================================================================
 */

class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  ConsumerState<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  bool _isSignUp = false; // Toggle: false = Sign In, true = Create Account
  UserRole _selectedRole = UserRole.donor; // Donor, NGO Admin, or SuperAdmin
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orgNameController = TextEditingController(); // For NGO Admin

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _orgNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final orgName = _orgNameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (_isSignUp && fullName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }

    if (_isSignUp && _selectedRole == UserRole.ngoAdmin && orgName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your NGO or Foundation name');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = SupabaseService.instance.client;
      if (client == null) throw Exception('Supabase client not initialized');

      if (_isSignUp) {
        final roleString = _selectedRole == UserRole.ngoAdmin
            ? 'NGO_ADMIN'
            : _selectedRole == UserRole.superAdmin
                ? 'SUPERADMIN'
                : 'DONOR';

        // --- REAL SUPABASE SIGN UP ---
        final AuthResponse res = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'phone_number': phone,
            'role': roleString,
            if (_selectedRole == UserRole.ngoAdmin) 'organization_name': orgName,
          },
        );

        final user = res.user;
        if (user != null) {
          // Sync profile into public.profiles table
          try {
            await client.from('profiles').upsert({
              'id': user.id,
              'full_name': fullName,
              'contact_email': email,
              'phone_number': phone,
              'role': roleString,
              'preferred_currency': 'USD',
            });

            if (_selectedRole == UserRole.ngoAdmin && phone.isNotEmpty) {
              await client.from('ngos').update({'contact_phone': phone}).eq('admin_user_id', user.id);
            }
          } catch (profileErr) {
            debugPrint('Profiles table sync notice: $profileErr');
          }

          ref.read(authProvider.notifier).loginWithEmail(
            id: user.id,
            email: email,
            fullName: fullName,
            role: _selectedRole,
          );

          if (mounted) {
            final roleLabel = _selectedRole == UserRole.ngoAdmin
                ? 'NGO Organizer'
                : _selectedRole == UserRole.superAdmin
                    ? 'SuperAdmin'
                    : 'Donor';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$roleLabel account created successfully! Welcome to CongoActions.'),
                backgroundColor: AppTheme.mintGreen,
              ),
            );

            if (_selectedRole == UserRole.ngoAdmin) {
              context.go('/ngo');
            } else if (_selectedRole == UserRole.superAdmin) {
              context.go('/admin');
            } else {
              context.go('/donor');
            }
          }
        } else {
          // If Supabase project requires email confirmation link:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Confirmation email sent to $email. Please check your inbox.'),
              ),
            );
          }
        }
      } else {
        // --- REAL SUPABASE SIGN IN ---
        final AuthResponse res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = res.user;
        if (user != null) {
          final metadataRoleStr = user.userMetadata?['role'] as String?;
          UserRole resolvedRole = metadataRoleStr != null
              ? UserRole.fromString(metadataRoleStr)
              : UserRole.donor;

          // Check profiles table for confirmed role
          try {
            final profile = await client
                .from('profiles')
                .select('role, full_name')
                .eq('id', user.id)
                .maybeSingle();

            if (profile != null && profile['role'] != null) {
              resolvedRole = UserRole.fromString(profile['role'] as String);
            }
          } catch (e) {
            debugPrint('Error fetching role from profile: $e');
          }

          final displayName = user.userMetadata?['full_name'] as String? ?? 
              (email.split('@').first);

          ref.read(authProvider.notifier).loginWithEmail(
            id: user.id,
            email: email,
            fullName: displayName,
            role: resolvedRole,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome back, $displayName! (${resolvedRole.displayName})'),
                backgroundColor: AppTheme.ceruleanBlue,
              ),
            );

            if (resolvedRole == UserRole.ngoAdmin) {
              context.go('/ngo');
            } else if (resolvedRole == UserRole.superAdmin) {
              context.go('/admin');
            } else {
              context.go('/donor');
            }
          }
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Authentication failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textSlateNavy,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _isSignUp
                    ? 'Register with your email to track donations, receive verified impact receipts, and manage recurring pledges.'
                    : 'Sign in to access your donation dashboard and double-entry ledger records.',
                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              // Segmented Tab Switcher: Sign In vs Create Account
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
                      child: _buildAuthTab(
                        label: 'Sign In',
                        isSelected: !_isSignUp,
                        onTap: () => setState(() {
                          _isSignUp = false;
                          _errorMessage = null;
                        }),
                      ),
                    ),
                    Expanded(
                      child: _buildAuthTab(
                        label: 'Create Account',
                        isSelected: _isSignUp,
                        onTap: () => setState(() {
                          _isSignUp = true;
                          _errorMessage = null;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelRose,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.roseText.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.roseText, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.roseText, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Form fields
              if (_isSignUp) ...[
                const Text(
                  'Account Type',
                  style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleSelectorChip(
                        title: 'Donor',
                        icon: Icons.favorite_rounded,
                        role: UserRole.donor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleSelectorChip(
                        title: 'NGO',
                        icon: Icons.corporate_fare_rounded,
                        role: UserRole.ngoAdmin,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleSelectorChip(
                        title: 'Admin',
                        icon: Icons.shield_rounded,
                        role: UserRole.superAdmin,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Full Name',
                  style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.ceruleanBlue),
                    hintText: 'e.g. Junior Lutula',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Phone Number',
                  style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.ceruleanBlue),
                    hintText: '+243 812 345 678',
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedRole == UserRole.ngoAdmin) ...[
                  const Text(
                    'NGO / Organization Name',
                    style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _orgNameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.apartment_rounded, color: AppTheme.ceruleanBlue),
                      hintText: 'e.g. Fondation Espoir Congo',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              const Text(
                'Email Address',
                style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.ceruleanBlue),
                  hintText: 'donor@example.com',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Password',
                style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.ceruleanBlue),
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppTheme.textMutedGray,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Main Action Button
              PillButton(
                label: _isSignUp ? 'Create an Account' : 'Sign In',
                isLoading: _isLoading,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              // Phone Auth Note (Commented for future implementation)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android_rounded, color: AppTheme.textMutedGray, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'DRC Mobile Phone (SMS/WhatsApp)',
                            style: TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Phone authentication will be enabled once SMS gateway provider is provisioned.',
                            style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppTheme.cardOutline)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('or explore', style: TextStyle(color: AppTheme.textLightPlaceholder, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: AppTheme.cardOutline)),
                ],
              ),
              const SizedBox(height: 16),
              PillButton(
                label: 'Continue as Guest Donor',
                isSecondary: true,
                onPressed: () {
                  ref.read(authProvider.notifier).loginWithPhone('+243000000000', '000000', fullName: 'Guest Donor');
                  context.go('/donor');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.textSlateNavy : AppTheme.textMutedGray,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectorChip({
    required String title,
    required IconData icon,
    required UserRole role,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.ceruleanBlue : AppTheme.backgroundIceBlue,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: isSelected ? AppTheme.ceruleanBlue : AppTheme.cardOutline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.textSlateNavy,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSlateNavy,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
