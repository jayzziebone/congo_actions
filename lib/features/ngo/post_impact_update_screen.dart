import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../core/state/data_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class PostImpactUpdateScreen extends ConsumerStatefulWidget {
  const PostImpactUpdateScreen({super.key});

  @override
  ConsumerState<PostImpactUpdateScreen> createState() => _PostImpactUpdateScreenState();
}

class _PostImpactUpdateScreenState extends ConsumerState<PostImpactUpdateScreen> {
  final _titleController = TextEditingController(text: 'Delivery of 50 Specialized Maternity Beds in Bukavu');
  final _contentController = TextEditingController(
    text: 'We are thrilled to announce that the new surgical recovery ward has been fully furnished using the recent \$12,000 disbursement. Below is the signed supplier delivery voucher and high-resolution photo proof from the ward.',
  );

  bool _hasPhoto = true;
  bool _isCompressing = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publishUpdate() async {
    setState(() => _isPublishing = true);

    await SupabaseService.instance.addImpactUpdate(
      campaignId: 'camp-pooled-1',
      ngoId: 'ngo-panzi',
      ngoName: 'Fondation Panzi',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      mediaUrls: [
        'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
      ],
      receiptImageUrl: 'https://images.unsplash.com/photo-1554415707-9e4466a9c396?auto=format&fit=crop&w=400&q=80',
    );

    refreshAllData(ref);

    setState(() => _isPublishing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impact Proof published! 420 past donors notified via push and WhatsApp.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('Post Field Impact Proof'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/ngo');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.pastelMint.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.pastelMint),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_rounded, color: AppTheme.mintGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Direct proof updates are broadcasted to all past donors who contributed to your pool or campaign.',
                        style: TextStyle(color: AppTheme.textSlateNavy, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Update Headline',
                style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Well #4 Drilled & Providing Clean Water',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Impact Narrative & Beneficiary Details',
                style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe how the funds were deployed and who was helped...',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Field Media & Compressed Photos',
                style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 10),
              // Photo attachment box
              GestureDetector(
                onTap: () {
                  setState(() => _isCompressing = true);
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (mounted) {
                      setState(() {
                        _isCompressing = false;
                        _hasPhoto = true;
                      });
                    }
                  });
                },
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundIceBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardOutline),
                  ),
                  child: _isCompressing
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(strokeWidth: 2, color: AppTheme.ceruleanBlue),
                              SizedBox(height: 8),
                              Text(
                                'Compressing image via flutter_image_compress (JPEG 80%)...',
                                style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      : (_hasPhoto
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=800&q=80',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('Compressed (420 KB)', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, color: AppTheme.ceruleanBlue, size: 32),
                                SizedBox(height: 6),
                                Text(
                                  'Tap to take photo or pick from gallery',
                                  style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
                                ),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Proof of Expense: Verified Receipt / Invoices',
                style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppTheme.mintGreen, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Delivery_Voucher_Panzi_Ward.pdf',
                            style: TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text('Signed by Dr. Mukwege & Rawbank Wire Stamp', style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: AppTheme.mintGreen, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PillButton(
                label: 'Publish Proof & Broadcast to Donors',
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                isLoading: _isPublishing,
                onPressed: _publishUpdate,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
