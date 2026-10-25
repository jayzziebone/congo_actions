import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/auth_state.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/data_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class NgoDashboardScreen extends ConsumerStatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  ConsumerState<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends ConsumerState<NgoDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Ngo? _ngo;
  int _clearedBalanceUsdCents = 0;
  int _clearedBalanceCdf = 0;
  List<Donation> _ngoDonations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNgoData();
  }

  Future<void> _loadNgoData() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;
    if (user != null) {
      final ngo = await SupabaseService.instance.fetchNgoForUser(user.id);
      if (ngo != null) {
        final bal = await SupabaseService.instance.fetchNgoBalance(ngo.id);
        final dons = await SupabaseService.instance.fetchDonationsForNgo(ngo.id);
        if (mounted) {
          setState(() {
            _ngo = ngo;
            _clearedBalanceUsdCents = bal['USD'] ?? 0;
            _clearedBalanceCdf = bal['CDF'] ?? 0;
            _ngoDonations = dons;
            _isLoading = false;
          });
        }
        return;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showRegisterNgoModal() {
    final authState = ref.read(authProvider);
    final defaultName = authState.user?.fullName.isNotEmpty == true
        ? '${authState.user!.fullName} Initiative'
        : 'Sauvons Congo';
    final nameController = TextEditingController(text: defaultName);
    final regController = TextEditingController(text: 'F92/2026/${DateTime.now().millisecond + 100}');
    final missionController = TextEditingController(
      text: 'Direct humanitarian relief, clean water, healthcare, and education in the Democratic Republic of Congo.',
    );
    final emailController = TextEditingController(text: authState.user?.email ?? '');
    final phoneController = TextEditingController(text: '+243 999 123 456');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppTheme.surfacePureWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.cardOutline,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Register NGO Organization',
                          style: TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMutedGray),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.cardOutline, height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text('Organization Legal Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Sauvons Congo, Fondation Panzi',
                            filled: true,
                            fillColor: AppTheme.backgroundIceBlue,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Legal Registration / F92 Number', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: regController,
                          decoration: InputDecoration(
                            hintText: 'e.g. F.92/34.901/2026',
                            filled: true,
                            fillColor: AppTheme.backgroundIceBlue,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Mission Statement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: missionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Describe your core humanitarian purpose in DRC',
                            filled: true,
                            fillColor: AppTheme.backgroundIceBlue,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Official Contact Email', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'contact@ngo.org',
                            filled: true,
                            fillColor: AppTheme.backgroundIceBlue,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Contact Phone Number (DRC / International)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '+243 999 123 456',
                            filled: true,
                            fillColor: AppTheme.backgroundIceBlue,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 24),

                        PillButton(
                          label: isSubmitting ? 'Registering Organization...' : 'Complete NGO Registration',
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          onPressed: isSubmitting ? null : () async {
                            final orgName = nameController.text.trim();
                            final regNo = regController.text.trim();
                            final mission = missionController.text.trim();
                            final email = emailController.text.trim();
                            final phone = phoneController.text.trim();

                            if (orgName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter the organization name')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              final user = ref.read(authProvider).user;
                              await SupabaseService.instance.registerNgo(
                                adminUserId: user?.id,
                                name: orgName,
                                legalRegistrationNumber: regNo.isNotEmpty ? regNo : 'F92/PENDING',
                                missionStatement: mission.isNotEmpty ? mission : orgName,
                                contactEmail: email.isNotEmpty ? email : (user?.email ?? 'info@congoactions.org'),
                                contactPhone: phone.isNotEmpty ? phone : '+243 000 000 000',
                              );

                              if (modalCtx.mounted) {
                                Navigator.pop(modalCtx);
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('NGO "$orgName" registered successfully! You can now create campaigns.'),
                                    backgroundColor: AppTheme.mintGreen,
                                  ),
                                );
                                await _loadNgoData();
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error registering NGO: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateCampaignModal() {
    if (_ngo == null) {
      _showRegisterNgoModal();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register your NGO organization before launching a campaign.')),
      );
      return;
    }

    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final descController = TextEditingController();
    final goalUsdController = TextEditingController(text: '5000');
    final locationController = TextEditingController(text: 'Goma, North Kivu, DRC');
    String selectedCategory = 'HEALTH';
    String selectedImageUrl = 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80';
    bool isSubmitting = false;

    final presetImages = [
      {'label': 'Hospital & Health', 'url': 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80'},
      {'label': 'Education & Youth', 'url': 'https://images.unsplash.com/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=800&q=80'},
      {'label': 'Clean Solar Water', 'url': 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&w=800&q=80'},
      {'label': 'Emergency Nutrition', 'url': 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=800&q=80'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: AppTheme.surfacePureWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.cardOutline,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Launch New Campaign',
                          style: TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMutedGray),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.cardOutline, height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text('Campaign Title', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Solar Incubators for Goma Hospital',
                            filled: true,
                            fillColor: AppTheme.backgroundIceBlue,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Short Summary / Subtitle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: subtitleController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Providing 24/7 power to save premature newborns',
                            filled: true,
                            fillColor: AppTheme.backgroundIceBlue,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundIceBlue,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedCategory,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(value: 'HEALTH', child: Text('Health')),
                                          DropdownMenuItem(value: 'EDUCATION', child: Text('Education')),
                                          DropdownMenuItem(value: 'CHILDREN', child: Text('Children')),
                                          DropdownMenuItem(value: 'EMERGENCY', child: Text('Emergency')),
                                          DropdownMenuItem(value: 'INFRASTRUCTURE', child: Text('Infrastructure')),
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
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Target Goal (USD)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: goalUsdController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixText: '\$ ',
                                      filled: true,
                                      fillColor: AppTheme.backgroundIceBlue,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text('Location in DRC', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Bukavu, South Kivu, DRC',
                            filled: true,
                            fillColor: AppTheme.backgroundIceBlue,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Detailed Description & Objectives', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Describe the emergency, expected beneficiaries, and how funds will be deployed...',
                            filled: true,
                            fillColor: AppTheme.backgroundIceBlue,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Select Cover Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSlateNavy)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: presetImages.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              final img = presetImages[idx];
                              final isSelected = selectedImageUrl == img['url'];
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedImageUrl = img['url']!),
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.ceruleanBlue : AppTheme.cardOutline,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(img['url']!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        PillButton(
                          label: isSubmitting ? 'Publishing to DRC & Diaspora...' : 'Publish Live Campaign',
                          icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                          onPressed: isSubmitting ? null : () async {
                            final title = titleController.text.trim();
                            final subtitle = subtitleController.text.trim();
                            final desc = descController.text.trim();
                            final goalUsd = int.tryParse(goalUsdController.text.trim()) ?? 5000;
                            final location = locationController.text.trim();

                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a campaign title')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);

                            try {
                              final goalUsdCents = goalUsd * 100;
                              final goalCdf = goalUsd * 2800; // standard 2800 FC/$ rate

                              await SupabaseService.instance.createCampaign(
                                ngoId: _ngo!.id,
                                title: title,
                                subtitle: subtitle.isNotEmpty ? subtitle : title,
                                description: desc.isNotEmpty ? desc : title,
                                category: selectedCategory,
                                targetAmountUsdCents: goalUsdCents,
                                targetAmountCdf: goalCdf,
                                imageUrl: selectedImageUrl,
                                location: location.isNotEmpty ? location : 'DRC',
                              );

                              // Refresh global campaigns provider
                              ref.read(campaignsProvider.notifier).state = [...SupabaseService.instance.campaigns];

                              if (modalCtx.mounted) {
                                Navigator.pop(modalCtx);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Campaign "$title" published live! Donors can now view and donate.'),
                                    backgroundColor: AppTheme.mintGreen,
                                  ),
                                );
                                _loadNgoData();
                              }
                            } catch (err) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error publishing campaign: $err')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final allCampaigns = ref.watch(campaignsProvider);
    final authState = ref.watch(authProvider);

    final ngoName = _ngo?.name ?? authState.user?.fullName ?? 'Sauvons Congo';
    final isVerified = _ngo?.verificationStatus == 'VERIFIED';
    final regNumber = _ngo?.legalRegistrationNumber ?? 'Pending Registration';

    // Filter campaigns belonging specifically to this NGO
    final myCampaigns = _ngo != null
        ? allCampaigns.where((c) => c.ngoId == _ngo!.id).toList()
        : <Campaign>[];

    final clearedBalanceStr = CurrencyNotifier.formatAmount(
      amountUsdCents: _clearedBalanceUsdCents,
      amountCdf: _clearedBalanceCdf,
      activeCurrency: currency,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.surfacePureWhite,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('NGO Organizer Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.textSlateNavy, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Navigation Menu',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSlateNavy),
            tooltip: 'Refresh Ledger',
            onPressed: _loadNgoData,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CurrencyTogglePill(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCampaignModal,
        backgroundColor: AppTheme.ceruleanBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Create Campaign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNgoData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // NGO Header
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isVerified ? AppTheme.pastelMint : AppTheme.pastelButtercream,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.corporate_fare_rounded,
                              color: isVerified ? AppTheme.mintGreen : AppTheme.warmOchre,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      ngoName,
                                      style: const TextStyle(
                                        color: AppTheme.textSlateNavy,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (isVerified)
                                    PastelBadge.verified()
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.pastelButtercream,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Verification Pending',
                                        style: TextStyle(color: AppTheme.warmOchre, fontSize: 10, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$regNumber • NGO Portal',
                                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_ngo == null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.pastelButtercream.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.warmOchre.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.business_center_rounded, color: AppTheme.warmOchre, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'Register Your NGO Entity',
                                  style: TextStyle(
                                    color: AppTheme.textSlateNavy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'To launch humanitarian campaigns, receive mobile money donations, and request treasury disbursements, register your legal NGO entity.',
                              style: TextStyle(color: AppTheme.textSlateNavy, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            PillButton(
                              label: 'Register NGO Organization',
                              icon: const Icon(Icons.add_business_rounded, color: Colors.white, size: 18),
                              onPressed: _showRegisterNgoModal,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Cleared Balance Card with Prominent Actions
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
                                  'Available Cleared Balance',
                                  style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _clearedBalanceUsdCents > 0 ? AppTheme.pastelMint : AppTheme.backgroundIceBlue,
                                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                  border: Border.all(color: AppTheme.cardOutline),
                                ),
                                child: Text(
                                  _clearedBalanceUsdCents > 0 ? 'Ready for Payout' : 'Zero Balance',
                                  style: TextStyle(
                                    color: _clearedBalanceUsdCents > 0 ? AppTheme.mintGreen : AppTheme.textMutedGray,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            clearedBalanceStr,
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: PillButton(
                                  label: 'Withdraw',
                                  icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
                                  onPressed: () => context.push('/ngo/withdraw'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: AppTheme.ceruleanBlue),
                                  ),
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppTheme.ceruleanBlue),
                                  label: const Text('New Campaign', style: TextStyle(color: AppTheme.ceruleanBlue, fontSize: 13, fontWeight: FontWeight.w700)),
                                  onPressed: _showCreateCampaignModal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Managed Campaigns Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Campaigns (${myCampaigns.length})',
                          style: const TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Cause'),
                          onPressed: _showCreateCampaignModal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (myCampaigns.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundIceBlue,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.cardOutline),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.campaign_outlined, size: 48, color: AppTheme.textMutedGray),
                            const SizedBox(height: 12),
                            const Text(
                              'No Campaigns Published Yet',
                              style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Create your first cause so donors in the DRC and diaspora can start contributing.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            PillButton(
                              label: 'Launch First Campaign',
                              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              onPressed: _showCreateCampaignModal,
                            ),
                          ],
                        ),
                      )
                    else
                      ...myCampaigns.map((camp) {
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  camp.imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 56,
                                    height: 56,
                                    color: AppTheme.powderBlue,
                                    child: const Icon(Icons.image, color: AppTheme.ceruleanBlue),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      camp.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.textSlateNavy,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Raised: $raisedStr of $targetStr',
                                      style: const TextStyle(color: AppTheme.mintGreen, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMutedGray),
                                onPressed: () => context.push('/donor/campaign/${camp.id}'),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 28),

                    // Real Donations Received History
                    const Text(
                      'Direct Donations Received',
                      style: TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_ngoDonations.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundIceBlue,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardOutline),
                        ),
                        child: const Center(
                          child: Text(
                            'No donations received yet. Funds will appear here once donors contribute.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ..._ngoDonations.map((don) {
                        final amtStr = CurrencyNotifier.formatAmount(
                          amountUsdCents: don.amountUsdCents,
                          amountCdf: don.amountCdf,
                          activeCurrency: currency,
                        );
                        final dateStr = DateFormat('dd MMM yyyy • HH:mm').format(don.createdAt);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundIceBlue,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.cardOutline),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.pastelMint,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.mintGreen, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      don.campaignTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    Text(dateStr, style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(
                                '+$amtStr',
                                style: const TextStyle(color: AppTheme.mintGreen, fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 60),
                  ],
                ),
        ),
      ),
    );
  }
}
