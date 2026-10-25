import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/ngo_review_screen.dart';
import '../../features/admin/registered_ngos_screen.dart';
import '../../features/admin/superadmin_console_screen.dart';
import '../../features/auth/email_signin_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/donor/campaign_detail_screen.dart';
import '../../features/donor/donation_setup_screen.dart';
import '../../features/donor/donation_success_screen.dart';
import '../../features/donor/donor_home_screen.dart';
import '../../features/donor/donor_profile_screen.dart';
import '../../features/donor/donor_subscriptions_screen.dart';
import '../../features/donor/payment_checkout_screen.dart';
import '../../features/donor/pooled_fund_screen.dart';
import '../../features/donor/ussd_waiting_screen.dart';
import '../../features/ngo/ngo_dashboard_screen.dart';
import '../../features/ngo/ngo_kyc_screen.dart';
import '../../features/ngo/ngo_withdrawal_screen.dart';
import '../../features/ngo/post_impact_update_screen.dart';
import '../models/models.dart';
import '../state/auth_state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth/welcome',
    routes: [
      // Phase A: Auth
      GoRoute(
        path: '/auth/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/email',
        builder: (context, state) => const EmailSignInScreen(),
      ),
      GoRoute(
        path: '/auth/signin',
        builder: (context, state) => const EmailSignInScreen(),
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const EmailSignInScreen(), // Redirects to Email Auth as phone auth is commented out for future
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '+243810001234';
          return OtpScreen(phoneNumber: phone);
        },
      ),

      // Phase B: Donor Flow
      GoRoute(
        path: '/donor',
        builder: (context, state) => const DonorHomeScreen(),
      ),
      GoRoute(
        path: '/donor/campaign/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'camp-pooled-1';
          return CampaignDetailScreen(campaignId: id);
        },
      ),
      GoRoute(
        path: '/donor/donate',
        builder: (context, state) => const DonationSetupScreen(),
      ),
      GoRoute(
        path: '/donor/checkout',
        builder: (context, state) => const PaymentCheckoutScreen(),
      ),
      GoRoute(
        path: '/donor/ussd-waiting',
        builder: (context, state) => const UssdWaitingScreen(),
      ),
      GoRoute(
        path: '/donor/success',
        builder: (context, state) => const DonationSuccessScreen(),
      ),
      GoRoute(
        path: '/donor/pooled',
        builder: (context, state) => const PooledFundScreen(),
      ),
      GoRoute(
        path: '/donor/subscriptions',
        builder: (context, state) => const DonorSubscriptionsScreen(),
      ),
      GoRoute(
        path: '/donor/profile',
        builder: (context, state) => const DonorProfileScreen(),
      ),

      // Phase C: NGO Organizer Flow
      GoRoute(
        path: '/ngo',
        builder: (context, state) => const NgoDashboardScreen(),
      ),
      GoRoute(
        path: '/ngo/kyc',
        builder: (context, state) => const NgoKycScreen(),
      ),
      GoRoute(
        path: '/ngo/withdraw',
        builder: (context, state) => const NgoWithdrawalScreen(),
      ),
      GoRoute(
        path: '/ngo/post-impact',
        builder: (context, state) => const PostImpactUpdateScreen(),
      ),

      // Phase D: Platform SuperAdmin Flow
      GoRoute(
        path: '/admin',
        builder: (context, state) => const SuperAdminConsoleScreen(),
      ),
      GoRoute(
        path: '/admin/registered-ngos',
        builder: (context, state) => const RegisteredNgosScreen(),
      ),
      GoRoute(
        path: '/admin/ngo-review/:id',
        builder: (context, state) {
          final ngoId = state.pathParameters['id'] ?? '';
          final ngo = state.extra as Ngo?;
          return NgoReviewScreen(ngoId: ngoId, initialNgo: ngo);
        },
      ),
    ],
    // Role-based redirect guard
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final role = authState.activeRole;
      final isAuthRoute = loc.startsWith('/auth');

      // If NOT authenticated, only allow auth screens
      if (!authState.isAuthenticated) {
        if (!isAuthRoute) {
          return '/auth/welcome';
        }
        return null;
      }

      // If authenticated and on auth screens, redirect to active dashboard
      if (isAuthRoute) {
        if (role == UserRole.ngoAdmin) return '/ngo';
        if (role == UserRole.superAdmin) return '/admin';
        return '/donor';
      }

      // Restrict /admin to superAdmin
      if (loc.startsWith('/admin') && role != UserRole.superAdmin) {
        return '/donor';
      }
      // Restrict /ngo to ngoAdmin or superAdmin
      if (loc.startsWith('/ngo') && role == UserRole.donor) {
        return '/donor';
      }
      return null;
    },
  );
});
