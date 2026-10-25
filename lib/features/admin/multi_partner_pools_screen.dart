import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/currency_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class MultiPartnerPoolsScreen extends ConsumerStatefulWidget {
  const MultiPartnerPoolsScreen({super.key});

  @override
  ConsumerState<MultiPartnerPoolsScreen> createState() => _MultiPartnerPoolsScreenState();
}

class _MultiPartnerPoolsScreenState extends ConsumerState<MultiPartnerPoolsScreen> {
  List<Campaign> _pools = [];
  List<Ngo> _ngos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPools();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPools() async {
    setState(() => _isLoading = true);
    await SupabaseService.instance.fetchLiveCampaigns();
    final allCampaigns = SupabaseService.instance.campaigns;
    final verifiedNgos = await SupabaseService.instance.fetchVerifiedNgos();

    if (mounted) {
      setState(() {
        _pools = allCampaigns.where((c) => c.isPooledFund).toList();
        _ngos = verifiedNgos;
        _isLoading = false;
      });
    }
  }

  List<Campaign> get _filteredPools {
    if (_searchQuery.isEmpty) return _pools;
    return _pools.where((p) {
      final titleMatch = p.title.toLowerCase().contains(_searchQuery);
      final categoryMatch = p.category.toLowerCase().contains(_searchQuery);
      final locationMatch = p.location.toLowerCase().contains(_searchQuery);
      final partnerMatch = p.splits.any((s) => s.ngoName.toLowerCase().contains(_searchQuery));
      return titleMatch || categoryMatch || locationMatch || partnerMatch;
    }).toList();
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

    List<CampaignSplit> initialSplits = [];
    if (_ngos.length >= 2) {
      initialSplits = [
        CampaignSplit(id: 'split-new-1', ngoId: _ngos[0].id, ngoName: _ngos[0].name, percentage: 50.0),
        CampaignSplit(id: 'split-new-2', ngoId: _ngos[1].id, ngoName: _ngos[1].name, percentage: 50.0),
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
        _loadPools();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create pool: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final filtered = _filteredPools;

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('All Multi-Partner Pools'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textSlateNavy),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSlateNavy),
            tooltip: 'Refresh Pools',
            onPressed: _loadPools,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CurrencyTogglePill(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPools,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              // Header Summary Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.pastelMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hub_rounded, color: AppTheme.mintGreen, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_pools.length} Multi-Partner Pools',
                                style: const TextStyle(
                                  color: AppTheme.textSlateNavy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              PastelBadge.pooled(),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Collective consortium funds with automated ledger-verified redistribution formulas.',
                            style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Search Bar & Create Button Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search pools by title, category, partner...',
                        hintStyle: const TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMutedGray, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.backgroundIceBlue,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.cardOutline)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.cardOutline)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.ceruleanBlue, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.ceruleanBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create Pool', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    onPressed: _showCreatePoolDialog,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Results count
              Text(
                _searchQuery.isEmpty
                    ? 'All Active Pools (${_pools.length})'
                    : 'Matching Pools (${filtered.length})',
                style: const TextStyle(
                  color: AppTheme.textSlateNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundIceBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardOutline),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _searchQuery.isEmpty ? Icons.hub_outlined : Icons.search_off_rounded,
                        size: 44,
                        color: AppTheme.textMutedGray,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty ? 'No Pools Available' : 'No Pools match "$_searchQuery"',
                        style: const TextStyle(
                          color: AppTheme.textSlateNavy,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Tap "+ Create Pool" to establish your first multi-partner consortium.'
                            : 'Try searching by a different name, sector, or partner NGO.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((pool) => _buildFullPoolCard(pool, currency)),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullPoolCard(Campaign pool, AppCurrency currency) {
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
        context.push('/admin/pool/${pool.id}', extra: pool).then((_) => _loadPools());
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
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.pastelMint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hub_rounded, color: AppTheme.mintGreen, size: 20),
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
                          fontSize: 16,
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
                        'Redistribution Split',
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
                  'Manage Pool & Redistribution Sliders',
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
}
