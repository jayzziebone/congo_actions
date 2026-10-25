import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_state.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/data_providers.dart';
import '../../core/state/donation_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class DonorHomeScreen extends ConsumerStatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  ConsumerState<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends ConsumerState<DonorHomeScreen> {
  int _activeTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _refreshLiveCampaigns();
  }

  Future<void> _refreshLiveCampaigns() async {
    await SupabaseService.instance.fetchLiveCampaigns();
    if (mounted) {
      ref.read(campaignsProvider.notifier).state = [...SupabaseService.instance.campaigns];
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final campaigns = ref.watch(filteredCampaignsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.surfacePureWhite,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Currency Toggle Pill, Notification Bell, User Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppTheme.textSlateNavy, size: 28),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    tooltip: 'Navigation Menu',
                  ),
                  const Spacer(),
                  const CurrencyTogglePill(),
                  const SizedBox(width: 12),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundIceBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.cardOutline),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, color: AppTheme.textSlateNavy, size: 22),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.terracottaIcon,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.push('/donor/profile'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.powderBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.ceruleanBlue, width: 1.5),
                        image: authState.user?.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(authState.user!.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: authState.user?.avatarUrl == null
                          ? const Icon(Icons.person, color: AppTheme.ceruleanBlue, size: 24)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            // Body Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await SupabaseService.instance.fetchLiveCampaigns();
                  ref.read(campaignsProvider.notifier).state = [...SupabaseService.instance.campaigns];
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                    const SizedBox(height: 8),
                    // Personalized Greeting & Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, ${authState.user?.fullName.split(' ').first ?? 'Diaspora Donor'} 👋',
                              style: const TextStyle(
                                color: AppTheme.textMutedGray,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Make an Impact Today',
                              style: TextStyle(
                                color: AppTheme.textSlateNavy,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundIceBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardOutline),
                          ),
                          child: Text(
                            '${campaigns.length} Active',
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Categories horizontal scroll
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryChip('All', 'All Causes', selectedCategory),
                          _buildCategoryChip('Health', 'Health & Panzi', selectedCategory),
                          _buildCategoryChip('Education', 'Tech & Schools', selectedCategory),
                          _buildCategoryChip('Children', 'Orphan Care', selectedCategory),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Hero Highlight / Pooled Fund Spotlight
                    _buildPooledHeroBanner(context, currency),
                    const SizedBox(height: 28),
                    // Feed Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verified Campaigns For You',
                          style: TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View All',
                            style: TextStyle(color: AppTheme.ceruleanBlue, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Vertical Campaign Cards
                    if (campaigns.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundIceBlue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.cardOutline),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.search_off_rounded, size: 40, color: AppTheme.textMutedGray),
                            SizedBox(height: 8),
                            Text(
                              'No Active Campaigns Found',
                              style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pull down to refresh or check back once registered NGOs publish new causes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ...campaigns.map((camp) => _buildCampaignCard(context, camp, currency)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom 3-tab navigation
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfacePureWhite,
          border: Border(top: BorderSide(color: AppTheme.cardOutline, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(
              index: 0,
              label: 'Home',
              icon: Icons.home_rounded,
              onTap: () => setState(() => _activeTabIndex = 0),
            ),
            _buildBottomNavItem(
              index: 1,
              label: 'Explore Pools',
              icon: Icons.hub_rounded,
              onTap: () {
                setState(() => _activeTabIndex = 1);
                context.push('/donor/pooled');
              },
            ),
            _buildBottomNavItem(
              index: 2,
              label: 'Subscriptions',
              icon: Icons.repeat_rounded,
              onTap: () {
                setState(() => _activeTabIndex = 2);
                context.push('/donor/subscriptions');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label, String activeCategory) {
    final isSelected = activeCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) ref.read(selectedCategoryProvider.notifier).state = id;
        },
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSlateNavy,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        selectedColor: AppTheme.ceruleanBlue,
        backgroundColor: AppTheme.backgroundIceBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          side: BorderSide(color: isSelected ? AppTheme.ceruleanBlue : AppTheme.cardOutline),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildPooledHeroBanner(BuildContext context, AppCurrency currency) {
    return GestureDetector(
      onTap: () => context.push('/donor/pooled'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.pastelApricot.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.pastelApricot),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PastelBadge.pooled(),
                const Spacer(),
                const Text(
                  'Redistributed Fund',
                  style: TextStyle(
                    color: AppTheme.terracottaIcon,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.terracottaIcon),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Eastern DRC Emergency & Health Relief Pool',
              style: TextStyle(
                color: AppTheme.textSlateNavy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Automated split: 40% Hospital Panzi, 35% Kivu Clean Water, 25% Kinshasa Orphanage.',
              style: TextStyle(
                color: AppTheme.textMutedGray,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.pie_chart_outline_rounded, size: 16, color: AppTheme.terracottaIcon),
                      SizedBox(width: 6),
                      Text(
                        'View 3-Way Split Ratios',
                        style: TextStyle(
                          color: AppTheme.textSlateNavy,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, Campaign camp, AppCurrency currency) {
    final isUsd = currency == AppCurrency.usd;
    final raisedStr = CurrencyNotifier.formatAmount(
      amountUsdCents: camp.raisedAmountUsdCents,
      amountCdf: camp.raisedAmountCdf,
      activeCurrency: currency,
    );
    final targetStr = CurrencyNotifier.formatAmount(
      amountUsdCents: camp.targetAmountUsdCents,
      amountCdf: camp.targetAmountCdf,
      activeCurrency: currency,
    );
    final progress = isUsd ? camp.progressRatioUsd : camp.progressRatioCdf;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundIceBlue,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.cardOutline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: () {
            ref.read(donationFlowProvider.notifier).setCampaign(camp);
            context.push('/donor/campaign/${camp.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image with Category Badge & Verification Pill
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.cardRadius),
                      topRight: Radius.circular(AppTheme.cardRadius),
                    ),
                    child: Image.network(
                      camp.imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          color: AppTheme.powderBlue,
                          child: const Center(
                            child: Icon(Icons.volunteer_activism_rounded, color: AppTheme.ceruleanBlue, size: 40),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: PastelBadge.category(camp.category),
                  ),
                  if (camp.isNgoVerified)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.verified_rounded, color: AppTheme.mintGreen, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Verified NGO',
                              style: TextStyle(
                                color: AppTheme.textSlateNavy,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMutedGray),
                        const SizedBox(width: 4),
                        Text(
                          camp.location,
                          style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                        ),
                        const Spacer(),
                        if (camp.isPooledFund)
                          const Text(
                            '3 NGOs Sharing',
                            style: TextStyle(
                              color: AppTheme.ceruleanBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      camp.title,
                      style: const TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      camp.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMutedGray,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    CustomLinearProgress(value: progress),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 14),
                            children: [
                              TextSpan(
                                text: raisedStr,
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ceruleanBlue),
                              ),
                              TextSpan(
                                text: ' raised of $targetStr',
                                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.ceruleanBlue : AppTheme.textLightPlaceholder,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.ceruleanBlue : AppTheme.textLightPlaceholder,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
