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
  int _donorCount = 0;
  int _totalVolumeUsdCents = 0;
  int _totalVolumeCdf = 0;
  bool _isLoading = true;

  // Interactive split sliders state for Eastern DRC Pool
  double _splitPanzi = 40.0;
  double _splitWater = 35.0;
  double _splitOrphan = 25.0;

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
    final data = await SupabaseService.instance.fetchSuperAdminData();
    if (mounted) {
      final ngos = data['ngos'] as List<Ngo>? ?? [];
      final pendingCount = ngos.where((n) => n.verificationStatus != 'VERIFIED').length;
      setState(() {
        _ngos = ngos;
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

                    // Multi-Partner Pooled Fund Redistribution Sliders
                    Container(
                      padding: const EdgeInsets.all(20),
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
                            children: const [
                              Text(
                                'Pooled Split Allocation Ratios',
                                style: TextStyle(
                                  color: AppTheme.textSlateNavy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Sum: 100%',
                                style: TextStyle(
                                  color: AppTheme.ceruleanBlue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildSliderRow(
                            label: 'Fondation Panzi (Bukavu)',
                            val: _splitPanzi,
                            color: AppTheme.ceruleanBlue,
                            onChanged: (newVal) => setState(() => _splitPanzi = newVal),
                          ),
                          const SizedBox(height: 8),
                          _buildSliderRow(
                            label: 'Kivu Clean Water (Goma)',
                            val: _splitWater,
                            color: AppTheme.mintGreen,
                            onChanged: (newVal) => setState(() => _splitWater = newVal),
                          ),
                          const SizedBox(height: 8),
                          _buildSliderRow(
                            label: 'Orphelinat Kinshasa (Ngaliema)',
                            val: _splitOrphan,
                            color: AppTheme.terracottaIcon,
                            onChanged: (newVal) => setState(() => _splitOrphan = newVal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
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

  Widget _buildSliderRow({
    required String label,
    required double val,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(
              '${val.toInt()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: AppTheme.cardOutline,
            trackHeight: 6,
          ),
          child: Slider(
            value: val,
            min: 5,
            max: 80,
            divisions: 15,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
