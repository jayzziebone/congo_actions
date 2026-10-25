import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_state.dart';
import '../../core/state/currency_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class DonorProfileScreen extends ConsumerStatefulWidget {
  const DonorProfileScreen({super.key});

  @override
  ConsumerState<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends ConsumerState<DonorProfileScreen> {
  List<Donation> _myDonations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonorDonations();
  }

  Future<void> _loadDonorDonations() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;
    if (user != null) {
      final dons = await SupabaseService.instance.fetchDonationsForDonor(user.id);
      if (mounted) {
        setState(() {
          _myDonations = dons;
          _isLoading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currency = ref.watch(currencyProvider);

    int totalUsdCents = 0;
    int totalCdf = 0;
    for (final d in _myDonations) {
      totalUsdCents += d.amountUsdCents;
      totalCdf += d.amountCdf;
    }

    final totalGivenStr = CurrencyNotifier.formatAmount(
      amountUsdCents: totalUsdCents,
      amountCdf: totalCdf,
      activeCurrency: currency,
    );

    final displayName = authState.user?.fullName.isNotEmpty == true
        ? authState.user!.fullName
        : (authState.user?.email?.split('@').first ?? 'Donor');
    final email = authState.user?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('My Giving Profile'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSlateNavy),
            tooltip: 'Refresh Giving History',
            onPressed: _loadDonorDonations,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CurrencyTogglePill(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDonorDonations,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // User header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.powderBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.ceruleanBlue, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D',
                                style: const TextStyle(
                                  color: AppTheme.ceruleanBlue,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.isNotEmpty ? email : 'Verified Donor',
                            style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.powderBlue,
                              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                            ),
                            child: const Text(
                              'VERIFIED DONOR',
                              style: TextStyle(
                                color: AppTheme.ceruleanBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cumulative Giving Metrics Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundIceBlue,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.cardOutline),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Lifetime Cumulative Giving',
                            style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalGivenStr,
                            style: const TextStyle(
                              color: AppTheme.ceruleanBlue,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Recorded in Supabase double-entry ledger',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Donation History Timeline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Donation History (${_myDonations.length})',
                          style: const TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_myDonations.isNotEmpty)
                          TextButton(
                            onPressed: _loadDonorDonations,
                            child: const Text('Refresh', style: TextStyle(color: AppTheme.ceruleanBlue, fontSize: 13)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_myDonations.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundIceBlue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.cardOutline),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.volunteer_activism_outlined, size: 48, color: AppTheme.textMutedGray),
                            const SizedBox(height: 12),
                            const Text(
                              'No Donations Recorded Yet',
                              style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Explore active campaigns in the DRC and make your first transparent donation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            PillButton(
                              label: 'Explore Causes',
                              icon: const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
                              onPressed: () => context.go('/donor'),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._myDonations.map((d) {
                        final formatted = CurrencyNotifier.formatAmount(
                          amountUsdCents: d.amountUsdCents,
                          amountCdf: d.amountCdf,
                          activeCurrency: currency,
                        );
                        final date = DateFormat('dd MMM yyyy • HH:mm').format(d.createdAt);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundIceBlue,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardOutline),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppTheme.powderBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_rounded, color: AppTheme.ceruleanBlue, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.campaignTitle,
                                      style: const TextStyle(
                                        color: AppTheme.textSlateNavy,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$date • ${d.receiptNumber}',
                                      style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatted,
                                style: const TextStyle(
                                  color: AppTheme.ceruleanBlue,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ),
    );
  }
}
