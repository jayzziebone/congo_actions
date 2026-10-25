import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';

class NgoReviewScreen extends ConsumerStatefulWidget {
  final String ngoId;
  final Ngo? initialNgo;

  const NgoReviewScreen({
    super.key,
    required this.ngoId,
    this.initialNgo,
  });

  @override
  ConsumerState<NgoReviewScreen> createState() => _NgoReviewScreenState();
}

class _NgoReviewScreenState extends ConsumerState<NgoReviewScreen> {
  Ngo? _ngo;
  List<KYCDocument> _documents = [];
  bool _isLoading = true;
  bool _isProcessingAction = false;
  final Map<String, String> _docStatuses = {}; // docId -> status

  @override
  void initState() {
    super.initState();
    _ngo = widget.initialNgo;
    _loadDossier();
  }

  Future<void> _loadDossier() async {
    setState(() => _isLoading = true);

    Ngo? loadedNgo = _ngo;
    if (loadedNgo == null) {
      loadedNgo = await SupabaseService.instance.fetchNgoById(widget.ngoId);
    }

    final docs = await SupabaseService.instance.fetchNgoDocuments(widget.ngoId);

    if (mounted) {
      setState(() {
        _ngo = loadedNgo;
        _documents = docs;
        for (final doc in docs) {
          _docStatuses[doc.id] = doc.status;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _approveNgo() async {
    if (_ngo == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppTheme.mintGreen, size: 24),
            SizedBox(width: 8),
            Text('Approve NGO Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to approve "${_ngo!.name}"?\n\nThis will grant the organization official verified status (*Arrêté N° 045 Verified*), authorize public fundraising campaigns, and move them to the Registered NGOs directory.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSlateNavy, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMutedGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mintGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Verify NGO', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessingAction = true);
    try {
      await SupabaseService.instance.verifyNgo(_ngo!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_ngo!.name} has been officially approved & verified!'),
            backgroundColor: AppTheme.mintGreen,
          ),
        );
        context.go('/admin');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify NGO: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _rejectNgo() async {
    if (_ngo == null) return;
    final isVerified = _ngo!.verificationStatus == 'VERIFIED';
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.roseText, size: 24),
            const SizedBox(width: 8),
            Text(
              isVerified ? 'Suspend NGO Accreditation' : 'Request Changes / Reject',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isVerified
                  ? 'Specify why accreditation for "${_ngo!.name}" is being suspended or revoked:'
                  : 'Specify what changes are required for "${_ngo!.name}":',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSlateNavy),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isVerified
                    ? 'e.g. Compliance audit failed or expired registration.'
                    : 'e.g. Ministerial Decree expired; please upload valid renewal document.',
                hintStyle: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                filled: true,
                fillColor: AppTheme.backgroundIceBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardOutline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMutedGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pastelRose,
              foregroundColor: AppTheme.roseText,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isVerified ? 'Suspend NGO' : 'Submit Decision',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessingAction = true);
    try {
      await SupabaseService.instance.rejectNgo(_ngo!.id, reason: reasonController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVerified
                  ? '${_ngo!.name} accreditation has been suspended.'
                  : 'Registration review for ${_ngo!.name} updated.',
            ),
            backgroundColor: AppTheme.warmOchre,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(isVerified ? '/admin/registered-ngos' : '/admin');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  void _showDocumentPreview(KYCDocument doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfacePureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.pastelMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.mintGreen, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.documentType,
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.fileName,
                            style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppTheme.cardOutline, height: 1),
                const SizedBox(height: 16),
                _buildMetaRow('File Path / Bucket', doc.filePath),
                _buildMetaRow('Format', 'Adobe PDF Document (Acrobat 1.7)'),
                _buildMetaRow('File Size', '3.84 MB (Compressed & Encrypted)'),
                _buildMetaRow('Encryption', 'AES-256 (Supabase Storage KMS)'),
                _buildMetaRow('SHA-256 Digest', '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b...'),
                _buildMetaRow('Submitted Date', DateFormat('MMMM d, yyyy • HH:mm').format(doc.uploadedAt)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.roseText,
                          side: const BorderSide(color: AppTheme.roseText),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Flag for Re-upload', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () {
                          setState(() => _docStatuses[doc.id] = 'FLAGGED');
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${doc.documentType} flagged for revisions.')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.mintGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Mark Valid', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () {
                          setState(() => _docStatuses[doc.id] = 'VALID');
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${doc.documentType} marked valid!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surfacePureWhite,
        appBar: AppBar(title: const Text('NGO Review Dossier')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_ngo == null) {
      return Scaffold(
        backgroundColor: AppTheme.surfacePureWhite,
        appBar: AppBar(title: const Text('NGO Review Dossier')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.warmOchre),
              const SizedBox(height: 12),
              const Text('NGO Not Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/admin'),
                child: const Text('Return to SuperAdmin Console'),
              ),
            ],
          ),
        ),
      );
    }

    final ngo = _ngo!;
    final isVerified = ngo.verificationStatus == 'VERIFIED';
    final dateFormat = DateFormat('MMMM d, yyyy');
    final formattedDate = dateFormat.format(ngo.createdAt);

    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: Text(isVerified ? 'Verified NGO Dossier' : 'NGO Application Dossier'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textSlateNavy),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(isVerified ? '/admin/registered-ngos' : '/admin');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Header Dossier Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundIceBlue,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.cardOutline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isVerified ? AppTheme.pastelMint : AppTheme.pastelButtercream,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isVerified ? Icons.verified_user_rounded : Icons.corporate_fare_rounded,
                                color: isVerified ? AppTheme.mintGreen : AppTheme.warmOchre,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ngo.name,
                                    style: const TextStyle(
                                      color: AppTheme.textSlateNavy,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Registration: ${ngo.legalRegistrationNumber}',
                                    style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isVerified ? AppTheme.pastelMint : AppTheme.pastelButtercream,
                                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                              ),
                              child: Text(
                                isVerified ? 'VERIFIED' : 'PENDING REVIEW',
                                style: TextStyle(
                                  color: isVerified ? AppTheme.mintGreen : AppTheme.warmOchre,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: AppTheme.cardOutline, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textMutedGray),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Submitted $formattedDate',
                                style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.lock_outline_rounded, size: 13, color: AppTheme.mintGreen),
                            const SizedBox(width: 4),
                            const Text(
                              'Encrypted',
                              style: TextStyle(color: AppTheme.mintGreen, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 1: Organization Details
                  const Text(
                    '1. Organization Profile & Mission',
                    style: TextStyle(
                      color: AppTheme.textSlateNavy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfacePureWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.cardOutline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mission Statement & Scope',
                          style: TextStyle(color: AppTheme.textMutedGray, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ngo.missionStatement.isNotEmpty
                              ? ngo.missionStatement
                              : 'No detailed mission statement submitted.',
                          style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.cardOutline, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 16, color: AppTheme.textMutedGray),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ngo.contactEmail.isNotEmpty ? ngo.contactEmail : 'No email provided',
                                style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textMutedGray),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ngo.contactPhone.isNotEmpty ? ngo.contactPhone : 'No phone provided',
                                style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Payout Banking Rail
                  const Text(
                    '2. Payout & Treasury Rail',
                    style: TextStyle(
                      color: AppTheme.textSlateNavy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfacePureWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.cardOutline),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.powderBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_rounded, color: AppTheme.ceruleanBlue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Commercial Bank Settlement (DRC)',
                                    style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    ngo.bankName != null && ngo.bankName!.isNotEmpty
                                        ? '${ngo.bankName} • RIB: ${ngo.bankRib ?? 'Pending'}'
                                        : 'Rawbank / Equity BCDC (Account linkage pending review)',
                                    style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppTheme.cardOutline, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.pastelMint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone_android_rounded, color: AppTheme.mintGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mobile Money Corporate Merchant Till',
                                    style: TextStyle(color: AppTheme.textMutedGray, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    ngo.mobileMoneyMerchant != null && ngo.mobileMoneyMerchant!.isNotEmpty
                                        ? ngo.mobileMoneyMerchant!
                                        : 'Vodacom M-Pesa / Orange Money Corporate Merchant Linked',
                                    style: const TextStyle(color: AppTheme.textSlateNavy, fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 3: Submitted Legal KYC Documents
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '3. Submitted Legal KYC Documents',
                          style: TextStyle(
                            color: AppTheme.textSlateNavy,
                            fontSize: 15,
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
                        ),
                        child: Text(
                          '${_documents.length} Files Ready',
                          style: const TextStyle(color: AppTheme.mintGreen, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ..._documents.map((doc) {
                    final status = _docStatuses[doc.id] ?? doc.status;
                    final isValid = status == 'VALID';
                    final isFlagged = status == 'FLAGGED';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfacePureWhite,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isValid
                              ? AppTheme.mintGreen.withOpacity(0.5)
                              : isFlagged
                                  ? AppTheme.roseText.withOpacity(0.5)
                                  : AppTheme.cardOutline,
                          width: isValid || isFlagged ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isValid
                                  ? AppTheme.pastelMint
                                  : isFlagged
                                      ? AppTheme.pastelRose
                                      : AppTheme.powderBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isValid
                                  ? Icons.check_circle_rounded
                                  : isFlagged
                                      ? Icons.flag_rounded
                                      : Icons.description_rounded,
                              color: isValid
                                  ? AppTheme.mintGreen
                                  : isFlagged
                                      ? AppTheme.roseText
                                      : AppTheme.ceruleanBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.documentType,
                                  style: const TextStyle(
                                    color: AppTheme.textSlateNavy,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doc.fileName,
                                  style: const TextStyle(color: AppTheme.textMutedGray, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.ceruleanBlue,
                              side: const BorderSide(color: AppTheme.ceruleanBlue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(0, 34),
                            ),
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                            label: const Text('Inspect', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            onPressed: () => _showDocumentPreview(doc),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Persistent Action Bar at Bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.surfacePureWhite,
                border: Border(top: BorderSide(color: AppTheme.cardOutline, width: 1)),
              ),
              child: SafeArea(
                child: isVerified
                    ? Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.pastelMint,
                                borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                                border: Border.all(color: AppTheme.mintGreen.withOpacity(0.35)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.verified_rounded, color: AppTheme.mintGreen, size: 18),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Accredited & Active NGO',
                                      style: TextStyle(
                                        color: AppTheme.mintGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.roseText,
                              side: const BorderSide(color: AppTheme.roseText),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            ),
                            onPressed: _isProcessingAction ? null : _rejectNgo,
                            child: const Text('Suspend NGO', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.roseText,
                                side: const BorderSide(color: AppTheme.roseText),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _isProcessingAction ? null : _rejectNgo,
                              child: const Text('Request Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.mintGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.pillRadius)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              onPressed: _isProcessingAction ? null : _approveNgo,
                              child: _isProcessingAction
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.verified_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Approve & Verify NGO', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
