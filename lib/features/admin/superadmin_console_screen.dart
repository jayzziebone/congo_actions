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

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void dispose() {
    _pendingCarouselController.dispose();
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
                        height: 255,
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
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundIceBlue,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.warmOchre.withOpacity(0.6),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Reg: ${ngo.legalRegistrationNumber}',
                                                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.pastelButtercream,
                                            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                          ),
                                          child: const Text(
                                            'PENDING REVIEW',
                                            style: TextStyle(
                                              color: AppTheme.warmOchre,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (ngo.missionStatement.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        ngo.missionStatement,
                                        style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (ngo.contactEmail.isNotEmpty) ...[
                                          const Icon(Icons.email_outlined, size: 13, color: AppTheme.textMutedGray),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              ngo.contactEmail,
                                              style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        if (ngo.contactPhone.isNotEmpty) ...[
                                          const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textMutedGray),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              ngo.contactPhone,
                                              style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const Spacer(),
                                    const Divider(color: AppTheme.cardOutline, height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.folder_open_rounded, size: 14, color: AppTheme.ceruleanBlue),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Review Dossier',
                                              style: TextStyle(
                                                color: AppTheme.ceruleanBlue,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.ceruleanBlue,
                                            side: const BorderSide(color: AppTheme.ceruleanBlue),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: const Size(0, 34),
                                          ),
                                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                          label: const Text('Inspect & Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                          onPressed: () {
                                            context.push(
                                              '/admin/ngo-review/${ngo.id}',
                                              extra: ngo,
                                            ).then((_) => _loadAdminData());
                                          },
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
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                          label: const Text('Create Pool', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          onPressed: _showCreatePoolDialog,
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
                              onPressed: _showCreatePoolDialog,
                            ),
                          ],
                        ),
                      )
                    else
                      ..._pooledFunds.map((pool) => _buildPoolCard(pool, currency)),

                    const SizedBox(height: 36),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPoolCard(Campaign pool, AppCurrency currency) {
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

    return GestureDetector(
      onTap: () {
        context.push(
          '/admin/pool/${pool.id}',
          extra: pool,
        ).then((_) => _loadAdminData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfacePureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardOutline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Title, and Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.pastelMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hub_rounded,
                    color: AppTheme.mintGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundIceBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pool.category.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.ceruleanBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
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
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMutedGray),
              ],
            ),

            if (pool.subtitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                pool.subtitle,
                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Participating Campaigns Summary Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundIceBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.groups_rounded, size: 14, color: AppTheme.ceruleanBlue),
                          const SizedBox(width: 6),
                          Text(
                            '${pool.splits.length} Participating Campaigns / NGOs',
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Formula Split',
                        style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: pool.splits.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfacePureWhite,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.cardOutline),
                        ),
                        child: Text(
                          '${s.ngoName} (${s.percentage.toInt()}%)',
                          style: const TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Progress Bar & Financials
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Raised: $raisedStr',
                  style: const TextStyle(
                    color: AppTheme.textSlateNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Goal: $targetStr',
                  style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
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

            const SizedBox(height: 12),
            const Divider(color: AppTheme.cardOutline, height: 1),
            const SizedBox(height: 8),

            // Bottom Tap Prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'Open Pool & Adjust Redistribution Sliders',
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
      ),
    );
  }

  Future<void> _showCreatePoolDialog() async {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final descController = TextEditingController();
    final targetController = TextEditingController(text: '50000');
    final locationController = TextEditingController(text: 'Eastern DRC (Goma & Bukavu)');
    String selectedCategory = 'HEALTH';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfacePureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.cardOutline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.add_circle_outline_rounded, color: AppTheme.ceruleanBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Create Multi-Partner Pool',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textSlateNavy),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Launch a collective fund that redistributes capital across multiple verified NGOs.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMutedGray),
                ),
                const SizedBox(height: 16),

                // Pool Title
                const Text('Pool Name / Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. South Kivu Maternal & Child Health Pool',
                    filled: true,
                    fillColor: AppTheme.backgroundIceBlue,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardOutline)),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                const Text('Short Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: subtitleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Automated split across 3 regional maternity clinics.',
                    filled: true,
                    fillColor: AppTheme.backgroundIceBlue,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardOutline)),
                  ),
                ),
                const SizedBox(height: 12),

                // Category & Target
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundIceBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.cardOutline),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'HEALTH', child: Text('Health')),
                                  DropdownMenuItem(value: 'EMERGENCY', child: Text('Emergency')),
                                  DropdownMenuItem(value: 'EDUCATION', child: Text('Education')),
                                  DropdownMenuItem(value: 'WATER', child: Text('Water & Sanitation')),
                                  DropdownMenuItem(value: 'CHILDREN', child: Text('Children')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedCategory = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Target Goal (USD)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: targetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '50000',
                              prefixText: '\$ ',
                              filled: true,
                              fillColor: AppTheme.backgroundIceBlue,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardOutline)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location
                const Text('Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Bukavu & Uvira, South Kivu',
                    filled: true,
                    fillColor: AppTheme.backgroundIceBlue,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardOutline)),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.ceruleanBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                    ),
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Create & Launch Pool', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final targetUsd = int.tryParse(targetController.text.trim()) ?? 50000;
    final targetUsdCents = targetUsd * 100;
    final targetCdf = CurrencyNotifier.convertUsdToCdf(targetUsdCents);

    // Initial partner splits from verified NGOs or consortium defaults
    final verified = _ngos.where((n) => n.verificationStatus == 'VERIFIED').toList();
    List<CampaignSplit> initialSplits = [];
    if (verified.length >= 2) {
      initialSplits = [
        CampaignSplit(id: 'split-new-1', ngoId: verified[0].id, ngoName: verified[0].name, percentage: 50.0),
        CampaignSplit(id: 'split-new-2', ngoId: verified[1].id, ngoName: verified[1].name, percentage: 50.0),
      ];
    } else {
      initialSplits = [
        CampaignSplit(id: 'split-new-1', ngoId: 'a0000000-0000-0000-0000-000000000001', ngoName: 'Fondation Panzi', percentage: 50.0),
        CampaignSplit(id: 'split-new-2', ngoId: 'a0000000-0000-0000-0000-000000000002', ngoName: 'Sauvons Congo', percentage: 50.0),
      ];
    }

    try {
      await SupabaseService.instance.createPooledFund(
        title: titleController.text.trim(),
        subtitle: subtitleController.text.trim().isEmpty ? 'Multi-partner collaborative cause fund.' : subtitleController.text.trim(),
        description: descController.text.trim().isEmpty ? 'Automated ledger-verified redistribution across partner NGOs.' : descController.text.trim(),
        category: selectedCategory,
        targetAmountUsdCents: targetUsdCents,
        targetAmountCdf: targetCdf,
        imageUrl: 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=1200&q=80',
        location: locationController.text.trim().isEmpty ? 'Democratic Republic of Congo' : locationController.text.trim(),
        splits: initialSplits,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Multi-Partner Pool created successfully!'),
            backgroundColor: AppTheme.mintGreen,
          ),
        );
        _loadAdminData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create pool: $e')),
        );
      }
    }
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

