import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/state/currency_state.dart';
import '../../core/state/data_providers.dart';
import '../../core/state/donation_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class CampaignDetailScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  ConsumerState<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends ConsumerState<CampaignDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final campaigns = ref.watch(campaignsProvider);
    final campaign = campaigns.firstWhere(
      (c) => c.id == widget.campaignId,
      orElse: () => campaigns.first,
    );

    final isUsd = currency == AppCurrency.usd;
    final raisedStr = CurrencyNotifier.formatAmount(
      amountUsdCents: campaign.raisedAmountUsdCents,
      amountCdf: campaign.raisedAmountCdf,
      activeCurrency: currency,
    );
    final targetStr = CurrencyNotifier.formatAmount(
      amountUsdCents: campaign.targetAmountUsdCents,
      amountCdf: campaign.targetAmountCdf,
      activeCurrency: currency,
    );
    final progress = isUsd ? campaign.progressRatioUsd : campaign.progressRatioCdf;

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.surfacePureWhite,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textSlateNavy),
                  onPressed: () => context.pop(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20, color: AppTheme.textSlateNavy),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Campaign link copied to clipboard')),
                      );
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      campaign.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.powderBlue,
                          child: const Center(
                            child: Icon(Icons.volunteer_activism_rounded, color: AppTheme.ceruleanBlue, size: 48),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              PastelBadge.category(campaign.category),
                              const SizedBox(width: 8),
                              if (campaign.isPooledFund) PastelBadge.pooled(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            campaign.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Progress Bar and Metric Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.backgroundIceBlue,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppTheme.cardOutline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppTheme.mintGreen, size: 16),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Arrêté Ministériel Verified',
                          style: TextStyle(
                            color: AppTheme.mintGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on, color: AppTheme.textMutedGray, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        campaign.location,
                        style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomLinearProgress(value: progress, height: 10),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            raisedStr,
                            style: const TextStyle(
                              color: AppTheme.ceruleanBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Target: $targetStr',
                            style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.powderBlue,
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}% funded',
                          style: const TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 3 Content Tabs: About, Redistribution Split, Impact Proofs
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.ceruleanBlue,
              unselectedLabelColor: AppTheme.textMutedGray,
              indicatorColor: AppTheme.ceruleanBlue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Redistribution'),
                Tab(text: 'Impact Proofs'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(campaign),
                  _buildRedistributionTab(campaign),
                  _buildImpactProofsTab(campaign),
                ],
              ),
            ),
          ],
        ),
      ),
      // Sticky Bottom Bar: Full-Width Donate Now Pill
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppTheme.surfacePureWhite,
          border: Border(top: BorderSide(color: AppTheme.cardOutline, width: 1)),
        ),
        child: SafeArea(
          child: PillButton(
            label: 'Donate Now',
            icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
            onPressed: () {
              ref.read(donationFlowProvider.notifier).setCampaign(campaign);
              context.push('/donor/donate');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(Campaign campaign) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Mission & Objective',
          style: TextStyle(
            color: AppTheme.textSlateNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          campaign.description,
          style: const TextStyle(
            color: AppTheme.textSlateNavy,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Audited Non-Profit Governance',
          style: TextStyle(
            color: AppTheme.textSlateNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundIceBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardOutline),
          ),
          child: Column(
            children: [
              _buildGovRow('Governing NGO', campaign.ngoName ?? 'Autonomous Pooled Consortium'),
              const Divider(color: AppTheme.cardOutline, height: 16),
              _buildGovRow('Legal Registry', 'Arrêté N° 045/CAB/MIN/J&DH/2021'),
              const Divider(color: AppTheme.cardOutline, height: 16),
              _buildGovRow('Accounting Ledger', 'Double-Entry Invariant (PostgreSQL)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGovRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 13)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppTheme.textSlateNavy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRedistributionTab(Campaign campaign) {
    if (!campaign.isPooledFund || campaign.splits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.volunteer_activism_rounded, color: AppTheme.ceruleanBlue, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Direct NGO Allocation',
                style: TextStyle(
                  color: AppTheme.textSlateNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '100% of donations to this campaign are disbursed directly to ${campaign.ngoName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Pooled Fund Allocation Formula',
          style: TextStyle(
            color: AppTheme.textSlateNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Every dollar or Congolese franc given is split atomically into separate NGO payable sub-accounts upon payment confirmation.',
          style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ...campaign.splits.map((split) {
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.powderBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${split.percentage.toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.ceruleanBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
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
                        split.ngoName,
                        style: const TextStyle(
                          color: AppTheme.textSlateNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Verified Local Beneficiary Partner',
                        style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildImpactProofsTab(Campaign campaign) {
    if (campaign.impactUpdates.isEmpty) {
      return const Center(
        child: Text(
          'No impact reports published yet.',
          style: TextStyle(color: AppTheme.textMutedGray),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: campaign.impactUpdates.map((update) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppTheme.backgroundIceBlue,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardOutline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (update.mediaUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    update.mediaUrls.first,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        color: AppTheme.powderBlue,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: AppTheme.textMutedGray, size: 36),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            update.ngoName,
                            style: const TextStyle(
                              color: AppTheme.ceruleanBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.receipt_long_rounded, size: 14, color: AppTheme.mintGreen),
                        const SizedBox(width: 4),
                        const Text(
                          'Receipt Verified',
                          style: TextStyle(
                            color: AppTheme.mintGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      update.title,
                      style: const TextStyle(
                        color: AppTheme.textSlateNavy,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      update.content,
                      style: const TextStyle(
                        color: AppTheme.textMutedGray,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
