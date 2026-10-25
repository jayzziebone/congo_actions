import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class RegisteredNgosScreen extends ConsumerStatefulWidget {
  const RegisteredNgosScreen({super.key});

  @override
  ConsumerState<RegisteredNgosScreen> createState() => _RegisteredNgosScreenState();
}

class _RegisteredNgosScreenState extends ConsumerState<RegisteredNgosScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  List<Ngo> _verifiedNgos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVerifiedNgos();
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

  Future<void> _loadVerifiedNgos() async {
    setState(() => _isLoading = true);
    final ngos = await SupabaseService.instance.fetchVerifiedNgos();
    if (mounted) {
      setState(() {
        _verifiedNgos = ngos;
        _isLoading = false;
      });
    }
  }

  List<Ngo> get _filteredNgos {
    if (_searchQuery.isEmpty) return _verifiedNgos;
    return _verifiedNgos.where((ngo) {
      final matchName = ngo.name.toLowerCase().contains(_searchQuery);
      final matchReg = ngo.legalRegistrationNumber.toLowerCase().contains(_searchQuery);
      final matchMission = ngo.missionStatement.toLowerCase().contains(_searchQuery);
      final matchEmail = ngo.contactEmail.toLowerCase().contains(_searchQuery);
      return matchName || matchReg || matchMission || matchEmail;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.surfacePureWhite,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Registered NGOs'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.textSlateNavy, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Navigation Menu',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSlateNavy),
            tooltip: 'Refresh Directory',
            onPressed: _loadVerifiedNgos,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CurrencyTogglePill(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadVerifiedNgos,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Hero Summary Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppTheme.pastelMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.verified_user_rounded,
                          color: AppTheme.mintGreen,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_verifiedNgos.length}',
                                style: const TextStyle(
                                  color: AppTheme.textSlateNavy,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Verified Congolese NGOs',
                                  style: TextStyle(
                                    color: AppTheme.textSlateNavy,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Officially accredited organizations approved for public fundraising.',
                            style: TextStyle(
                              color: AppTheme.textMutedGray,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Filter Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by NGO name, registration N°, email...',
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.cardOutline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.cardOutline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.ceruleanBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Results Count and Link to Pending
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'All Verified Organizations (${_verifiedNgos.length})'
                          : 'Matching NGOs (${_filteredNgos.length})',
                      style: const TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.warmOchre,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.pending_actions_rounded, size: 16),
                    label: const Text('Pending Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    onPressed: () => context.go('/admin'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredNgos.isEmpty)
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
                        _searchQuery.isEmpty ? Icons.verified_outlined : Icons.search_off_rounded,
                        size: 44,
                        color: AppTheme.textMutedGray,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No Verified NGOs Yet'
                            : 'No NGOs match "$_searchQuery"',
                        style: const TextStyle(
                          color: AppTheme.textSlateNavy,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchQuery.isEmpty
                            ? 'When you approve NGO registration applications from the SuperAdmin Console, they will appear here.'
                            : 'Try searching by a different name or legal registration number.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.ceruleanBlue,
                            side: const BorderSide(color: AppTheme.ceruleanBlue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Go to SuperAdmin Console', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          onPressed: () => context.go('/admin'),
                        ),
                      ],
                    ],
                  ),
                )
              else
                ..._filteredNgos.map((ngo) => _buildNgoCard(ngo)),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNgoCard(Ngo ngo) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(ngo.createdAt);

    return GestureDetector(
      onTap: () {
        context.push(
          '/admin/ngo-review/${ngo.id}',
          extra: ngo,
        ).then((_) => _loadVerifiedNgos());
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
            // Header with Icon, Name, and Verified Badge
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
                    Icons.corporate_fare_rounded,
                    color: AppTheme.mintGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ngo.name,
                        style: const TextStyle(
                          color: AppTheme.textSlateNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Arrêté N°: ${ngo.legalRegistrationNumber}',
                        style: const TextStyle(
                          color: AppTheme.textMutedGray,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PastelBadge.verified(compact: true),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textMutedGray),
              ],
            ),

            if (ngo.missionStatement.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                ngo.missionStatement,
                style: const TextStyle(
                  color: AppTheme.textSlateNavy,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: AppTheme.cardOutline, height: 1),
            const SizedBox(height: 10),

            // Contact Details
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (ngo.contactEmail.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: AppTheme.textMutedGray),
                      const SizedBox(width: 5),
                      Text(
                        ngo.contactEmail,
                        style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                      ),
                    ],
                  ),
                if (ngo.contactPhone.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textMutedGray),
                      const SizedBox(width: 5),
                      Text(
                        ngo.contactPhone,
                        style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),

            // Bank / Mobile Money Payout Account if available
            if (ngo.bankName != null || ngo.mobileMoneyMerchant != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ngo.bankName != null ? Icons.account_balance_rounded : Icons.phone_android_rounded,
                      size: 14,
                      color: AppTheme.ceruleanBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ngo.bankName != null
                          ? 'Treasury Bank: ${ngo.bankName} (${ngo.bankRib ?? 'Configured'})'
                          : 'Merchant: ${ngo.mobileMoneyMerchant}',
                      style: const TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registered: $formattedDate',
                  style: const TextStyle(
                    color: AppTheme.textMutedGray,
                    fontSize: 11,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelMint.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Good Standing • Active',
                    style: TextStyle(
                      color: AppTheme.mintGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: AppTheme.cardOutline, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'Inspect NGO Dossier & Legal Files',
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
