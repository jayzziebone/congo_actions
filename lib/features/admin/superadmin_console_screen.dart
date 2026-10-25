import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/currency_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class SuperAdminConsoleScreen extends ConsumerStatefulWidget {
  const SuperAdminConsoleScreen({super.key});

  @override
  ConsumerState<SuperAdminConsoleScreen> createState() => _SuperAdminConsoleScreenState();
}

class _SuperAdminConsoleScreenState extends ConsumerState<SuperAdminConsoleScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Ngo> _ngos = [];
  List<Campaign> _pooledFunds = [];
  int _donorCount = 0;
  int _totalVolumeUsdCents = 0;
  int _totalVolumeCdf = 0;
  bool _isLoading = true;

  final PageController _pendingCarouselController = PageController(viewportFraction: 0.92);
  int _currentPendingPage = 0;

  final PageController _poolCarouselController = PageController(viewportFraction: 0.92);
  int _currentPoolPage = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _pendingCarouselController.dispose();
    _poolCarouselController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    await SupabaseService.instance.fetchLiveCampaigns();
    final data = await SupabaseService.instance.fetchSuperAdminData();
    if (mounted) {
      final ngos = data['ngos'] as List<Ngo>? ?? [];
      final pendingCount = ngos.where((n) => n.verificationStatus != 'VERIFIED').length;
      final allCampaigns = SupabaseService.instance.campaigns;
      final pools = allCampaigns.where((c) => c.isPooledFund).toList();
      final displayPoolCount = pools.take(5).length;

      setState(() {
        _ngos = ngos;
        _pooledFunds = pools;
        _donorCount = data['donorCount'] as int? ?? 0;
        _totalVolumeUsdCents = data['totalVolumeUsdCents'] as int? ?? 0;
        _totalVolumeCdf = data['totalVolumeCdf'] as int? ?? 0;
        if (_currentPendingPage >= pendingCount && pendingCount > 0) {
          _currentPendingPage = pendingCount - 1;
        } else if (pendingCount == 0) {
          _currentPendingPage = 0;
        }
        if (_currentPoolPage >= displayPoolCount && displayPoolCount > 0) {
          _currentPoolPage = displayPoolCount - 1;
        } else if (displayPoolCount == 0) {
          _currentPoolPage = 0;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    final grossVolumeStr = CurrencyNotifier.formatAmount(
      amountUsdCents: _totalVolumeUsdCents,
      amountCdf: _totalVolumeCdf,
      activeCurrency: currency,
    );

    final verifiedNgos = _ngos.where((n) => n.verificationStatus == 'VERIFIED').toList();
    final pendingNgos = _ngos.where((n) => n.verificationStatus != 'VERIFIED').toList();
    final verifiedNgosCount = verifiedNgos.length;
    final pendingNgosCount = pendingNgos.length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.surfacePureWhite,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('SuperAdmin Console'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.textSlateNavy, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Navigation Menu',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSlateNavy),
            tooltip: 'Refresh Platform Metrics',
            onPressed: _loadAdminData,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CurrencyTogglePill(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAdminData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Ledger Volume Overview Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundIceBlue,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.cardOutline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  'Platform Double-Entry Ledger Volume',
                                  style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.pastelMint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Live Invariant Verified',
                                  style: TextStyle(color: AppTheme.mintGreen, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            grossVolumeStr,
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildMetricTile(
                                '$verifiedNgosCount Registered NGOs',
                                Icons.verified_user_rounded,
                                AppTheme.ceruleanBlue,
                                onTap: () => context.go('/admin/registered-ngos'),
                              ),
                              _buildMetricTile('$_donorCount Donors', Icons.people_alt_rounded, AppTheme.mintGreen),
                              if (pendingNgosCount > 0)
                                _buildMetricTile('$pendingNgosCount Pending Review', Icons.pending_actions_rounded, AppTheme.warmOchre),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Pending Registration NGOs Section
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'Pending Registration NGOs',
                                  style: TextStyle(
                                    color: AppTheme.textSlateNavy,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.pastelButtercream,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${pendingNgos.length}',
                                  style: const TextStyle(
                                    color: AppTheme.warmOchre,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pendingNgos.length > 1) ...[
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppTheme.textSlateNavy),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: _currentPendingPage > 0
                                ? () => _pendingCarouselController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                          ),
                          Text(
                            '${_currentPendingPage + 1}/${pendingNgos.length}',
                            style: const TextStyle(
                              color: AppTheme.textMutedGray,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textSlateNavy),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: _currentPendingPage < pendingNgos.length - 1
                                ? () => _pendingCarouselController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                          ),
                          const SizedBox(width: 4),
                        ],
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.ceruleanBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.corporate_fare_rounded, size: 15),
                          label: Text(
                            'Registered ($verifiedNgosCount)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          onPressed: () => context.go('/admin/registered-ngos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (pendingNgos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundIceBlue,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardOutline),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppTheme.mintGreen,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'All Registrations Up to Date',
                              style: TextStyle(
                                color: AppTheme.textSlateNavy,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'There are currently no pending NGO registration applications awaiting review.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.ceruleanBlue,
                                side: const BorderSide(color: AppTheme.ceruleanBlue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: const Size(0, 36),
                              ),
                              icon: const Icon(Icons.verified_user_rounded, size: 16),
                              label: Text(
                                'View Registered NGOs Directory ($verifiedNgosCount)',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              onPressed: () => context.go('/admin/registered-ngos'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Carousel Slider for Pending Registration NGOs
                      SizedBox(
                        height: 185,
                        child: PageView.builder(
                          controller: _pendingCarouselController,
                          itemCount: pendingNgos.length,
                          onPageChanged: (idx) => setState(() => _currentPendingPage = idx),
                          itemBuilder: (context, index) {
                            final ngo = pendingNgos[index];

                            return GestureDetector(
                              onTap: () {
                                context.push(
                                  '/admin/ngo-review/${ngo.id}',
                                  extra: ngo,
                                ).then((_) => _loadAdminData());
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfacePureWhite,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.cardOutline,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Icon + Name + Review Required Pill
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.pastelButtercream,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.corporate_fare_rounded,
                                            color: AppTheme.warmOchre,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ngo.name,
                                                style: const TextStyle(
                                                  color: AppTheme.textSlateNavy,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Reg: ${ngo.legalRegistrationNumber}',
                                                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.pastelButtercream,
                                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: AppTheme.warmOchre,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              const Text(
                                                'NEEDS REVIEW',
                                                style: TextStyle(
                                                  color: AppTheme.warmOchre,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Key High-level Pills (No heavy paragraphs)
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppTheme.backgroundIceBlue,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.description_outlined, size: 13, color: AppTheme.ceruleanBlue),
                                              SizedBox(width: 5),
                                              Text(
                                                'Legal Dossier Submitted',
                                                style: TextStyle(
                                                  color: AppTheme.textSlateNavy,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppTheme.backgroundIceBlue,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.verified_user_outlined, size: 13, color: AppTheme.warmOchre),
                                                SizedBox(width: 5),
                                                Flexible(
                                                  child: Text(
                                                    'Pending Clearance',
                                                    style: TextStyle(
                                                      color: AppTheme.textSlateNavy,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Spacer(),
                                    const Divider(color: AppTheme.cardOutline, height: 1),
                                    const SizedBox(height: 8),

                                    // Clean Bottom Action Bar
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Tap to inspect dossier & approve',
                                            style: TextStyle(
                                              color: AppTheme.textMutedGray,
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'Review NGO',
                                              style: TextStyle(
                                                color: AppTheme.ceruleanBlue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.ceruleanBlue),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (pendingNgos.length > 1) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(pendingNgos.length, (index) {
                            final isActive = index == _currentPendingPage;
                            return GestureDetector(
                              onTap: () => _pendingCarouselController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isActive ? 22 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.warmOchre : AppTheme.cardOutline,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],

                    const SizedBox(height: 28),

                    // Section: Multi-Partner Pool
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.hub_rounded, color: AppTheme.textSlateNavy, size: 20),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Multi-Partner Pool',
                                  style: TextStyle(
                                    color: AppTheme.textSlateNavy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.pastelMint,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.mintGreen.withOpacity(0.3)),
                                ),
                                child: Text(
                                  '${_pooledFunds.length} Active',
                                  style: const TextStyle(
                                    color: AppTheme.mintGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.ceruleanBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          onPressed: () {
                            context.push('/admin/pools').then((_) => _loadAdminData());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Multi-organization cause consortiums distributing verified donor capital across partner campaigns.',
                      style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 14),

                    if (_pooledFunds.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundIceBlue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.cardOutline),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.hub_outlined, size: 40, color: AppTheme.textMutedGray),
                            const SizedBox(height: 10),
                            const Text(
                              'No Multi-Partner Pools Created',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textSlateNavy),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Create a shared pooled cause fund to group multiple grassroots campaigns together.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppTheme.textMutedGray),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.ceruleanBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Create First Pool', style: TextStyle(fontWeight: FontWeight.w700)),
                              onPressed: () {
                                context.push('/admin/pools').then((_) => _loadAdminData());
                              },
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Builder(
                        builder: (context) {
                          final displayPools = _pooledFunds.take(5).toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 220,
                                child: PageView.builder(
                                  controller: _poolCarouselController,
                                  itemCount: displayPools.length,
                                  onPageChanged: (index) {
                                    setState(() => _currentPoolPage = index);
                                  },
                                  itemBuilder: (context, index) {
                                    final pool = displayPools[index];
                                    return _buildPoolCarouselCard(pool, currency);
                                  },
                                ),
                              ),
                              if (displayPools.length > 1) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(displayPools.length, (index) {
                                    final isActive = index == _currentPoolPage;
                                    return GestureDetector(
                                      onTap: () => _poolCarouselController.animateToPage(
                                        index,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(horizontal: 3),
                                        width: isActive ? 22 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isActive ? AppTheme.ceruleanBlue : AppTheme.cardOutline,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 36),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPoolCarouselCard(Campaign pool, AppCurrency currency) {
    final raisedStr = CurrencyNotifier.formatAmount(
      amountUsdCents: pool.raisedAmountUsdCents,
      amountCdf: pool.raisedAmountCdf,
      activeCurrency: currency,
    );
    final targetStr = CurrencyNotifier.formatAmount(
      amountUsdCents: pool.targetAmountUsdCents,
      amountCdf: pool.targetAmountCdf,
      activeCurrency: currency,
    );
    final progress = currency == AppCurrency.usd ? pool.progressRatioUsd : pool.progressRatioCdf;
    final progressPercent = (progress * 100).clamp(0, 100).toInt();

    return GestureDetector(
      onTap: () {
        context.push(
          '/admin/pool/${pool.id}',
          extra: pool,
        ).then((_) => _loadAdminData());
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfacePureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardOutline, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Hub Icon + Title/Location + Category Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: AppTheme.pastelMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hub_rounded,
                    color: AppTheme.mintGreen,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pool.title,
                        style: const TextStyle(
                          color: AppTheme.textSlateNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMutedGray),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              pool.location,
                              style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppTheme.powderBlue,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Text(
                    pool.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.ceruleanBlue,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Middle: High-level Consortium Info Box (Clean capsule, NO cluttered split chips)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundIceBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 15, color: AppTheme.ceruleanBlue),
                      const SizedBox(width: 6),
                      Text(
                        '${pool.splits.length} Participating NGOs',
                        style: const TextStyle(
                          color: AppTheme.textSlateNavy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.tune_rounded, size: 13, color: AppTheme.mintGreen),
                      SizedBox(width: 4),
                      Text(
                        'Formula Split',
                        style: TextStyle(
                          color: AppTheme.textMutedGray,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Financial Metrics & Linear Progress Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: raisedStr,
                          style: const TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        TextSpan(
                          text: ' raised of $targetStr',
                          style: const TextStyle(
                            color: AppTheme.textMutedGray,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelMint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$progressPercent%',
                    style: const TextStyle(
                      color: AppTheme.mintGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.cardOutline,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.ceruleanBlue),
                minHeight: 6,
              ),
            ),

            const Spacer(),
            const Divider(color: AppTheme.cardOutline, height: 1),
            const SizedBox(height: 8),

            // Bottom Tap Prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Tap to view details & adjust sliders',
                    style: TextStyle(
                      color: AppTheme.textMutedGray,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Redistribution',
                      style: TextStyle(
                        color: AppTheme.ceruleanBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.ceruleanBlue),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: onTap != null ? AppTheme.ceruleanBlue : AppTheme.textSlateNavy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.ceruleanBlue),
        ],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      );
    }
    return content;
  }
}

