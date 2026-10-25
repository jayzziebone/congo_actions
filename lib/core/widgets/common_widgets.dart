import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../state/auth_state.dart';
import '../state/currency_state.dart';
import '../theme/app_theme.dart';

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final Widget? icon;
  final bool isLoading;
  final double height;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.icon,
    this.isLoading = false,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSecondary ? AppTheme.powderBlue : AppTheme.ceruleanBlue;
    final fgColor = isSecondary ? AppTheme.textSlateNavy : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fgColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class PastelBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const PastelBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory PastelBadge.verified({bool compact = false}) {
    return PastelBadge(
      text: compact ? 'Verified' : 'Arrêté N° 045 Verified',
      backgroundColor: AppTheme.pastelMint,
      textColor: AppTheme.mintGreen,
      icon: Icons.verified_rounded,
    );
  }

  factory PastelBadge.pooled() {
    return const PastelBadge(
      text: 'Pooled Cause Fund',
      backgroundColor: AppTheme.pastelButtercream,
      textColor: AppTheme.warmOchre,
      icon: Icons.hub_rounded,
    );
  }

  factory PastelBadge.urgent() {
    return const PastelBadge(
      text: 'Action Needed Today',
      backgroundColor: AppTheme.pastelRose,
      textColor: AppTheme.roseText,
      icon: Icons.priority_high_rounded,
    );
  }

  factory PastelBadge.category(String category) {
    Color bg;
    Color fg;
    IconData ic;
    switch (category.toLowerCase()) {
      case 'health':
        bg = AppTheme.pastelRose;
        fg = AppTheme.roseText;
        ic = Icons.medical_services_outlined;
        break;
      case 'education':
        bg = AppTheme.pastelButtercream;
        fg = AppTheme.warmOchre;
        ic = Icons.school_outlined;
        break;
      case 'children':
      default:
        bg = AppTheme.pastelApricot;
        fg = AppTheme.terracottaIcon;
        ic = Icons.volunteer_activism_outlined;
        break;
    }
    return PastelBadge(
      text: category,
      backgroundColor: bg,
      textColor: fg,
      icon: ic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyTogglePill extends ConsumerWidget {
  const CurrencyTogglePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCurrency = ref.watch(currencyProvider);
    final isUsd = activeCurrency == AppCurrency.usd;

    return GestureDetector(
      onTap: () => ref.read(currencyProvider.notifier).toggleCurrency(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppTheme.backgroundIceBlue,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(color: AppTheme.cardOutline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUsd ? AppTheme.ceruleanBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
              child: Text(
                '\$ USD',
                style: TextStyle(
                  color: isUsd ? Colors.white : AppTheme.textMutedGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !isUsd ? AppTheme.ceruleanBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              ),
              child: Text(
                'FC CDF',
                style: TextStyle(
                  color: !isUsd ? Colors.white : AppTheme.textMutedGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomLinearProgress extends StatelessWidget {
  final double value;
  final Color progressColor;
  final double height;

  const CustomLinearProgress({
    super.key,
    required this.value,
    this.progressColor = AppTheme.ceruleanBlue,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardOutline.withOpacity(0.5),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              width: constraints.maxWidth * value.clamp(0.0, 1.0),
              height: height,
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final role = authState.activeRole;

    final displayName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : (user?.email?.split('@').first ?? 'CongoActions User');
    final email = user?.email ?? '';

    final roleLabel = role == UserRole.ngoAdmin
        ? 'NGO ORGANIZER'
        : role == UserRole.superAdmin
            ? 'SUPERADMIN'
            : 'DONOR';

    final roleBadgeColor = role == UserRole.ngoAdmin
        ? AppTheme.mintGreen
        : role == UserRole.superAdmin
            ? AppTheme.terracottaIcon
            : AppTheme.ceruleanBlue;

    final roleBadgeBg = role == UserRole.ngoAdmin
        ? AppTheme.pastelMint
        : role == UserRole.superAdmin
            ? AppTheme.pastelApricot
            : AppTheme.powderBlue;

    return Drawer(
      backgroundColor: AppTheme.surfacePureWhite,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.all(22.0),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundIceBlue,
                border: Border(bottom: BorderSide(color: AppTheme.cardOutline)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: roleBadgeBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: roleBadgeColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: roleBadgeColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: AppTheme.textSlateNavy,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: AppTheme.textMutedGray,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleBadgeBg,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: roleBadgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Role-Specific Navigation Menu (Strict Role Locking)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  if (role == UserRole.donor) ...[
                    _buildNavTile(
                      context: context,
                      title: 'Causes & Campaigns',
                      subtitle: 'Explore verified relief efforts',
                      icon: Icons.volunteer_activism_rounded,
                      route: '/donor',
                    ),
                    _buildNavTile(
                      context: context,
                      title: 'My Donations & Receipts',
                      subtitle: 'Track your giving history',
                      icon: Icons.receipt_long_rounded,
                      route: '/donor/profile',
                    ),
                    _buildNavTile(
                      context: context,
                      title: 'Recurring Pledges',
                      subtitle: 'Active automated giving',
                      icon: Icons.event_repeat_rounded,
                      route: '/donor/subscriptions',
                    ),
                    _buildNavTile(
                      context: context,
                      title: 'Pooled Fund Transparency',
                      subtitle: 'Multi-hospital redistribution model',
                      icon: Icons.pie_chart_outline_rounded,
                      route: '/donor/pooled',
                    ),
                  ] else if (role == UserRole.ngoAdmin) ...[
                    _buildNavTile(
                      context: context,
                      title: 'NGO Dashboard',
                      subtitle: 'Campaign analytics & balances',
                      icon: Icons.dashboard_rounded,
                      route: '/ngo',
                    ),
                    _buildNavTile(
                      context: context,
                      title: 'Post Field Update',
                      subtitle: 'Share verified photos & receipts',
                      icon: Icons.campaign_rounded,
                      route: '/ngo/post-impact',
                    ),
                    _buildNavTile(
                      context: context,
                      title: 'KYC & Legal Documents',
                      subtitle: 'Official registration status',
                      icon: Icons.verified_user_rounded,
                      route: '/ngo/kyc',
                    ),
                    _buildNavTile(
                      context: context,
                      title: 'Treasury Payout',
                      subtitle: 'Direct bank & mobile money transfer',
                      icon: Icons.account_balance_wallet_rounded,
                      route: '/ngo/withdraw',
                    ),
                  ] else if (role == UserRole.superAdmin) ...[
                    _buildNavTile(
                      context: context,
                      title: 'SuperAdmin Console',
                      subtitle: 'Pending registrations & ledger metrics',
                      icon: Icons.admin_panel_settings_rounded,
                      route: '/admin',
                    ),
                    _buildNavTile(
                      context: context,
                      title: 'Multi-Partner Pools',
                      subtitle: 'Consortium funds & redistribution models',
                      icon: Icons.hub_rounded,
                      route: '/admin/pools',
                    ),
                    _buildNavTile(
                      context: context,
                      title: 'Registered NGOs',
                      subtitle: 'Verified Congolese NGO directory',
                      icon: Icons.verified_user_rounded,
                      route: '/admin/registered-ngos',
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: AppTheme.cardOutline, height: 1),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.roseText,
                  side: const BorderSide(color: AppTheme.pastelRose),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 44),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/auth/welcome');
                  }
                },
              ),
            ),

            // DRC Live Footer
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.mintGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CongoActions • DRC Live Production',
                    style: TextStyle(
                      color: AppTheme.textMutedGray,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundIceBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.ceruleanBlue, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSlateNavy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textMutedGray,
          fontSize: 11,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (route == '/donor' || route == '/ngo' || route == '/admin') {
          context.go(route);
        } else {
          context.push(route);
        }
      },
    );
  }
}

// Backward-compatibility alias so existing screens work seamlessly
typedef PersonaRoleSwitcherDrawer = AppDrawer;
