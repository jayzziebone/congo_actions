import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Official Congo Actions Brand Logo
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.powderBlue.withOpacity(0.5),
                        blurRadius: 32,
                        spreadRadius: 6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/congo_actions_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Value proposition
              Text(
                'Fund a Better Tomorrow',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textSlateNavy,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Direct, 100% verified charitable giving to the Democratic Republic of Congo. Transparently redistribute pooled funds across grassroots NGOs with real-time double-entry ledger auditing.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMutedGray,
                      fontSize: 15,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PastelBadge.category('Health'),
                  const SizedBox(width: 8),
                  PastelBadge.category('Education'),
                  const SizedBox(width: 8),
                  PastelBadge.category('Children'),
                ],
              ),
              const Spacer(flex: 2),
              // Primary CTA
              PillButton(
                label: 'Get Started',
                onPressed: () => context.push('/auth/email'),
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              PillButton(
                label: 'Explore as Guest Donor',
                isSecondary: true,
                onPressed: () {
                  ref.read(authProvider.notifier).loginWithPhone('+243000000000', '000000', fullName: 'Guest Donor');
                  context.go('/donor');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
